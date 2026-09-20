`timescale 1ns / 1ps

module matched_filter #(
    parameter NUM_TAPS = 17
)(
    input  logic               clk,
    input logic                rst,
    input  logic signed [7:0]  sample_in,
    output logic signed [17:0] sample_out
);


    // istantiate Shift register
  

    logic signed [7:0] shift_reg [0:NUM_TAPS-1];

    initial begin
        for (int i = 0; i < NUM_TAPS; i++) begin
            shift_reg[i] = 0;
        end
    end


    // RRC filter coefficients
    // Coefficients are scaled by 128 (2^7)


    logic signed [7:0] taps [0:NUM_TAPS-1];

    initial begin
        `include "rrc_coefficients.vh"
    end



    // Shift input samples through the FIR


    always_ff @(posedge clk) begin

        for (int i = NUM_TAPS-1; i > 0; i--) begin
            shift_reg[i] <= shift_reg[i-1];
        end

        shift_reg[0] <= sample_in;

    end


  
    // Multiplication results
    // 8-bit sample × 8-bit coefficient = 16-bit product


    logic signed [15:0] mul [0:NUM_TAPS-1];


 
    // Accumulator
    // Wider than individual products because 17 products
    // are being added together.

    logic signed [23:0] accumulator;



    // FIR calculation

    always_comb begin

        // Calculate all sample × coefficient products
        for (int i = 0; i < NUM_TAPS; i++) begin
            mul[i] = shift_reg[i] * taps[i];
        end


        // Accumulate all products
        accumulator = 0;

        for (int i = 0; i < NUM_TAPS; i++) begin
            accumulator = accumulator + mul[i];
        end


        // RRC coefficients were multiplied by 128 = 2^7.
        // Shift right by 7 bits to restore the original scale.
        //adding 64 ensures that the numbers are rounded 
        sample_out = (accumulator + 64) >>> 7;

    end



    // Display coefficients for simulation
 

    initial begin

        for (int i = 0; i < NUM_TAPS; i++) begin
            $display("taps[%0d] = %0d", i, taps[i]);
        end

    end

endmodule