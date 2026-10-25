`timescale 1ns / 1ps
//=====================================================================
// eq_pkg
//---------------------------------------------------------------------
// Every width, fractional-bit count and shift from ../FORMATS.md, in
// one place. Each module starts with `import eq_pkg::*;` so a format
// change is a one-line edit here, never a hunt through six files.
//
// Names: *_W = total bits, *_F = fractional bits.
// A value is (integer) / 2^F, e.g. 4096 in E (F = 12) is 1.0.
//
// Vivado: add this file FIRST in the source list (or set it to compile
// first). Modules that import a package must compile after it.
//=====================================================================

package eq_pkg;

    // ---- formats --------------------------------------------------
    localparam int X_W = 8,  X_F = 5;    // input x        Q3.5
    localparam int W_W = 24, W_F = 22;   // taps w         Q2.22
    localparam int Y_W = 16, Y_F = 13;   // output y       Q3.13
    localparam int E_W = 16, E_F = 12;   // error e        Q4.12
    localparam int G_W = 18, G_F = 23;   // g = mu*e*y*    23 frac bits
    localparam int MU_SHIFT = 10;        // mu = 2^-10

    // ---- derived widths -------------------------------------------
    localparam int P_W    = X_W + W_W;   // 32: one real product x*w
    localparam int MAG2_W = 2 * Y_W + 1; // 33: re^2 + im^2
    localparam int EY_W   = E_W + Y_W;   // 32: e * y
    localparam int DW_W   = G_W + X_W + 1; // 27: g*x complex part (2 products summed)

    // ---- rounding shifts (each is "old frac bits - new frac bits") -
    localparam int Y_SHIFT  = X_F + W_F - Y_F;              // 27 - 13 = 14
    localparam int MAG2_F   = 2 * Y_F;                      // 26
    localparam int E_SHIFT  = MAG2_F - E_F;                 // 26 - 12 = 14
    localparam int G_SHIFT  = E_F + Y_F + MU_SHIFT - G_F;   // 35 - 23 = 12
    localparam int DW_SHIFT = G_F + X_F - W_F;              // 28 - 22 = 6

    // ---- constants --------------------------------------------------
    localparam longint R_INT   = 64'sd1 <<< MAG2_F;         // R = 1.0 in the |y|^2 format
    localparam longint W_ONE   = 64'sd1 <<< W_F;            // 1.0 as a tap: single-spike value

    // ---- filter index: input, output (your Python names) ----------
    // y_x = FIR(XX on x window) + FIR(YX on y window)
    // y_y = FIR(XY on x window) + FIR(YY on y window)
    localparam int XX = 0, XY = 1, YX = 2, YY = 3;

endpackage
