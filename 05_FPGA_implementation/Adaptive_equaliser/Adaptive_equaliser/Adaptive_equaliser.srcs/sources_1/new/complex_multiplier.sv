`timescale 1ns / 1ps
module complex_multiplier(input logic signed [7:0] a_real,a_imag,b_real,b_imag,
                          output logic signed [16:0] product_real, 
                          output logic signed [16:0] product_imag);
//completing the mathematical dot product 

//internal wires
        logic signed [15:0]ac;
        logic signed [15:0]bd;
        logic signed [15:0]ad;
        logic signed [15:0]bc;
        
        
        always_comb begin 
                   ac = a_real * b_real;
                   bd = a_imag * b_imag;
                   ad = a_real * b_imag;
                   bc = a_imag * b_real;
                   
                   product_real = ac - bd;
                   product_imag = ad+ bc;
        end

endmodule
