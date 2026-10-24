`timescale 1ns / 1ps
//=====================================================================
// cma_error: y -> e and g, both outputs, combinational        YOU WRITE
//---------------------------------------------------------------------
// For each output o in {x, y}:
//     mag2 = re^2 + im^2                       exact, 33 bits, frac 26
//     e    = sat16( (R - mag2 + 2^13) >>> 14 ) Q4.12        (E_SHIFT = 14)
//     ey   = e * conj(y) :  ey_re =  e * re                 frac 25
//                           ey_im = -e * im
//     g    = sat18( (ey + 2^11) >>> 12 )       23 frac bits (G_SHIFT = 12)
//
// mu = 2^-10 costs nothing: it is inside G_SHIFT (12 = 10 for mu + 2).
// R = 1.0 is R_INT = 2^26 in eq_pkg, the SAME format as mag2.
//
// Python reference: cma_int.py, the "error and g, per output" block.
// Your float Python: error_x = R - abs(output_x)**2 ; mu * error * conj(out)
// Unit test: tb_cma_error.sv with vectors/N5/unit_error.txt
//   row:  yx_re yx_im yy_re yy_im | e_x e_y gx_re gx_im gy_re gy_im
//=====================================================================

import eq_pkg::*;

module cma_error (
    input  logic signed [Y_W-1:0] yx_re, yx_im, yy_re, yy_im,
    output logic signed [E_W-1:0] e_x, e_y,
    output logic signed [G_W-1:0] gx_re, gx_im, gy_re, gy_im
);

    // TODO 1. Write ONE small function or submodule for a single output,
    //         then use it twice (x and y). Inside, in order:
    //
    //   a) logic signed [MAG2_W-1:0] mag2 = re*re + im*im;
    //      TIP: re*re is 32 bits; the sum of two needs 33 = MAG2_W.
    //   b) logic signed [MAG2_W:0] d = R_INT - mag2;          // 34 bits
    //   c) round by E_SHIFT, saturate to E_W                   -> e
    //   d) logic signed [EY_W-1:0] ey_re = e * re;  ey_im = -(e * im);
    //      TIP: -(e*im) can't overflow 32 bits here: |e| <= 2^15, |im| <= 2^15,
    //      the product magnitude is at most 2^30.
    //   e) round by G_SHIFT, saturate to G_W                   -> g re, g im
    //
    // TODO 2. Saturation limits are different per format:
    //         E_W = 16: [-32768, 32767]     G_W = 18: [-131072, 131071]
    //         TIP: a reusable pattern:
    //           localparam longint G_MAX = (64'sd1 <<< (G_W-1)) - 1;
    //           if (r > G_MAX) ... else if (r < -G_MAX-1) ...
    //
    // CHECK: row 1 of unit_error.txt is y = 0 -> e = 4096 (1.0), g = 0.
    //        Can you predict that before simulating?

endmodule
