`timescale 1ns / 1ps


module tb_counter;

logic clk, rst, ena;
logic [7:0] counter;

counter dut(.rst(rst), .clk(clk), .ena(ena), . counter(counter));


//generate clock 

initial begin 
clk = 0;
forever #10 clk = ~clk;
end

//generate stimuli 
initial begin
rst = 0 ; ena = 0; counter = '0;
repeat (3)begin
#20 rst = 1; 
end

repeat (20) begin 
#20 ena = 1;
end

initial begin 
$monitor("Time %ot: count = %/b",$time,count )
end 
 

end 



endmodule
