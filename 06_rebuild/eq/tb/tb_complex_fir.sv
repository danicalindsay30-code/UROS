`timescale 1ns / 1ps
//=====================================================================
// tb_complex_fir: file-driven, same pattern as tb_cma_error
//---------------------------------------------------------------------
// unit_fir.txt row: xr[N] xi[N] wr[N] wi[N] sum_re sum_im
// The sum is exact, so any difference is a real bug.
//=====================================================================

import eq_pkg::*;

module tb_complex_fir;

    localparam int    N   = 5;
    localparam int    SW  = P_W + 1 + $clog2(N);
    localparam string VEC = "C:/dev/UROS/06_rebuild/eq/vectors/N5/unit_fir.txt";

    logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1];
    logic signed [W_W-1:0] wr [0:N-1], wi [0:N-1];
    logic signed [SW-1:0]  sr, si;

    complex_fir #(.N(N)) u_dut (.*);

    initial begin
        int fd, code, rows, errors;
        longint t, e_r, e_i;

        fd = $fopen(VEC, "r");
        if (fd == 0) begin $display("cannot open %s", VEC); $finish; end
        rows = 0; errors = 0;

        while (!$feof(fd)) begin
            code = 0;
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); xr[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); xi[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); wr[i] = t; end
            for (int i = 0; i < N; i++) begin code += $fscanf(fd, "%d", t); wi[i] = t; end
            code += $fscanf(fd, "%d", e_r);
            code += $fscanf(fd, "%d", e_i);
            if (code != 4 * N + 2) break;

            #1;
            if (sr !== e_r || si !== e_i) begin
                errors++;
                if (errors <= 5) $display("row %0d: got (%0d,%0d) exp (%0d,%0d)", rows, sr, si, e_r, e_i);
            end
            rows++;
        end
        $fclose(fd);
        $display("tb_complex_fir: %0d rows, %0d errors -> %s", rows, errors,
                 (errors == 0 && rows > 0) ? "PASS" : "FAIL");
        $finish;
    end

endmodule
