`timescale 1ns / 1ps
//=====================================================================
// top_module_tb
//---------------------------------------------------------------------
// Proves the hardware test harness works BEFORE it goes near the board.
//
// If this produces 132 rows identical to MF_sv_filter_output.txt, then
// the ROM, the counter and the valid alignment are all correct, and
// anything that fails on the board is a board problem rather than a
// harness problem. That distinction saves hours of debugging.
//
// Note there is no stimulus here. The samples live in the ROM inside
// the DUT. All this testbench does is release reset and record what
// comes out - exactly what the VIO and ILA will do on the board.
//=====================================================================

module top_module_tb;

    localparam CLK_HALF = 5.0;      // 10 ns period, 100 MHz
    localparam string OUT_FILE = "C:/dev/UROS/03_Data/MF_board_sim_out.txt";

    logic clk = 0;
    logic rst = 1;

    logic               valid_out;
    logic signed [17:0] Ix_out, Qx_out, Iy_out, Qy_out;

    top_module dut (
        .clk       (clk),
        .rst       (rst),
        .valid_out (valid_out),
        .Ix_out    (Ix_out),
        .Qx_out    (Qx_out),
        .Iy_out    (Iy_out),
        .Qy_out    (Qy_out)
    );

    always #(CLK_HALF) clk = ~clk;

    int outfile;
    int rows = 0;

    //-----------------------------------------------------------------
    // Monitor: one row per valid output. Knows nothing about latency.
    //-----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst && valid_out) begin
            $fwrite(outfile, "%0d %0d %0d %0d\n",
                    Ix_out, Qx_out, Iy_out, Qy_out);
            rows <= rows + 1;
        end
    end

    //-----------------------------------------------------------------
    // Run
    //-----------------------------------------------------------------
    initial begin
        outfile = $fopen(OUT_FILE, "w");
        if (outfile == 0) begin
            $display("ERROR: cannot open %s", OUT_FILE);
            $finish;
        end

        // Hold reset, then release - the VIO does this on the board.
        rst = 1;
        repeat (10) @(posedge clk);
        rst = 0;

        // 132 samples + pipeline latency, with plenty of margin.
        repeat (250) @(posedge clk);

        $fclose(outfile);

        $display("wrote %0d rows to %s", rows, OUT_FILE);
        $display("expected 132 rows (116 samples + 16 flush)");

        if (rows != 132)
            $display("WARNING: row count wrong - check the valid alignment");

        $finish;
    end

    //-----------------------------------------------------------------
    // Sanity check on the first sample out of the ROM. Should be
    // Ix=-21 Qx=9 Iy=-6 Qy=2 on the first clock where valid_in is high.
    //-----------------------------------------------------------------
    initial begin
        @(negedge rst);
        @(posedge clk);
        @(posedge clk);
        $display("first unpacked sample: Ix=%0d Qx=%0d Iy=%0d Qy=%0d",
                 dut.Ix_m, dut.Qx_m, dut.Iy_m, dut.Qy_m);
        $display("  expected: Ix=-21 Qx=9 Iy=-6 Qy=2");
    end

endmodule