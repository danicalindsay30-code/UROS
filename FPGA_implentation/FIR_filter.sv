`timescale 1ns / 1ps

module FIR_filter(
    input  logic              clk,
    input  logic signed [7:0] sample_in,
    output logic signed [17:0] sample_out
);


    // FIR coefficients
    logic signed [7:0] taps [0:3];

    initial begin
        taps[0] = 8'sd1;
        taps[1] = 8'sd2;
        taps[2] = 8'sd3;
        taps[3] = 8'sd4;
    end


    // Delay line (shift register)
    logic signed [7:0] shift_reg [0:3];

    always_ff @(posedge clk) begin
        shift_reg[3] <= shift_reg[2];
        shift_reg[2] <= shift_reg[1];
        shift_reg[1] <= shift_reg[0];
        shift_reg[0] <= sample_in;
    end


    // Multiplication results
    logic signed [15:0] mul [0:3];


    // Combinational FIR output
    always_comb begin
        mul[0] = shift_reg[0] * taps[0];
        mul[1] = shift_reg[1] * taps[1];
        mul[2] = shift_reg[2] * taps[2];
        mul[3] = shift_reg[3] * taps[3];

        sample_out = mul[0] + mul[1] + mul[2] + mul[3];
    end

endmodule