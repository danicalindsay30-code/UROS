`timescale 1ns / 1ps
//=====================================================================
// dp_matched_filter_pipeline_tb
//---------------------------------------------------------------------
// The key difference from the old testbench:
//
//   OLD: apply a sample, wait a fixed number of cycles, write output.
//        The testbench had to know the pipeline latency. Change the
//        pipeline depth and the testbench breaks.
//
//   NEW: a driver pushes samples in, and a SEPARATE monitor writes a
//        row every time valid_out is high. The monitor does not know
//        or care what the latency is. Change the pipeline depth and
//        nothing here needs editing.
//
// That is the whole reason valid signals exist in real designs.
//=====================================================================

module dp_matched_filter_pipeline_tb;

    localparam int NUM_TAPS   = 17;
    localparam int MAX_SAMPLE = 2000;   // array size, not the real count
    localparam     CLK_HALF   = 5.0;    // 10 ns period = 100 MHz

    localparam string IN_FILE  = "C:/dev/UROS/03_Data/MF_input_samples.txt";
    localparam string OUT_FILE = "C:/dev/UROS/03_Data/MF_sv_filter_output.txt";

    //-----------------------------------------------------------------
    // DUT signals
    //-----------------------------------------------------------------
    logic clk = 0;
    logic rst = 1;
    logic valid_in = 0;

    logic signed [7:0] Ix = 0, Qx = 0, Iy = 0, Qy = 0;

    logic valid_out;
    logic signed [17:0] Ix_out, Qx_out, Iy_out, Qy_out;

    dp_matched_filter_pipeline #(.NUM_TAPS(NUM_TAPS)) dut (
        .clk(clk), .rst(rst), .valid_in(valid_in),
        .Ix(Ix), .Qx(Qx), .Iy(Iy), .Qy(Qy),
        .valid_out(valid_out),
        .Ix_out(Ix_out), .Qx_out(Qx_out), .Iy_out(Iy_out), .Qy_out(Qy_out)
    );

    always #(CLK_HALF) clk = ~clk;

    //-----------------------------------------------------------------
    // Storage for the stimulus
    //-----------------------------------------------------------------
    logic signed [7:0] samples [0:MAX_SAMPLE-1][0:3];
    int n_samples = 0;

    int infile, outfile, code;
    int rows_written = 0;
    bit driving_done = 0;

    //-----------------------------------------------------------------
    // Read the stimulus file. The sample count is counted, not
    // hardcoded, so regenerating the data with a different length
    // does not silently read the wrong amount.
    //-----------------------------------------------------------------
    task automatic load_stimulus;
        int a, b, c, d;
        infile = $fopen(IN_FILE, "r");
        if (infile == 0) begin
            $display("ERROR: cannot open %s", IN_FILE);
            $finish;
        end
        n_samples = 0;
        while (!$feof(infile) && n_samples < MAX_SAMPLE) begin
            code = $fscanf(infile, "%d %d %d %d\n", a, b, c, d);
            if (code == 4) begin
                samples[n_samples][0] = a[7:0];
                samples[n_samples][1] = b[7:0];
                samples[n_samples][2] = c[7:0];
                samples[n_samples][3] = d[7:0];
                n_samples++;
            end
        end
        $fclose(infile);
        $display("loaded %0d input samples", n_samples);
    endtask

    //-----------------------------------------------------------------
    // MONITOR
    // Writes a row whenever valid_out is high. Knows nothing about
    // the pipeline depth.
    //-----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst && valid_out) begin
            $fwrite(outfile, "%0d %0d %0d %0d\n",
                    Ix_out, Qx_out, Iy_out, Qy_out);
            rows_written <= rows_written + 1;
        end
    end

    //-----------------------------------------------------------------
    // DRIVER
    //-----------------------------------------------------------------
    initial begin
        load_stimulus();

        outfile = $fopen(OUT_FILE, "w");
        if (outfile == 0) begin
            $display("ERROR: cannot open %s for writing", OUT_FILE);
            $finish;
        end

        // Reset: hold for several cycles, release on a clock edge.
        rst = 1;
        valid_in = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Drive one sample per clock, valid high throughout.
        for (int i = 0; i < n_samples; i++) begin
            Ix <= samples[i][0];
            Qx <= samples[i][1];
            Iy <= samples[i][2];
            Qy <= samples[i][3];
            valid_in <= 1;
            @(posedge clk);
        end

        // Flush: keep valid high with zero data so the tail of the
        // impulse response is produced, then drop valid and let the
        // pipeline drain.
        Ix <= 0; Qx <= 0; Iy <= 0; Qy <= 0;
        repeat (NUM_TAPS - 1) @(posedge clk);

        valid_in <= 0;
        repeat (32) @(posedge clk);     // generous: covers any latency

        driving_done = 1;
        $fclose(outfile);

        $display("wrote %0d output rows to %s", rows_written, OUT_FILE);
        $display("expected %0d valid rows (%0d samples + %0d flush)",
                 n_samples + NUM_TAPS - 1, n_samples, NUM_TAPS - 1);

        if (rows_written != n_samples + NUM_TAPS - 1)
            $display("WARNING: row count does not match expectation - check the valid pipeline depth");

        $display("simulation complete");
        $finish;
    end

    //-----------------------------------------------------------------
    // Safety net: never let the simulation hang forever.
    //-----------------------------------------------------------------
    initial begin
        #1_000_000;
        $display("ERROR: timeout");
        $finish;
    end

endmodule