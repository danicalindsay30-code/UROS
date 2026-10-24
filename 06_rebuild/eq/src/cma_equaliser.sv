`timescale 1ns / 1ps
//=====================================================================
// cma_equaliser: the 2x2 CMA butterfly equaliser, top level
//---------------------------------------------------------------------
// Holds all the STATE (delay lines, taps, stage registers) and a 4-state
// machine. The maths blocks (butterfly, cma_error, cma_update) are
// combinational and always computing; the state machine decides WHEN
// each result is captured.
//
//   S_IDLE  in_ready = 1. On in_valid, shift the new sample into both
//           delay lines. Once N samples are in, go to S_FIR; before
//           that (fill phase) stay here: no output, no update.
//   S_FIR   y regs  <= butterfly(windows, taps)
//   S_ERR   e, g    <= cma_error(y regs)
//   S_UPD   taps    <= cma_update(g, windows, taps); out_valid = 1
//
// So one symbol = K = 4 clocks. The next sample can't enter before the
// taps are written, because the next FIR needs them: that is the
// feedback loop, and it is why throughput is f_clk / 4.
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

    typedef enum logic [1:0] {S_IDLE, S_FIR, S_ERR, S_UPD} state_t;
    state_t state;

    // ---- state ------------------------------------------------------
    logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1];      // delay lines, [0] = newest
    logic signed [X_W-1:0] yr [0:N-1], yi [0:N-1];
    logic signed [W_W-1:0] wr [0:3][0:N-1];             // taps [filter][tap]
    logic signed [W_W-1:0] wi [0:3][0:N-1];
    logic signed [Y_W-1:0] y_xr, y_xi, y_yr, y_yi;      // captured in S_FIR
    logic signed [E_W-1:0] e_x_q, e_y_q;                // captured in S_ERR
    logic signed [G_W-1:0] gxr_q, gxi_q, gyr_q, gyi_q;
    logic [$clog2(N+1)-1:0] fill;                       // samples in the window, stops at N-1

    // ---- combinational maths ----------------------------------------
    logic signed [Y_W-1:0] bf_xr, bf_xi, bf_yr, bf_yi;
    logic signed [E_W-1:0] er_x, er_y;
    logic signed [G_W-1:0] er_gxr, er_gxi, er_gyr, er_gyi;
    logic signed [W_W-1:0] wr_new [0:3][0:N-1];
    logic signed [W_W-1:0] wi_new [0:3][0:N-1];

    butterfly #(.N(N)) u_bf (
        .xr(xr), .xi(xi), .yr(yr), .yi(yi), .wr(wr), .wi(wi),
        .yx_re(bf_xr), .yx_im(bf_xi), .yy_re(bf_yr), .yy_im(bf_yi)
    );

    cma_error u_err (
        .yx_re(y_xr), .yx_im(y_xi), .yy_re(y_yr), .yy_im(y_yi),
        .e_x(er_x), .e_y(er_y),
        .gx_re(er_gxr), .gx_im(er_gxi), .gy_re(er_gyr), .gy_im(er_gyi)
    );

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
            {y_xr, y_xi, y_yr, y_yi} <= '0;
            {e_x_q, e_y_q}           <= '0;
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
                    if (fill == N-1) state <= S_FIR;     // window full
                    else             fill  <= fill + 1'b1;
                end
                S_FIR: begin
                    {y_xr, y_xi, y_yr, y_yi} <= {bf_xr, bf_xi, bf_yr, bf_yi};
                    state <= S_ERR;
                end
                S_ERR: begin
                    e_x_q <= er_x;  e_y_q <= er_y;
                    gxr_q <= er_gxr; gxi_q <= er_gxi; gyr_q <= er_gyr; gyi_q <= er_gyi;
                    state <= S_UPD;
                end
                S_UPD: begin
                    wr    <= wr_new;
                    wi    <= wi_new;
                    state <= S_IDLE;
                end
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
