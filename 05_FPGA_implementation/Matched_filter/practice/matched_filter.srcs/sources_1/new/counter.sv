`timescale 1ns / 1ps

module counter(input logic rst,
               input logic ena,
               input logic clk,
               output logic [7:0] count );
           
       always_ff @(posedge clk) begin
          if (rst) begin 
             count <= 8'b0;      
          end 
          else if (ena)begin 
             count <= count + 1'b1 ; 
          end 
       end 
endmodule
