
`timescale 1ns / 1ps

module tb_fir4;

    logic tb_clk, tb_rst;
    logic signed [7:0] tb_in;
    logic signed [11:0] tb_out;

    integer error_count = 0;

    // Device under test
    fir4 dut (
        .clk(tb_clk),
        .rst(tb_rst),
        .in(tb_in),
        .out(tb_out)
    );

    // Clock: 10 ns period
    initial begin
        tb_clk = 0;
        forever #5 tb_clk = ~tb_clk;
    end

    // Input sequences
    logic impulse [0:5] = '{1, 0, 0, 0, 0, 0};
    logic step_seq [0:5] = '{1, 1, 1, 1, 1, 1};

    // Expected outputs, including one cycle of latency
    logic signed [11:0] expected_impulse [0:6]
        = '{0, 1, 2, 3, 4, 0, 0};

    logic signed [11:0] expected_step [0:6]
        = '{0, 1, 3, 6, 10, 10, 10};

    initial begin
        tb_rst = 1;
        tb_in  = 0;

        // Apply reset for two rising edges
        repeat (2) @(posedge tb_clk);

        @(negedge tb_clk);
        tb_rst = 0;

        // --------------------------------
        // Test 1: Impulse response
        // --------------------------------
        $display("Testing impulse response");

        for (int i = 0; i < 7; i++) begin
            @(negedge tb_clk);

            // Drive six samples, then flush the final response
            if (i < 6)
                tb_in = impulse[i];
            else
                tb_in = 0;

            @(posedge tb_clk);
            #1;

            if (tb_out !== expected_impulse[i]) begin
                error_count++;
                $display(
                    "IMPULSE ERROR at cycle %0d: expected %0d, got %0d",
                    i, expected_impulse[i], tb_out
                );
            end
            else begin
                $display(
                    "Impulse cycle %0d: output = %0d PASS",
                    i, tb_out
                );
            end
        end

        // --------------------------------
        // Reset before the step response
        // --------------------------------
        @(negedge tb_clk);
        tb_rst = 1;
        tb_in  = 0;

        repeat (2) @(posedge tb_clk);

        @(negedge tb_clk);
        tb_rst = 0;

        // --------------------------------
        // Test 2: Step response
        // --------------------------------
        $display("Testing step response");

        for (int i = 0; i < 7; i++) begin
            @(negedge tb_clk);

            if (i < 6)
                tb_in = step_seq[i];
            else
                tb_in = 0;

            @(posedge tb_clk);
            #1;

            if (tb_out !== expected_step[i]) begin
                error_count++;
                $display(
                    "STEP ERROR at cycle %0d: expected %0d, got %0d",
                    i, expected_step[i], tb_out
                );
            end
            else begin
                $display(
                    "Step cycle %0d: output = %0d PASS",
                    i, tb_out
                );
            end
        end

        // --------------------------------
        // Final result
        // --------------------------------
        $display("--------------------------------");

        if (error_count == 0)
            $display("PASS: All tests passed");
        else
            $display("FAIL: %0d errors detected", error_count);

        $finish;
    end

endmodule
