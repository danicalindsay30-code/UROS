`timescale 1ns / 1ps
//=====================================================================
// tb_cma_update: same pattern                                  YOU WRITE
//---------------------------------------------------------------------
// unit_update.txt, one row per test, 4 + 4N + 8N + 8N integers (N = 5: 104):
//     gx_re gx_im gy_re gy_im
//     xr[N] xi[N] yr[N] yi[N]
//     4 filters BEFORE:  for f in XX, XY, YX, YY: wr[N] then wi[N]
//     4 filters AFTER:   same layout, expected wr_new / wi_new
//
// Compare all 8N new taps. On a mismatch print the filter, tap index
// and both values. If a whole filter is wrong, check which g (x or y)
// and which window (x or y) that filter uses: name = INPUT, OUTPUT.
//
// PASS when: 300 rows, 0 errors.
//=====================================================================

import eq_pkg::*;

module tb_cma_update;
    localparam int    N   = 5;
    localparam string VEC = "C:/dev/UROS/06_rebuild/eq/vectors/N5/unit_update.txt";

    // TODO: signals, DUT (cma_update #(.N(N))), file loop, compare, summary.
endmodule
