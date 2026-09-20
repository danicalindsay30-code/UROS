`timescale 1ns / 1ps

module matched_filter_pipeline #(
    parameter NUM_TAPS = 17
)(
    input  logic               clk,
    input  logic               rst,

    input  logic               valid_in,
    input  logic signed [7:0]  sample_in,

    output logic               valid_out,
    output logic signed [17:0] sample_out
);

    // Internal pipeline registers


    logic signed [7:0] shift_reg [0:NUM_TAPS-1];

    logic signed [15:0] product_reg [0:NUM_TAPS-1];

    logic signed [23:0] partial_sum [0:3];

    logic signed [23:0] accumulator_reg;

    logic signed [23:0] scaled_val;


  
    // Constant FIR coefficients
    // These are compile-time constants.
 

    localparam logic signed [7:0] TAPS [0:NUM_TAPS-1] = '{
         8'sd0,
         8'sd1,
        -8'sd2,
         8'sd2,
         8'sd5,
       -8'sd12,
        -8'sd8,
        8'sd55,
        8'sd99,
        8'sd55,
        -8'sd8,
       -8'sd12,
         8'sd5,
         8'sd2,
        -8'sd2,
         8'sd1,
         8'sd0
    };


 
    // Valid signal pipeline


    logic valid_stage0;
    logic valid_stage1;
    logic valid_stage2;
    logic valid_stage3;
    logic valid_stage4;



    // Sequential pipeline
  

    always_ff @(posedge clk ) begin

        if (rst) begin

            // Reset shift register and multiplier outputs

            for (int i = 0; i < NUM_TAPS; i++) begin
                shift_reg[i]   <= '0;
                product_reg[i] <= '0;
            end

            // Reset partial sums

            for (int i = 0; i < 4; i++) begin
                partial_sum[i] <= '0;
            end

            // Reset arithmetic registers

            accumulator_reg <= '0;
            scaled_val      <= '0;
            sample_out      <= '0;

            // Reset valid pipeline

            valid_stage0 <= 1'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
            valid_out    <= 1'b0;

        end

        else begin

        
            // Stage 0: shift register
       

            for (int i = NUM_TAPS-1; i > 0; i--) begin
                shift_reg[i] <= shift_reg[i-1];
            end

            shift_reg[0] <= sample_in;

            valid_stage0 <= valid_in;


        
            // Stage 1: registered multiplications
   

            for (int i = 0; i < NUM_TAPS; i++) begin
                product_reg[i] <= shift_reg[i] * TAPS[i];
            end

            valid_stage1 <= valid_stage0;


            // ------------------------------------------
            // Stage 2: registered partial sums
            // ------------------------------------------

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

            valid_stage2 <= valid_stage1;


     
            // Stage 3: accumulation
  

            accumulator_reg <= partial_sum[0]
                             + partial_sum[1]
                             + partial_sum[2]
                             + partial_sum[3];

            valid_stage3 <= valid_stage2;


       
            // Stage 4: scaling
     

            scaled_val <= (accumulator_reg + 24'sd64) >>> 7;

            valid_stage4 <= valid_stage3;


        
            // Stage 5: registered output
          

            sample_out <= scaled_val;

            valid_out <= valid_stage4;

        end

    end

endmodule