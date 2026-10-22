`timescale 1ns / 1ps

module fir_param#(parameter int NUM_TAPS = 17)
                  (input logic clk,
                   input logic rst,
                   input logic signed [7:0] in,
                   input logic signed [17:0] out);
       //local param
       localparam logic signed  [6:0] taps [0:16] = '{0,1,-2,2,5,-12,-8,55,
                                                      99,55,-8,-12,5,2,-2,1,0};
         logic signed [17:0] accum ;                                              
       //instantiate register 
       logic signed [13:0] register [NUM_TAPS:0] ;           
       //Sequential: shift register
       always_ff @(posedge clk) begin
          register[0] <= in ;
          for(int i = 1; i< NUM_TAPS; i++) begin 
             register[i] <= register[i-1];
          end 
 
       end
       
      
       // Combinational: multiplication and accumulator  
       always_comb begin
          for(int i =0 ; i< NUM_TAPS; i++) begin
             register[i] = register[i] * NUM_TAPS[i]; 
          end 
          for(int i = 0; i <NUM_TAPS; i++) begin 
          accum = accum + register[i];
          end
          
       end  
       
                   
endmodule
