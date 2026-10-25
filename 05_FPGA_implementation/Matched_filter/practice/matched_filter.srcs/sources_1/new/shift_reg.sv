`timescale 1ns / 1ps


module shift_reg#(parameter N = 4, 
                  parameter W = 8)(
                  input logic clk,
                  input logic rst,
                  input logic signed [W-1:0] data,
                  output logic signed [W-1:0] register [0: N-1]);
                  
                  always_ff @(posedge clk) begin 
                     if (rst) begin 
                       for (int i = 0; i < N; i ++) begin
                          register[i] <= '0; 
                       end 
                       
                     end
                     else begin
                        register[0] <= data;
                        for (int i = 1; i < N ; i ++ ) begin
                           register[i] <= register[i-1] ;
                        end 
                     end 
                  end 
endmodule
