`timescale 1ns / 1ps

module fir4( input logic clk , rst,
             input logic signed  [7:0] in ,
             output logic signed  [11:0] out );
             
      logic signed [7:0] register [0:3]; //unpacked array 
      logic signed [10:0] products [0:3] ;
      //shift register 
      always_ff @(posedge clk) begin 
         register[0] <= in;
         for(int i = 1; i < 4 ; i++) begin 
           register[i] <= register[i-1];
         end  
         out <= sum; 
      end 
     
     logic [11:0] sum; 
     always_comb begin
        //parallel multiplication 
        for(int i = 0; i < 4; i++) begin
           products[i] = register[i] * (i+1); 
        end 
        //adder tree: partial sums 
        sum = (products[0] + products[1]) + (products[2]+ products[3]);
        
        
     end 
endmodule
