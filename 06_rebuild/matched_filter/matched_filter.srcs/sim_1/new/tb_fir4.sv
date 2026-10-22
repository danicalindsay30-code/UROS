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

//declare arrays 
//'{} an array assignment pattern that initialises each elemenent in order 

logic [5:0] impulse = 6'b100000;
logic [5:0] step = 6'b111111;
 
//generate stimuli
initial begin 
   tb_rst = 1;
   repeat (2)begin
   @(posedge tb_clk);
   end 
   for(int i = 0; i <6 ; i++) begin
      @(posedge tb_clk) begin
         tb_in =  
      end 
      
   end 
   
end 

endmodule
