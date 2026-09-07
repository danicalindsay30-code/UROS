`timescale 1ns / 1ps

module FIR_filter_tb;

localparam NUM_TAPS = 21;

logic clk;
logic signed [7:0] sample_in;
logic signed [17:0] sample_out;

// Instantiate DUT
FIR_filter #(
    .NUM_TAPS(NUM_TAPS)
) dut (
    .clk(clk),
    .sample_in(sample_in),
    .sample_out(sample_out)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Apply input samples
initial begin

    sample_in = 0;

    for (int i = 1; i <= (NUM_TAPS*1.5); i++) begin
        @(posedge clk);
        sample_in = i;
    end

    repeat (3) @(posedge clk);

    $finish;

end

// Display results every clock
always @(posedge clk) begin

    $display("--------------------------------");
    $display("Time   = %0t", $time);
    $display("Input  = %0d", sample_in);

    $display("Shift Registers:");
    for (int i = 0; i < NUM_TAPS; i++) begin
        $display("SR[%0d] = %0d", i, dut.shift_reg[i]);
    end

    $display("Output = %0d", sample_out);

end

endmodule