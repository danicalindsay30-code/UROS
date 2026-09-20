`timescale 1ns / 1ps

module matched_filter_pipeline #(
    parameter NUM_TAPS = 17
)(
    input  logic               clk,
    input logic                rst,
    input  logic signed [7:0]  sample_in,
    output logic signed [17:0] sample_out
);
//internal wires 
logic signed [7:0] shift_reg [0:NUM_TAPS-1];//each element 8 bits signed, number of elements tap length
logic signed [15:0] product_reg [0:NUM_TAPS -1];
logic signed [7:0] taps [0:NUM_TAPS-1];

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        for (int i = 0; i < NUM_TAPS; i++) begin
            shift_reg[i] <= '0;
            product_reg[i] <= '0;
        end
    end
    else begin
        // Stage 0: shift register

        for (int i = NUM_TAPS-1; i > 0; i--) begin
            shift_reg[i] <= shift_reg[i-1];
        end

        shift_reg[0] <= sample_in;

        // Stage 1: registered products

        for (int i = 0; i < NUM_TAPS; i++) begin
            product_reg[i] <= shift_reg[i] * taps[i];
        end
    end
end


endmodule
