
`timescale 1ns / 1ps

module tb_counter;

    logic clk, rst, ena;
    logic [7:0] count;

    // Instantiate the design under test
    counter dut (
        .rst   (rst),
        .clk   (clk),
        .ena   (ena),
        .count (count)
    );

    // Generate clock: 20 ns period, 50 MHz
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Print simulation time and count whenever either changes
    initial begin
        $monitor("Time = %0t ns, count = %0d", $time, count);
    end

    // Generate reset and counting stimulus
    initial begin
        rst = 1;
        ena = 0;

        // Hold reset for 3 rising clock edges
        repeat (3) begin
            @(posedge clk);
        end

        // Release reset and enable counting on a falling edge
        @(negedge clk);
        rst = 0;
        ena = 1;

        // Allow 20 rising edges for counting
        repeat (20) begin
            @(posedge clk);
        end

        // Stop counting
        @(negedge clk);
        ena = 0;

        // End simulation
        #1;
        $finish;
    end

endmodule
