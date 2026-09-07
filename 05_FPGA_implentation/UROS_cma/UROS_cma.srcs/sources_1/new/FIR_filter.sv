`timescale 1ns / 1ps

module FIR_filter#(
    parameter NUM_TAPS = 21)(
    input  logic              clk,
    input  logic signed [7:0] sample_in,
    output logic signed [17:0] sample_out
);


    // FIR coefficients
    logic signed [7:0] taps [0:NUM_TAPS-1];
    // Delay line (shift register)
    logic signed [7:0] shift_reg [0:NUM_TAPS-1];

    initial begin
        for(int i =0; i<NUM_TAPS;i++)begin
        taps[i] = i+1;
        shift_reg[i]=0;
        end
    end

 

    always_ff @(posedge clk) begin

    // Shift all previous samples one position down the delay line
    for (int i = NUM_TAPS-1; i > 0; i--) begin
        shift_reg[i] <= shift_reg[i-1];
    end

    // Load the newest sample
    shift_reg[0] <= sample_in;

end


  // Multiplication results
logic signed [15:0] mul [0:NUM_TAPS-1];

// Combinational FIR output
always_comb begin

    // Multiply each sample by its corresponding coefficient
    for (int i = 0; i < NUM_TAPS; i++) begin
        mul[i] = shift_reg[i] * taps[i];
    end

    // Sum all multiplication results
    sample_out = 0;

    for (int i = 0; i < NUM_TAPS; i++) begin
        sample_out += mul[i];
    end
    end
    
  endmodule 
    
    
 

