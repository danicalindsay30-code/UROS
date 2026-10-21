`timescale 1ns / 1ps

module tb_fir4;

logic tb_clk, tb_rst;
logic [7:0] tb_in;
logic [11:0] tb_out; 

fir4 dut(.clk(tb_clk), .rst(tb_rst), .in(tb_in), .out(tb_out));

initial begin
tb_clk = 0;
forever tb_clk = ~tb_clk; 
end

//generate stimuli
initial begin 
end 

endmodule
