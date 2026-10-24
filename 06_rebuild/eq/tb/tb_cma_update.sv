`timescale 1ns / 1ps
//=====================================================================
// tb_cma_update: file-driven, same pattern
//---------------------------------------------------------------------
// unit_update.txt row:
//     gx_re gx_im gy_re gy_im   xr[N] xi[N] yr[N] yi[N]
//     4 filters BEFORE (f = XX, XY, YX, YY: wr[N] wi[N])   4 filters AFTER (same layout)
//=====================================================================

import eq_pkg::*;

module tb_cma_update;

    localparam int    N   = 5;
    localparam string VEC = "C:/dev/UROS/06_rebuild/eq/vectors/N5/unit_update.txt";

    logic signed [G_W-1:0] gx_re, gx_im, gy_re, gy_im;
    logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1], yr [0:N-1], yi [0:N-1];
    logic signed [W_W-1:0] wr [0:3][0:N-1], wi [0:3][0:N-1];
    logic signed [W_W-1:0] wr_new [0:3][0:N-1], wi_new [0:3][0:N-1];
    longint                er [0:3][0:N-1], ei [0:3][0:N-1];   // expected

    cma_update #(.N(N)) u_dut (.*);

    initial begin
        int fd, code, rows, errors;
        longint t;

        fd = $fopen(VEC, "r");
        if (fd == 0) begin $display("cannot open %s", VEC); $finish; end
        rows = 0; errors = 0;

        while (!$feof(fd)) begin
            code = 0;
            code += $fscanf(fd, "%d", t); gx_re = t;
            code += $fscanf(fd, "%d", t); gx_im = t;
            code += $fscanf(fd, "%d", t); gy_re = t;
            code += $fscanf(fd, "%d", t); gy_im = t;
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); xr[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); xi[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); yr[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); yi[i] = t; end
            for (int f = 0; f < 4; f++) begin
                for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); wr[f][i] = t; end
                for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); wi[f][i] = t; end
            end
            for (int f = 0; f < 4; f++) begin
                for (int i = 0; i < N; i++) code += $fscanf(fd, "%d", er[f][i]);
                for (int i = 0; i < N; i++) code += $fscanf(fd, "%d", ei[f][i]);
            end
            if (code != 4 + 20 * N) break;

            #1;
            for (int f = 0; f < 4; f++)
                for (int i = 0; i < N; i++)
                    if (wr_new[f][i] !== er[f][i] || wi_new[f][i] !== ei[f][i]) begin
                        errors++;
                        if (errors <= 5) $display("row %0d filter %0d tap %0d: got (%0d,%0d) exp (%0d,%0d)",
                                                  rows, f, i, wr_new[f][i], wi_new[f][i], er[f][i], ei[f][i]);
                    end
            rows++;
        end
        $fclose(fd);
        $display("tb_cma_update: %0d rows, %0d errors -> %s", rows, errors,
                 (errors == 0 && rows > 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
