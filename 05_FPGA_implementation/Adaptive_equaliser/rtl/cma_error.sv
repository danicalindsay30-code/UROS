`timescale 1ns / 1ps
//=====================================================================
// cma_error: y -> e and g for both outputs
//---------------------------------------------------------------------
// Per output (your Python: error = R - abs(out)**2 ; mu*error*conj(out)):
//     mag2 = re^2 + im^2                         exact, frac 26
//     e    = sat16( (R - mag2 + 2^13) >>> 14 )   Q4.12
//     ey   = e * conj(y)                         frac 25
//     g    = sat18( (ey + 2^11) >>> 12 )         frac 23
//
// mu = 2^-10 costs nothing: it is inside the 12-bit shift
// (frac 25 + 10 for mu = 35, keep 23, so drop 12).
// R = 1.0 is R_INT = 2^26, the same format as mag2.
//
// Split into two small blocks, cma_e1 (y -> e) and cma_g1 (e, y -> g),
// because doing both multiplies in one clock took 10.6 ns and failed
// 100 MHz. cma_equaliser registers e between them (states S_ERR, S_G).
// This wrapper chains them directly, for the unit test.
//=====================================================================

import eq_pkg::*;

module cma_error (
    input  logic signed [Y_W-1:0] yx_re, yx_im, yy_re, yy_im,
    output logic signed [E_W-1:0] e_x, e_y,
    output logic signed [G_W-1:0] gx_re, gx_im, gy_re, gy_im
);
    cma_e1 u_ex (.re(yx_re), .im(yx_im), .e(e_x));
    cma_e1 u_ey (.re(yy_re), .im(yy_im), .e(e_y));
    cma_g1 u_gx (.re(yx_re), .im(yx_im), .e(e_x), .g_re(gx_re), .g_im(gx_im));
    cma_g1 u_gy (.re(yy_re), .im(yy_im), .e(e_y), .g_re(gy_re), .g_im(gy_im));
endmodule


// e = R - |y|^2, rounded to Q4.12 and saturated
module cma_e1 (
    input  logic signed [Y_W-1:0] re, im,
    output logic signed [E_W-1:0] e
);
    localparam longint E_MAX = (64'sd1 <<< (E_W - 1)) - 1;
    localparam longint E_MIN = -(64'sd1 <<< (E_W - 1));

    logic signed [MAG2_W-1:0] mag2;          // 33 bits
    logic signed [MAG2_W:0]   d, d_r;        // 34 bits

    always_comb begin
        mag2 = re * re + im * im;
        d    = R_INT - mag2;
        d_r  = (d + (1 <<< (E_SHIFT - 1))) >>> E_SHIFT;
        if      (d_r > E_MAX) e = E_W'(E_MAX);
        else if (d_r < E_MIN) e = E_W'(E_MIN);
        else                  e = d_r[E_W-1:0];
    end
endmodule


// g = mu * e * conj(y), rounded to 23 fractional bits and saturated
module cma_g1 (
    input  logic signed [Y_W-1:0] re, im,
    input  logic signed [E_W-1:0] e,
    output logic signed [G_W-1:0] g_re, g_im
);
    localparam longint G_MAX = (64'sd1 <<< (G_W - 1)) - 1;
    localparam longint G_MIN = -(64'sd1 <<< (G_W - 1));

    logic signed [EY_W-1:0] ey_re, ey_im;    // 32 bits
    logic signed [EY_W-1:0] gr_r, gi_r;

    always_comb begin
        ey_re = e * re;
        ey_im = -(e * im);                    // conj(y): minus on the imaginary part
        gr_r  = (ey_re + (1 <<< (G_SHIFT - 1))) >>> G_SHIFT;
        gi_r  = (ey_im + (1 <<< (G_SHIFT - 1))) >>> G_SHIFT;
        if      (gr_r > G_MAX) g_re = G_W'(G_MAX);
        else if (gr_r < G_MIN) g_re = G_W'(G_MIN);
        else                   g_re = gr_r[G_W-1:0];
        if      (gi_r > G_MAX) g_im = G_W'(G_MAX);
        else if (gi_r < G_MIN) g_im = G_W'(G_MIN);
        else                   g_im = gi_r[G_W-1:0];
    end
endmodule
