`timescale 1ns / 1ps
//=====================================================================
// tb_cma_error: file-driven, self-checking                     YOU WRITE
//---------------------------------------------------------------------
// This is the PATTERN for every file-driven unit test in Step 3
// (tb_complex_fir, tb_butterfly, tb_cma_update are the same shape with
// more numbers per row). Get this one working first.
//
// unit_error.txt, one row per test, 10 integers:
//     yx_re yx_im yy_re yy_im   e_x e_y gx_re gx_im gy_re gy_im
//     \____ inputs ________/   \__________ expected ___________/
//
// The DUT is combinational, so there is no clock: drive the inputs,
// wait #1, compare.
//=====================================================================

import eq_pkg::*;

module tb_cma_error;

    localparam string VEC = "C:/dev/UROS/06_rebuild/eq/vectors/N5/unit_error.txt";

    // TODO 1. DUT signals: four Y_W inputs, two E_W and four G_W outputs.
    //         Instantiate cma_error u_dut (...).

    initial begin
        int fd, code, rows, errors;
        longint v [0:9];                 // one row: 4 inputs + 6 expected

        fd = $fopen(VEC, "r");
        if (fd == 0) begin $display("cannot open %s", VEC); $finish; end
        rows = 0; errors = 0;

        while (!$feof(fd)) begin
            // TODO 2. Read 10 integers. One $fscanf per number is the
            //         simplest and works for any row length:
            //             code = 0;
            //             for (int j = 0; j < 10; j++) code += $fscanf(fd, "%d", v[j]);
            //             if (code != 10) break;          // end of file
            //
            // TODO 3. Drive inputs from v[0..3], then  #1;
            //
            // TODO 4. Compare all six outputs with v[4..9]. On a mismatch:
            //             errors++;
            //             if (errors <= 10) $display("row %0d: e_x got %0d exp %0d ...", rows, ...);
            //         TIP: print only the first few. Mismatch number 1 is
            //         the one that tells you the bug.
            //
            // rows++;
        end
        $fclose(fd);

        // TODO 5. $display("tb_cma_error: %0d rows, %0d errors -> %s", ...); $finish;
    end

endmodule
