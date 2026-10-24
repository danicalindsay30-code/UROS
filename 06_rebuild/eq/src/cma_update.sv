`timescale 1ns / 1ps
//=====================================================================
// cma_update: new taps for all four filters, combinational     YOU WRITE
//---------------------------------------------------------------------
// Your Python (adaptive_algorithim.cma):
//     w_xx += mu * x_window * error_x * conj(output_x)     = g_x * x_window
//     w_yx += mu * y_window * error_x * conj(output_x)     = g_x * y_window
//     w_xy += mu * x_window * error_y * conj(output_y)     = g_y * x_window
//     w_yy += mu * y_window * error_y * conj(output_y)     = g_y * y_window
//
// So per filter f, per tap i:     (filter name = INPUT, OUTPUT)
//     g   = g of f's OUTPUT     (XX, YX use g_x;  XY, YY use g_y)
//     v   = window of f's INPUT (XX, XY use x;    YX, YY use y)
//     dw  = round( g * v[i], DW_SHIFT = 6 )      plain product, NO conj
//     new = sat24( w[f][i] + dw )
//
// Count: 4 filters x N taps x 4 real multiplies = 80 DSPs for N = 5.
//
// Python reference: cma_int.py, the "update: w += round(g_out * x_in)" loop.
// Unit test: tb_cma_update.sv with vectors/N5/unit_update.txt
//   row: gx_re gx_im gy_re gy_im | xr xi yr yi windows | 4 filters BEFORE | 4 AFTER
//=====================================================================

import eq_pkg::*;

module cma_update #(
    parameter int N = 5
)(
    input  logic signed [G_W-1:0] gx_re, gx_im, gy_re, gy_im,
    input  logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1],
    input  logic signed [X_W-1:0] yr [0:N-1], yi [0:N-1],
    input  logic signed [W_W-1:0] wr     [0:3][0:N-1],
    input  logic signed [W_W-1:0] wi     [0:3][0:N-1],
    output logic signed [W_W-1:0] wr_new [0:3][0:N-1],
    output logic signed [W_W-1:0] wi_new [0:3][0:N-1]
);

    // TODO 1. A nested generate: for f in 0..3, for i in 0..N-1, one
    //         cmult #(.AW(G_W), .BW(X_W), .CONJ_A(0)).
    //         Pick the g and window with the parameter f (constant per copy):
    //             (f == XX || f == YX) ? gx : gy          <- output
    //             (f == XX || f == XY) ? x  : y           <- input
    //         TIP: inside a generate loop these are elaboration-time
    //         constants, so the ?: becomes plain wiring, not a mux.
    //         Products: logic signed [DW_W-1:0] dr [0:3][0:N-1], di [...]

    // TODO 2. Round each product by DW_SHIFT (6), add to the old tap,
    //         saturate to W_W (24 bits: [-2^23, 2^23-1]).
    //         TIP: do the add in a wider signal first (W_W + 1 bits),
    //         then saturate; otherwise the overflow happens before
    //         you can detect it.

    // CHECK: rows 1 and 2 of unit_update.txt have g = 0 -> taps unchanged.
    //        Row 2 has g != 0: which taps change first? (only where the
    //        window is non-zero)

endmodule
