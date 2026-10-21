`timescale 1ns / 1ps


module tb_counter;

logic clk, rst, ena;
logic [7:0] count;

counter dut(.rst(rst), .clk(clk), .ena(ena), .count(count));


//generate clock 

initial begin 
clk = 0;
forever #10 clk = ~clk;
end

//generate stimuli 
initial begin
rst = 1 ; ena = 0; count = 0;
repeat (3)begin
   @(posedge clk);
end

repeat (20) begin 
@(negedge clk) ena = 1; rst = 0;
end


$monitor("Time %0t: count = %0db",$time,count )

 

end 



endmodule
