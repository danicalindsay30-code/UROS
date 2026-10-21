`timescale 1ns / 1ps

module tb_shift_reg ; 


localparam N_TB = 5;
localparam W_TB = 8;
logic clk_tb, rst_tb;
logic signed [W_TB-1:0] data_tb;
logic signed [W_TB-1:0] register_tb [0:N_TB-1];

shift_reg #(
    .N(N_TB),
    .W(W_TB)
) dut (
    .clk(clk_tb),
    .rst(rst_tb),
    .data(data_tb),
    .register(register_tb)
);

//generate clock stimuli 
initial begin
clk_tb = 0;
forever clk_tb = ~clk_tb; 
end 

// generate input stimuli 
initial begin 
   rst_tb = 1; data_tb = 0;
   
   @(negedge clk_tb)
   rst_tb = 0;
   
   for(int i = 1; i < 6; i ++) begin 
         data_tb = i;
         @(negedge clk_tb);      
   end 
end 

initial begin 
$monitor("time = %0t: register = %0sd", $time, register_tb );
end 

$finish
endmodule
