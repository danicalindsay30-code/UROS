`timescale 1ns / 1ps
//=====================================================================
// tb_butterfly: same pattern                                   YOU WRITE
//---------------------------------------------------------------------
// unit_butterfly.txt, one row per test, 4N + 8N + 4 integers (N = 5: 64):
//     xr[N] xi[N] yr[N] yi[N]                   both windows
//     wr[XX][N] wi[XX][N]  wr[XY][N] wi[XY][N]  wr[YX][N] wi[YX][N]  wr[YY][N] wi[YY][N]
//     yx_re yx_im yy_re yy_im                   expected, Q3.13
//
// Reading the taps: for f in 0..3 { read N into wr[f], then N into wi[f] }.
//
// If only yy (or only yx) is wrong, check which windows you wired to
// u_xy / u_yx: those two are the crossed arms of the butterfly and the
// easiest to swap.
//
// PASS when: 300 rows, 0 errors.
//=====================================================================

import eq_pkg::*;

module tb_butterfly;
    localparam int    N   = 5;
    localparam string VEC = "C:/dev/UROS/06_rebuild/eq/vectors/N5/unit_butterfly.txt";

    // TODO: signals (2-D tap arrays [0:3][0:N-1]), DUT, file loop, compare, summary.
endmodule
