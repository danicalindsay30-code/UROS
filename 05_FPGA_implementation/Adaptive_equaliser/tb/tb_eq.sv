`timescale 1ns / 1ps
//=====================================================================
// tb_eq: the full equaliser against cma_int.py
//---------------------------------------------------------------------
// Same idea as the matched filter testbench: a DRIVER pushes samples
// in, a separate MONITOR checks every output when out_valid is high.
// New here: a ready/valid handshake, because the equaliser only accepts
// a sample when in_ready is high (once every 6 clocks after the fill).
//
// The driver changes inputs on the FALLING edge, so the design (which
// samples on the rising edge) never races the testbench.
//
// PASS when: 10,004 outputs, 0 mismatches.
//=====================================================================

import eq_pkg::*;

module tb_eq;

    localparam int    N       = 5;
    localparam string DIR     = "C:/dev/UROS/05_FPGA_implementation/Adaptive_equaliser/vectors/N5/";
    localparam int    MAX_IN  = 20000;
    localparam string OUT_FILE = "C:/dev/UROS/05_FPGA_implementation/Adaptive_equaliser/results/rtl_out_N5.txt";

    logic clk = 0, rst = 1;
    always #5 clk = ~clk;                         // 100 MHz

    logic                  in_valid = 0, in_ready;
    logic signed [X_W-1:0] x_re_in = 0, x_im_in = 0, y_re_in = 0, y_im_in = 0;
    logic                  out_valid;
    logic signed [Y_W-1:0] yx_re, yx_im, yy_re, yy_im;
    logic signed [E_W-1:0] dbg_e_x, dbg_e_y;
    logic signed [G_W-1:0] dbg_gx_re, dbg_gx_im, dbg_gy_re, dbg_gy_im;

    cma_equaliser #(.N(N)) u_dut (.*);

    // ---- stimulus ------------------------------------------------------
    logic signed [X_W-1:0] stim [0:MAX_IN-1][0:3];
    int n_in = 0;

    task automatic load_stimulus;
        int fd, code, a, b, c, d;
        fd = $fopen({DIR, "eq_in.txt"}, "r");
        if (fd == 0) begin $display("cannot open eq_in.txt"); $finish; end
        while (!$feof(fd) && n_in < MAX_IN) begin
            code = $fscanf(fd, "%d %d %d %d\n", a, b, c, d);
            if (code == 4) begin
                stim[n_in][0] = a; stim[n_in][1] = b; stim[n_in][2] = c; stim[n_in][3] = d;
                n_in++;
            end
        end
        $fclose(fd);
        $display("loaded %0d input symbols", n_in);
    endtask

    // ---- monitor: compare every output with eq_out_ref.txt -----------
    int fd_ref, fd_dbg, fd_out;
    int outputs = 0, errors = 0;
    int cycle = 0, first_in_cycle = -1, first_out_cycle = -1;

    always @(posedge clk) cycle <= cycle + 1;

    always @(posedge clk) begin
        if (!rst && in_valid && in_ready && first_in_cycle < 0) first_in_cycle = cycle;
        if (!rst && out_valid) begin
            int code, k, r [0:3], d [0:6];
            code = $fscanf(fd_ref, "%d %d %d %d %d", k, r[0], r[1], r[2], r[3]);
            void'($fscanf(fd_dbg, "%d %d %d %d %d %d %d", d[0], d[1], d[2], d[3], d[4], d[5], d[6]));
            $fwrite(fd_out, "%0d %0d %0d %0d\n", yx_re, yx_im, yy_re, yy_im);
            if (first_out_cycle < 0) first_out_cycle = cycle;
            if (code != 5) begin
                errors++;
                $display("more outputs than reference rows");
            end
            else if (yx_re !== r[0] || yx_im !== r[1] || yy_re !== r[2] || yy_im !== r[3]) begin
                errors++;
                if (errors <= 5) begin
                    $display("k=%0d: y got (%0d,%0d,%0d,%0d) exp (%0d,%0d,%0d,%0d)",
                             k, yx_re, yx_im, yy_re, yy_im, r[0], r[1], r[2], r[3]);
                    $display("      e,g got (%0d,%0d | %0d,%0d,%0d,%0d) exp (%0d,%0d | %0d,%0d,%0d,%0d)",
                             dbg_e_x, dbg_e_y, dbg_gx_re, dbg_gx_im, dbg_gy_re, dbg_gy_im,
                             d[1], d[2], d[3], d[4], d[5], d[6]);
                end
            end
            outputs++;
        end
    end

    // ---- driver ----------------------------------------------------------
    initial begin
        load_stimulus();
        fd_ref = $fopen({DIR, "eq_out_ref.txt"}, "r");
        fd_dbg = $fopen({DIR, "eq_dbg_ref.txt"}, "r");
        fd_out = $fopen(OUT_FILE, "w");
        if (fd_ref == 0 || fd_dbg == 0 || fd_out == 0) begin $display("cannot open files"); $finish; end

        repeat (5) @(posedge clk);
        rst = 0;

        for (int i = 0; i < n_in; i++) begin
            @(negedge clk);
            while (!in_ready) @(negedge clk);     // wait until the equaliser can take a sample
            x_re_in = stim[i][0]; x_im_in = stim[i][1];
            y_re_in = stim[i][2]; y_im_in = stim[i][3];
            in_valid = 1;
        end
        @(negedge clk);
        in_valid = 0;
        repeat (20) @(posedge clk);

        $fclose(fd_ref); $fclose(fd_dbg); $fclose(fd_out);
        $display("tb_eq: %0d inputs, %0d outputs (expected %0d), %0d mismatches -> %s",
                 n_in, outputs, n_in - (N - 1), errors,
                 (errors == 0 && outputs == n_in - (N - 1)) ? "PASS" : "FAIL");
        $display("first input accepted at cycle %0d, first output at cycle %0d, total cycles %0d",
                 first_in_cycle, first_out_cycle, cycle);
        $finish;
    end

    initial begin
        #5_000_000;
        $display("tb_eq: TIMEOUT");
        $finish;
    end

endmodule
