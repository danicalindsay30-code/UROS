`timescale 1ns / 1ps


module top_module(input logic clk,
                  input logic rst,
                  output logic valid_out);
                  
  
       //flags - combinational 
       logic running, in_flush;
       
       assign running = (counter < 132);
       assign in_flush = (counter >= 116);
       
       //counter 
       logic [7:0]counter;
       always_ff @(posedge clk) 
          if (rst)begin
             counter <='0;   
          end 
          else if (counter == 132)begin 
             counter <= counter;
        
          end 
          else begin
             counter <= counter + 1'b1; 
          end 
          
          initial begin 
             $readmemh
          end
          
endmodule
