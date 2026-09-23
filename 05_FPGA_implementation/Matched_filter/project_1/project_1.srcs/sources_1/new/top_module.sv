`timescale 1ns / 1ps


module top_module(input logic clk,
                  input logic rst,
                  output logic valid_out);
                  
  
       //flags - combinational 
       logic running, in_flush;
       //flags delayed by one clock 
       logic running_d, in_flush_d;
       
       assign running = (counter < 132);
       assign in_flush = (counter >= 116);
       
       //counter 
       logic [7:0]counter;
       always_ff @(posedge clk) 
          if (rst)begin
             counter <='0; 
             running_d <= '0;
             in_flush_d <= '0;  
          end 
          else if (counter == 132)begin 
             counter <= counter;
        
          end 
          else begin
             counter <= counter + 1'b1; 
             
           //copying the entry of rom
           rom_q <= rom[counter[6:0]];
          end 
          
          //load the input samples 
          logic [31:0] rom [0:127];//memory for all 128 samples
          logic [31:0] rom_q ;//one register holding the word just read 
          initial begin 
             $readmemh("MF_input_samples.mem",rom);
          end
          
endmodule
