`timescale 1ns / 1ps
//=====================================================================
// butterfly: four complex FIRs, two complex adders, round   YOU WRITE
//---------------------------------------------------------------------
// Book 5.25 / 5.26, in your Python names (filter = input, output):
//     y_x = FIR(w_xx on x window) + FIR(w_yx on y window)
//     y_y = FIR(w_xy on x window) + FIR(w_yy on y window)
//
// Then round the exact sum (27 frac bits) to y (Q3.13, 16 bits):
//     y = saturate_16( (sum + 2^13) >>> 14 )
// Y_SHIFT = 14 is in eq_pkg. Saturate, never wrap: a wrapped y flips
// sign and pushes every tap the wrong way (see the study guide).
//
// Taps come in as 2-D arrays: wr[filter][tap], filter index XX, XY, YX, YY
// from eq_pkg.
//
// Python reference: cma_int.py, from "acc = {...}" to the y = ... line.
// Unit test: tb_butterfly.sv with vectors/N5/unit_butterfly.txt
//=====================================================================

import eq_pkg::*;

module butterfly #(
    parameter int N = 5
)(
    input  logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1],    // x window
    input  logic signed [X_W-1:0] yr [0:N-1], yi [0:N-1],    // y window
    input  logic signed [W_W-1:0] wr [0:3][0:N-1],           // taps [filter][tap]
    input  logic signed [W_W-1:0] wi [0:3][0:N-1],
    output logic signed [Y_W-1:0] yx_re, yx_im,              // output x, Q3.13
    output logic signed [Y_W-1:0] yy_re, yy_im               // output y, Q3.13
);

    localparam int SW = P_W + 1 + $clog2(N);   // one FIR sum
    localparam int AW = SW + 1;                // two FIR sums added

    // TODO 1. Four complex_fir instances. Name them u_xx, u_xy, u_yx, u_yy.
    //         u_xx and u_xy read the x window; u_yx and u_yy read the y window.
    //         TIP: passing one row of a 2-D array: .wr(wr[XX]) works.
    //         Outputs: declare  logic signed [SW-1:0] s_xx_r, s_xx_i, ... (8 signals)

    // TODO 2. Add the pairs into AW-bit sums (exact):
    //            ax_r = s_xx_r + s_yx_r;   ax_i = ...   (output x)
    //            ay_r = s_xy_r + s_yy_r;   ay_i = ...   (output y)

    // TODO 3. Round and saturate each of the four to Y_W bits.
    //         Write a function so you write it once:
    //
    //   function automatic logic signed [Y_W-1:0] round_sat_y (input logic signed [AW-1:0] v);
    //       logic signed [AW-1:0] r;
    //       r = (v + (AW'(1) <<< (Y_SHIFT-1))) >>> Y_SHIFT;    // round half up
    //       // TODO: if r > 32767 return 32767; if r < -32768 return -32768; else r[Y_W-1:0]
    //   endfunction
    //
    //   TIP: compare against the limits as signed numbers of the SAME width
    //   as r, e.g.  if (r > AW'(signed'(32767)))  or simply  if (r > 32767)
    //   (32767 is a signed 32-bit int and r is signed, so the compare is signed).
    //   Could v + 2^13 overflow AW bits? (worst case is far below 2^(AW-1): no)

endmodule
