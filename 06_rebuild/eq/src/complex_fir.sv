`timescale 1ns / 1ps
//=====================================================================
// complex_fir: one of the four butterfly filters, combinational  YOU WRITE
//---------------------------------------------------------------------
// s = sum over i of conj(w[i]) * x[i]          (book 5.9: w^H x)
//
// This is your Python  np.vdot(w, window)  with one difference:
//   Python window[0] is the OLDEST sample;  here x[0] is the NEWEST.
//   So tap i here = Python tap N-1-i. The vectors are already in this
//   order, so you don't convert anything; just know why.
//
// Why no shift register in here?  The window is also needed by the
// tap update (dw = g * x[i]), so the delay lines live ONE level up in
// cma_equaliser and both blocks read them. This module is pure maths.
//
// Why no rounding?  The sum is exact (27 fractional bits). Rounding to
// y happens once, after the two filters of each output are added
// (butterfly.sv). Rounding twice would not match cma_int.py.
//
// Widths: each cmult part is 33 bits. Summing N of them adds
// ceil(log2(N)) bits: SW = 33 + $clog2(N)  (N = 5: 36 bits).
//
// Python reference: cma_int.py, the fir() function inside run().
// Unit test: tb_complex_fir.sv with vectors/N5/unit_fir.txt
//=====================================================================

import eq_pkg::*;

module complex_fir #(
    parameter int N  = 5,
    parameter int SW = P_W + 1 + $clog2(N)          // sum width
)(
    input  logic signed [X_W-1:0] xr [0:N-1],       // window, [0] = newest
    input  logic signed [X_W-1:0] xi [0:N-1],
    input  logic signed [W_W-1:0] wr [0:N-1],       // taps, same order
    input  logic signed [W_W-1:0] wi [0:N-1],
    output logic signed [SW-1:0]  sr,               // exact sum, frac 27
    output logic signed [SW-1:0]  si
);

    // TODO 1. Declare product arrays from the cmults:
    //            logic signed [P_W:0] pr [0:N-1], pi [0:N-1];   // 33 bits

    // TODO 2. One cmult per tap with a generate loop:
    //            genvar i;
    //            generate for (i = 0; i < N; i++) begin : g_tap
    //                cmult #(.AW(W_W), .BW(X_W), .CONJ_A(1)) u_mul (
    //                    .a_re(wr[i]), .a_im(wi[i]), .b_re(xr[i]), .b_im(xi[i]),
    //                    .p_re(pr[i]), .p_im(pi[i]) );
    //            end endgenerate
    //         Q: which input is "a" (gets conjugated)? The tap or the sample?
    //         Check against np.vdot: it conjugates its FIRST argument, w.

    // TODO 3. Sum them in an always_comb:
    //            sr = '0;  si = '0;
    //            for (int k = 0; k < N; k++) begin sr += pr[k]; si += pi[k]; end
    //         TIP: this is the same pattern as your fir_param accum loop.
    //         Sign extension is automatic: pr is signed, sr is signed and wider.

endmodule
