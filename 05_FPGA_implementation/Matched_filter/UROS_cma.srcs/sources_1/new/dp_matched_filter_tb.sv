`timescale 1ns / 1ps

module dp_matched_filter_tb;

    localparam NUM_TAPS = 17;
    localparam NUM_BITS = 116;

    logic clk;

    // Input: X polarisation
    logic signed [7:0] Ix;
    logic signed [7:0] Qx;

    // Input: Y polarisation
    logic signed [7:0] Iy;
    logic signed [7:0] Qy;

    // Output: X polarisation
    logic signed [17:0] Ix_out;
    logic signed [17:0] Qx_out;

    // Output: Y polarisation
    logic signed [17:0] Iy_out;
    logic signed [17:0] Qy_out;


    // =========================================================
    // Instantiate DUT
    // =========================================================

    dp_matched_filter #(
        .NUM_TAPS(NUM_TAPS)
    ) dut (
        .clk(clk),
        .rst(rst),

        .Ix(Ix),
        .Qx(Qx),
        .Iy(Iy),
        .Qy(Qy),

        .Ix_out(Ix_out),
        .Qx_out(Qx_out),
        .Iy_out(Iy_out),
        .Qy_out(Qy_out)
    );


    // =========================================================
    // Clock generation
    // =========================================================

    initial begin
        clk = 0;

        forever #10 clk = ~clk;
    end


    // =========================================================
    // Input sample storage
    //
    // Column 0 = X real
    // Column 1 = X imaginary
    // Column 2 = Y real
    // Column 3 = Y imaginary
    // =========================================================

    logic signed [7:0] samples [0:NUM_BITS-1][0:3];

    int status;
    int file;
    int outfile;


    // =========================================================
    // Read input samples
    // =========================================================

    initial begin

        file = $fopen(
            "C:/dev/UROS/03_Data/MF_input_samples.txt",
            "r"
        );

        if (file == 0) begin
            $display("ERROR: Could not open input_samples.txt");
            $finish;
        end

        for (int i = 0; i < NUM_BITS; i++) begin

            status = $fscanf(
                file,
                "%d %d %d %d\n",
                samples[i][0],
                samples[i][1],
                samples[i][2],
                samples[i][3]
            );

            if (status != 4) begin
                $display("ERROR reading input sample %0d", i);
                $finish;
            end

        end

        $fclose(file);

        $display("Successfully loaded %0d input samples.", NUM_BITS);

    end


    // =========================================================
    // Apply samples and record FIR output
    // =========================================================

    initial begin

        outfile = $fopen(
            "C:/dev/UROS/03_Data/MF_sv_filter_output.txt",
            "w"
        );

        if (outfile == 0) begin
            $display("ERROR: Couldn't open output file.");
            $finish;
        end


        // Initialise inputs
        Ix = 0;
        Qx = 0;
        Iy = 0;
        Qy = 0;

        #1;


        // =====================================================
        // Process input samples
        // =====================================================

        for (int i = 0; i < NUM_BITS; i++) begin

            // Apply input between clock edges
            @(negedge clk);

            Ix = samples[i][0];
            Qx = samples[i][1];
            Iy = samples[i][2];
            Qy = samples[i][3];


            // FIR processes sample at next rising edge
            @(posedge clk);

            // Allow non-blocking assignments and
            // combinational FIR logic to settle
            #1;


            // Display output
            $display(
                "sample %0d: %0d %0d %0d %0d",
                i,
                Ix_out,
                Qx_out,
                Iy_out,
                Qy_out
            );


            // Save output
            $fwrite(
                outfile,
                "%0d %0d %0d %0d\n",
                Ix_out,
                Qx_out,
                Iy_out,
                Qy_out
            );

        end


        // =====================================================
        // Flush FIR
        //
        // NUM_TAPS-1 zeros are required to empty the delay line.
        // =====================================================

        for (int i = 0; i < NUM_TAPS-1; i++) begin

            @(negedge clk);

            Ix = 0;
            Qx = 0;
            Iy = 0;
            Qy = 0;

            @(posedge clk);

            #1;

            $display(
                "flush %0d: %0d %0d %0d %0d",
                i,
                Ix_out,
                Qx_out,
                Iy_out,
                Qy_out
            );

            $fwrite(
                outfile,
                "%0d %0d %0d %0d\n",
                Ix_out,
                Qx_out,
                Iy_out,
                Qy_out
            );

        end


        // =====================================================
        // Finish
        // =====================================================

        $fclose(outfile);

        $display("FIR simulation complete.");

        $finish;

    end

endmodule