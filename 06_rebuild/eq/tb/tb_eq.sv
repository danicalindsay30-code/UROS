`timescale 1ns / 1ps
//=====================================================================
// tb_eq: the full equaliser against cma_int.py                 YOU WRITE
//---------------------------------------------------------------------
// This is your matched filter testbench pattern (driver + separate
// monitor), plus a ready/valid handshake because the DUT only accepts
// a symbol every K = 4 clocks.
//
// Files (vectors/N5/):
//   eq_in.txt       xr xi yr yi              10,008 rows, one per input symbol
//   eq_out_ref.txt  k yx_re yx_im yy_re yy_im 10,004 rows, one per output
//   eq_dbg_ref.txt  k e_x e_y gx_re gx_im gy_re gy_im   (for debugging)
//
// PASS when: 10,004 outputs, 0 mismatches.
//=====================================================================

import eq_pkg::*;

module tb_eq;
    localparam int    N   = 5;
    localparam string DIR = "C:/dev/UROS/06_rebuild/eq/vectors/N5/";

    // TODO 1. Clock (10 ns), rst, DUT signals, DUT cma_equaliser #(.N(N)).

    // TODO 2. Load eq_in.txt into an array (like your MF load_stimulus task),
    //         counting rows. Open eq_out_ref.txt and eq_dbg_ref.txt for reading.

    // TODO 3. DRIVER (initial block). Drive on the FALLING edge so the DUT,
    //         which samples on the rising edge, never races the testbench:
    //
    //   rst = 1; repeat (5) @(posedge clk); rst = 0;
    //   for (int i = 0; i < n_in; i++) begin
    //       @(negedge clk);
    //       while (!in_ready) @(negedge clk);   // wait until the DUT can accept
    //       x_re_in = in[i][0]; ... ; in_valid = 1;
    //   end
    //   @(negedge clk); in_valid = 0;
    //   repeat (20) @(posedge clk);             // let the last symbol finish
    //   {print summary}; $finish;
    //
    //   Why this works: the DUT only takes a sample in S_IDLE, at the rising
    //   edge. Between symbols in_valid stays high with the OLD sample, but
    //   the DUT isn't looking (in_ready = 0), and by the next S_IDLE the
    //   driver has already put the NEXT sample on the pins.

    // TODO 4. MONITOR (separate always block), exactly like your MF one:
    //
    //   always @(posedge clk) if (!rst && out_valid) begin
    //       read the next row of eq_out_ref.txt (5 ints: k + 4 outputs)
    //       read the next row of eq_dbg_ref.txt (7 ints)
    //       compare yx_re .. yy_im; on a mismatch, errors++ and for the
    //       FIRST few print k, got, expected, AND dbg_e/dbg_g vs the dbg row.
    //       outputs++;
    //   end
    //
    //   DEBUG STRATEGY if it fails: look only at the FIRST mismatching k.
    //     y wrong but e, g right at k-1  -> FIR / taps issue (butterfly or update at k-1)
    //     y right but e or g wrong       -> cma_error
    //     first mismatch at k = 4         -> reset values or fill phase
    //   Feedback makes one wrong bit spread to everything after it, so the
    //   later mismatches tell you nothing.

    // TODO 5. Summary: outputs == 10004 and errors == 0 -> PASS.

    // TODO 6. Timeout safety net:  initial begin #5_000_000; $display("timeout"); $finish; end
    //         (10,008 symbols x 4 clocks x 10 ns = 0.4 ms = 400,000 ns, so 5 ms is generous)

endmodule
