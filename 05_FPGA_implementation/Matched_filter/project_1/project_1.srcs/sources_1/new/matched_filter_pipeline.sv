`timescale 1ns / 1ps

module matched_filter_pipeline #(
    parameter NUM_TAPS = 17
)(
    input  logic               clk,
    input  logic               rst,
    input  logic signed [7:0]  sample_in,
    output logic signed [17:0] sample_out
);


    // Internal registers
  

    logic signed [7:0] shift_reg [0:NUM_TAPS-1];
    logic signed [15:0] product_reg [0:NUM_TAPS-1];
    logic signed [23:0] partial_sum [0:3];
    logic signed [23:0] accumulator_reg;
    logic signed [23:0] scaled_val;


 
    // RRC filter coefficients
 

    logic signed [7:0] taps [0:NUM_TAPS-1];

    initial begin
        `include "rrc_coefficients.vh"
    end


    // Pipelined FIR filter
 

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            // Reset shift register and product registers

            for (int i = 0; i < NUM_TAPS; i++) begin
                shift_reg[i]  <= '0;
                product_reg[i] <= '0;
            end

            // Reset partial sums

            for (int i = 0; i < 4; i++) begin
                partial_sum[i] <= '0;
            end

            // Reset remaining pipeline registers

            accumulator_reg <= '0;
            scaled_val      <= '0;
            sample_out      <= '0;

        end

        else begin

           
            // Stage 0: Shift register
          

            for (int i = NUM_TAPS-1; i > 0; i--) begin
                shift_reg[i] <= shift_reg[i-1];
            end

            shift_reg[0] <= sample_in;


            // Stage 1: Registered products
           

            for (int i = 0; i < NUM_TAPS; i++) begin
                product_reg[i] <= shift_reg[i] * taps[i];
            end


          
            // Stage 2: Registered partial sums
           

            partial_sum[0] <= product_reg[0]
                            + product_reg[1]
                            + product_reg[2]
                            + product_reg[3];

            partial_sum[1] <= product_reg[4]
                            + product_reg[5]
                            + product_reg[6]
                            + product_reg[7];

            partial_sum[2] <= product_reg[8]
                            + product_reg[9]
                            + product_reg[10]
                            + product_reg[11];

            partial_sum[3] <= product_reg[12]
                            + product_reg[13]
                            + product_reg[14]
                            + product_reg[15]
                            + product_reg[16];


  
            // Stage 3: Final accumulation
   

            accumulator_reg <= partial_sum[0]
                             + partial_sum[1]
                             + partial_sum[2]
                             + partial_sum[3];


         
            // Stage 4: Scaling and output
           

            scaled_val <= (accumulator_reg + 24'sd64) >>> 7;

            sample_out <= scaled_val;

        end

    end

endmodule