`timescale 1ns / 1ps

module fir4( input logic clk , rst,
             input logic signed  [7:0] in ,
             output logic signed  [11:0] out );
             
      logic signed [7:0] register [0:3]; //unpacked array 
      logic signed [10:0] products [0:3] ;
      //shift register 
      always_ff @(posedge clk) begin
    if (rst) begin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
        // Clear every element of the shift register
        for (int i = 0; i < 4; i++) begin
            register[i] <= '0;
        end

        // Clear the registered output
        out <= '0;
    end
    else begin
        // Your existing shift-register updates go here

        // Your registered output update goes here
        out <= sum;
    end
end
     
     logic signed[11:0] sum; 
     always_comb begin
        //parallel multiplication 
        for(int i = 0; i < 4; i++) begin
           products[i] = register[i] * (i+1); 
        end 
        //adder tree: partial sums 
        sum = (products[0] + products[1]) + (products[2]+ products[3]);
        
        
     end 
endmodule
