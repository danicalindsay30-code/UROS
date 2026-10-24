`timescale 1ns / 1ps
//=====================================================================
// tb_butterfly: file-driven, same pattern
//---------------------------------------------------------------------
// unit_butterfly.txt row:
//     xr[N] xi[N] yr[N] yi[N]   then for f = XX, XY, YX, YY: wr[N] wi[N]
//     yx_re yx_im yy_re yy_im   (expected, Q3.13)
//=====================================================================

import eq_pkg::*;

module tb_butterfly;

    localparam int    N   = 5;
    localparam string VEC = "C:/dev/UROS/06_rebuild/eq/vectors/N5/unit_butterfly.txt";

    logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1], yr [0:N-1], yi [0:N-1];
    logic signed [W_W-1:0] wr [0:3][0:N-1], wi [0:3][0:N-1];
    logic signed [Y_W-1:0] yx_re, yx_im, yy_re, yy_im;

    butterfly #(.N(N)) u_dut (.*);

    initial begin
        int fd, code, rows, errors;
        longint t, ex [0:3];

        fd = $fopen(VEC, "r");
        if (fd == 0) begin $display("cannot open %s", VEC); $finish; end
        rows = 0; errors = 0;

        while (!$feof(fd)) begin
            code = 0;
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); xr[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); xi[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); yr[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); yi[i] = t; end
            for (int f = 0; f < 4; f++) begin
                for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); wr[f][i] = t; end
                for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); wi[f][i] = t; end
            end
            for (int j = 0; j < 4; j++) code += $fscanf(fd, "%d", ex[j]);
            if (code != 12 * N + 4) break;

            #1;
            if (yx_re !== ex[0] || yx_im !== ex[1] || yy_re !== ex[2] || yy_im !== ex[3]) begin
                errors++;
                if (errors <= 5) $display("row %0d: got (%0d,%0d,%0d,%0d) exp (%0d,%0d,%0d,%0d)",
                                          rows, yx_re, yx_im, yy_re, yy_im, ex[0], ex[1], ex[2], ex[3]);
            end
            rows++;
        end
        $fclose(fd);
        $display("tb_butterfly: %0d rows, %0d errors -> %s", rows, errors,
                 (errors == 0 && rows > 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
