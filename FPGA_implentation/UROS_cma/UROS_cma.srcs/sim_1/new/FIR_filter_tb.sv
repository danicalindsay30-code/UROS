`timescale 1ns / 1ps

module FIR_filter_tb;

logic clk;
logic signed [7:0] sample_in;
logic signed [17:0] sample_out;

FIR_filter dut (
    .clk(clk),
    .sample_in(sample_in),
    .sample_out(sample_out)
);

initial begin

clk = 0;
forever #5 clk = ~clk;
end 
// Apply test samples
initial begin

    sample_in = 0;

    @(posedge clk); sample_in = 1;
    @(posedge clk); sample_in = 2;
    @(posedge clk); sample_in = 3;
    @(posedge clk); sample_in = 4;
    @(posedge clk); sample_in = 5;
    @(posedge clk); sample_in = 6;

    repeat (3) @(posedge clk);

    $finish;
end

// Display values every clock edge
always @(posedge clk) begin
    $display("--------------------------------");
    $display("Time = %0t", $time);
    $display("Input  = %0d", sample_in);

    $display("Shift Registers:");
    $display("SR0 = %0d", dut.shift_reg[0]);
    $display("SR1 = %0d", dut.shift_reg[1]);
    $display("SR2 = %0d", dut.shift_reg[2]);
    $display("SR3 = %0d", dut.shift_reg[3]);

    $display("Output = %0d", sample_out);
end

endmodule