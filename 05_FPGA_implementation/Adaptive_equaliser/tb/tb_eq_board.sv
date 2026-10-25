`timescale 1ns / 1ps
//=====================================================================
// tb_eq_board: simulate exactly what will run on the KR260
//---------------------------------------------------------------------
// Only a clock and a reset, like the board. Waits for done, then reads
// the same pass / err_count the VIO will show. If this passes, the
// board should show pass = 1, err_count = 0, out_count = 10004.
//=====================================================================

module tb_eq_board;

    localparam string MEM = "C:/dev/UROS/05_FPGA_implementation/Adaptive_equaliser/vectors/N5/";

    logic clk = 0, rst = 1;
    always #5 clk = ~clk;

    logic        done, pass, out_valid;
    logic [15:0] out_count, err_count;
    logic signed [15:0] yx_re, yx_im, yy_re, yy_im;

    eq_board_top #(.IN_MEM({MEM, "eq_in_rom.mem"}), .REF_MEM({MEM, "eq_ref_rom.mem"})) u_top (.*);

    initial begin
        repeat (10) @(posedge clk);
        rst = 0;
        wait (done);
        repeat (5) @(posedge clk);
        $display("tb_eq_board: done=%0d out_count=%0d err_count=%0d -> %s (at %0t ns)",
                 done, out_count, err_count, pass ? "PASS" : "FAIL", $time);
        $finish;
    end

    initial begin
        #5_000_000;
        $display("tb_eq_board: TIMEOUT out_count=%0d err_count=%0d -> FAIL", out_count, err_count);
        $finish;
    end

endmodule
