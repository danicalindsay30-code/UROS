`timescale 1ns / 1ps

module fir_param#(parameter NUM_TAPS)
                  (input logic clk,
                   input logic rst,
                   input logic signed [7:0] in,
                   input logic signed [17:0] out);
       //local param
       localparam logic signed  [6:0] taps [0:16] = '{0,1,-2,2,5,-12,-8,55,
                                                      99,-8,-12,5,2,-2,1,0};
       //instantiate register 
       logic signed [13:0] register [NUM_TAPS:0] ;           
       //shift register
       always_ff @(posedge clk) begin
          register[0] <= in ;
          for(int i = 0; i< NUM_TAPS; i++) begin 
          end 
          
       end 
       
                   
endmodule
