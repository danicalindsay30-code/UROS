`timescale 1ns / 1ps
//=====================================================================
// tb_complex_fir: same pattern as tb_cma_error                 YOU WRITE
//---------------------------------------------------------------------
// unit_fir.txt, one row per test, 4N + 2 integers (N = 5: 22):
//     xr[0..N-1] xi[0..N-1] wr[0..N-1] wi[0..N-1]   sum_re sum_im
// 1200 rows = 300 symbols x 4 filters (each filter's real taps and window).
//
// Read the arrays in the order written, with an index loop:
//     for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); xr[i] = t; end
//     ... same for xi, wr, wi, then the two expected sums.
//
// Compare sr and si with the expected sums (exact, no rounding at all, so
// any difference is a real bug: usually a missing conj or a swapped
// re/im in cmult).
//
// PASS when: 1200 rows, 0 errors.
//=====================================================================

import eq_pkg::*;

module tb_complex_fir;
    localparam int    N   = 5;
    localparam string VEC = "C:/dev/UROS/06_rebuild/eq/vectors/N5/unit_fir.txt";

    // TODO: signals, DUT (complex_fir #(.N(N))), file loop, compare, summary.
endmodule
