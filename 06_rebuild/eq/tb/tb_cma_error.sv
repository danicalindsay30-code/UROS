`timescale 1ns / 1ps
//=====================================================================
// tb_cma_error: file-driven, self-checking
//---------------------------------------------------------------------
// unit_error.txt, one row per test, 10 integers:
//     yx_re yx_im yy_re yy_im | e_x e_y gx_re gx_im gy_re gy_im
// The DUT is combinational: drive, wait #1, compare. No clock needed.
// The other unit tests are this same pattern with more numbers per row.
//=====================================================================

import eq_pkg::*;

module tb_cma_error;

    localparam string VEC = "C:/dev/UROS/06_rebuild/eq/vectors/N5/unit_error.txt";

    logic signed [Y_W-1:0] yx_re, yx_im, yy_re, yy_im;
    logic signed [E_W-1:0] e_x, e_y;
    logic signed [G_W-1:0] gx_re, gx_im, gy_re, gy_im;

    cma_error u_dut (.*);       // .* connects ports to signals of the same name

    initial begin
        int fd, code, rows, errors;
        longint v [0:9];

        fd = $fopen(VEC, "r");
        if (fd == 0) begin $display("cannot open %s", VEC); $finish; end
        rows = 0; errors = 0;

        while (!$feof(fd)) begin
            code = 0;
            for (int j = 0; j < 10; j++) code += $fscanf(fd, "%d", v[j]);
            if (code != 10) break;

            {yx_re, yx_im, yy_re, yy_im} = {Y_W'(v[0]), Y_W'(v[1]), Y_W'(v[2]), Y_W'(v[3])};
            #1;
            if (e_x !== v[4] || e_y !== v[5] || gx_re !== v[6] || gx_im !== v[7] ||
                gy_re !== v[8] || gy_im !== v[9]) begin
                errors++;
                if (errors <= 5)
                    $display("row %0d: got e=(%0d,%0d) g=(%0d,%0d,%0d,%0d)  exp e=(%0d,%0d) g=(%0d,%0d,%0d,%0d)",
                             rows, e_x, e_y, gx_re, gx_im, gy_re, gy_im,
                             v[4], v[5], v[6], v[7], v[8], v[9]);
            end
            rows++;
        end
        $fclose(fd);
        $display("tb_cma_error: %0d rows, %0d errors -> %s", rows, errors,
                 (errors == 0 && rows > 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
