`timescale 1ns / 1ps
//=====================================================================
// complex_fir: one butterfly filter, combinational
//---------------------------------------------------------------------
// s = sum over i of conj(w[i]) * x[i]        book 5.9 (w^H x), Python np.vdot(w, window)
//
// x[0] is the NEWEST sample (Python's window[0] is the oldest), so tap i
// here = Python tap N-1-i. The test vectors are already in this order.
//
// No delay line in here: the window is also needed by the tap update,
// so the delay lines live in cma_equaliser and both blocks read them.
// No rounding: the sum stays exact (27 fractional bits). It is rounded
// once, after the two filters of an output are added (butterfly).
//
// Width: each product part is 33 bits; summing N adds $clog2(N) bits.
//
// PIPELINE REGISTER after the multipliers (same as the matched filter's
// product_reg). Without it, multiply + 20-term add + round took 10.5 ns
// and failed 100 MHz. With it, the sum is ready one clock after the
// inputs: the state machine waits one extra clock (S_MUL).
// Vivado puts this register inside the DSP48E2 (its M/P register).
//=====================================================================

import eq_pkg::*;

module complex_fir #(
    parameter int N  = 5,
    parameter int SW = P_W + 1 + $clog2(N)
)(
    input  logic                  clk,
    input  logic signed [X_W-1:0] xr [0:N-1],
    input  logic signed [X_W-1:0] xi [0:N-1],
    input  logic signed [W_W-1:0] wr [0:N-1],
    input  logic signed [W_W-1:0] wi [0:N-1],
    output logic signed [SW-1:0]  sr,          // valid one clock after the inputs
    output logic signed [SW-1:0]  si
);

    logic signed [P_W:0] pr_c [0:N-1], pi_c [0:N-1];    // straight from the multipliers
    logic signed [P_W:0] pr   [0:N-1], pi   [0:N-1];    // registered

    // one complex multiplier per tap; the TAP is conjugated (np.vdot conjugates w)
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : g_tap
            cmult #(.AW(W_W), .BW(X_W), .CONJ_A(1)) u_mul (
                .a_re(wr[i]), .a_im(wi[i]),
                .b_re(xr[i]), .b_im(xi[i]),
                .p_re(pr_c[i]), .p_im(pi_c[i])
            );
        end
    endgenerate

    always_ff @(posedge clk) begin
        pr <= pr_c;
        pi <= pi_c;
    end

    // add up all taps (same pattern as the fir_param accumulator)
    always_comb begin
        sr = '0;
        si = '0;
        for (int k = 0; k < N; k++) begin
            sr = sr + pr[k];
            si = si + pi[k];
        end
    end

endmodule
