`timescale 1ns / 1ps
//=====================================================================
// cma_equaliser: the 2x2 CMA butterfly equaliser, top level
//---------------------------------------------------------------------
// Holds all the STATE (delay lines, taps, stage registers) and a small
// state machine. The maths blocks are combinational and always
// computing; the state machine decides WHEN each result is captured.
//
//   S_IDLE  in_ready = 1. On in_valid, shift the new sample into both
//           delay lines. Once N samples are in, go to S_MUL; before
//           that (fill phase) stay here: no output, no update.
//   S_MUL   the product registers inside complex_fir fill
//   S_FIR   y regs  <= butterfly: add, round, saturate
//   S_ERR   e regs  <= R - |y|^2                       (cma_e1)
//   S_G     g regs  <= mu * e * conj(y)                (cma_g1)
//   S_UPD   taps    <= cma_update(g, windows, taps); out_valid = 1
//
// One symbol = K = 6 clocks. The next sample can't enter before the
// taps are written, because the next FIR needs them. That is the
// feedback loop, and it is why throughput is f_clk / 6.
//
// Why 6 and not 4: with fewer stages the FIR path (multiply + add +
// round) took 10.5 ns and the error path (two multiplies in a row)
// 10.6 ns, failing 100 MHz. Each split adds a register, like the
// matched filter's pipeline stages. In the matched filter that was free;
// here each register sits INSIDE the loop, so each one costs a clock
// per symbol. Faster clock, same arithmetic, fewer symbols per clock.
//
// Reset: taps = single spike (1.0 at the centre of w_xx and w_yy).
//=====================================================================

import eq_pkg::*;

module cma_equaliser #(
    parameter int N = 5
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic signed [X_W-1:0] x_re_in, x_im_in,
    input  logic signed [X_W-1:0] y_re_in, y_im_in,

    output logic                  out_valid,
    output logic signed [Y_W-1:0] yx_re, yx_im,
    output logic signed [Y_W-1:0] yy_re, yy_im,

    output logic signed [E_W-1:0] dbg_e_x, dbg_e_y,
    output logic signed [G_W-1:0] dbg_gx_re, dbg_gx_im, dbg_gy_re, dbg_gy_im
);

    typedef enum logic [2:0] {S_IDLE, S_MUL, S_FIR, S_ERR, S_G, S_UPD} state_t;
    state_t state;

    // ---- state ------------------------------------------------------
    logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1];      // delay lines, [0] = newest
    logic signed [X_W-1:0] yr [0:N-1], yi [0:N-1];
    logic signed [W_W-1:0] wr [0:3][0:N-1];             // taps [filter][tap]
    logic signed [W_W-1:0] wi [0:3][0:N-1];
    logic signed [Y_W-1:0] y_xr, y_xi, y_yr, y_yi;      // captured in S_FIR
    logic signed [E_W-1:0] e_x_q, e_y_q;                // captured in S_ERR
    logic signed [G_W-1:0] gxr_q, gxi_q, gyr_q, gyi_q;  // captured in S_G
    logic [$clog2(N+1)-1:0] fill;                       // samples in the window, stops at N-1

    // ---- combinational maths ----------------------------------------
    logic signed [Y_W-1:0] bf_xr, bf_xi, bf_yr, bf_yi;
    logic signed [E_W-1:0] e_x_c, e_y_c;
    logic signed [G_W-1:0] gxr_c, gxi_c, gyr_c, gyi_c;
    logic signed [W_W-1:0] wr_new [0:3][0:N-1];
    logic signed [W_W-1:0] wi_new [0:3][0:N-1];

    butterfly #(.N(N)) u_bf (
        .clk(clk), .xr(xr), .xi(xi), .yr(yr), .yi(yi), .wr(wr), .wi(wi),
        .yx_re(bf_xr), .yx_im(bf_xi), .yy_re(bf_yr), .yy_im(bf_yi)
    );

    cma_e1 u_ex (.re(y_xr), .im(y_xi), .e(e_x_c));
    cma_e1 u_ey (.re(y_yr), .im(y_yi), .e(e_y_c));
    cma_g1 u_gx (.re(y_xr), .im(y_xi), .e(e_x_q), .g_re(gxr_c), .g_im(gxi_c));
    cma_g1 u_gy (.re(y_yr), .im(y_yi), .e(e_y_q), .g_re(gyr_c), .g_im(gyi_c));

    cma_update #(.N(N)) u_upd (
        .gx_re(gxr_q), .gx_im(gxi_q), .gy_re(gyr_q), .gy_im(gyi_q),
        .xr(xr), .xi(xi), .yr(yr), .yi(yi), .wr(wr), .wi(wi),
        .wr_new(wr_new), .wi_new(wi_new)
    );

    // ---- registers and state machine --------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            fill  <= '0;
            for (int i = 0; i < N; i++) begin
                xr[i] <= '0; xi[i] <= '0; yr[i] <= '0; yi[i] <= '0;
            end
            for (int f = 0; f < 4; f++)
                for (int i = 0; i < N; i++) begin
                    wr[f][i] <= '0;
                    wi[f][i] <= '0;
                end
            wr[XX][N/2] <= W_W'(W_ONE);          // single spike, book 5.36
            wr[YY][N/2] <= W_W'(W_ONE);
            {y_xr, y_xi, y_yr, y_yi}     <= '0;
            {e_x_q, e_y_q}               <= '0;
            {gxr_q, gxi_q, gyr_q, gyi_q} <= '0;
        end
        else begin
            case (state)
                S_IDLE: if (in_valid) begin
                    for (int i = N-1; i > 0; i--) begin
                        xr[i] <= xr[i-1]; xi[i] <= xi[i-1];
                        yr[i] <= yr[i-1]; yi[i] <= yi[i-1];
                    end
                    xr[0] <= x_re_in; xi[0] <= x_im_in;
                    yr[0] <= y_re_in; yi[0] <= y_im_in;
                    if (fill == N-1) state <= S_MUL;     // window full
                    else             fill  <= fill + 1'b1;
                end
                S_MUL: state <= S_FIR;                   // products registering
                S_FIR: begin
                    {y_xr, y_xi, y_yr, y_yi} <= {bf_xr, bf_xi, bf_yr, bf_yi};
                    state <= S_ERR;
                end
                S_ERR: begin
                    e_x_q <= e_x_c;
                    e_y_q <= e_y_c;
                    state <= S_G;
                end
                S_G: begin
                    gxr_q <= gxr_c; gxi_q <= gxi_c; gyr_q <= gyr_c; gyi_q <= gyi_c;
                    state <= S_UPD;
                end
                S_UPD: begin
                    wr    <= wr_new;
                    wi    <= wi_new;
                    state <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    // ---- outputs ------------------------------------------------------
    assign in_ready  = (state == S_IDLE);
    assign out_valid = (state == S_UPD);
    assign {yx_re, yx_im, yy_re, yy_im} = {y_xr, y_xi, y_yr, y_yi};
    assign {dbg_e_x, dbg_e_y} = {e_x_q, e_y_q};
    assign {dbg_gx_re, dbg_gx_im, dbg_gy_re, dbg_gy_im} = {gxr_q, gxi_q, gyr_q, gyi_q};

endmodule
