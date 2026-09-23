`timescale 1ns / 1ps

//top module- hardware test harness for matched filter 
module top_module(input logic clk,
                  input logic rst,
                  output logic valid_out,
                  output logic signed [17:0] Ix_out,
                  output logic signed [17:0] Qx_out,
                  output logic signed [17:0] Iy_out,
                  output logic signed [17:0] Qy_out
                  );
                  
       localparam int NUM_SAMPLES = 116;
       localparam int NUM_FLUSH   = 16;      // NUM_TAPS - 1
       localparam int LAST        = NUM_SAMPLES + NUM_FLUSH;   // 132
        
       logic [7:0]  counter;
 
       logic        running, in_flush;        // combinational flags
       logic        running_d, in_flush_d;    // same flags, delayed 1 clock
 
       logic [31:0] rom [0:127];              // the memory: 128 x 32-bit
       logic [31:0] rom_q;                    // one word, just read
 
       logic signed [7:0] Ix_s, Qx_s, Iy_s, Qy_s;   // unpacked samples
       logic signed [7:0] Ix_m, Qx_m, Iy_m, Qy_m;   // after the flush mux 
 
          
       initial begin
          $readmemh("MF_input_samples.mem", rom);
       end
       
       //counter
       always_ff @(posedge clk) begin
           if (rst)
              counter <= '0;
           else if (counter != LAST)
               counter <= counter + 1'b1;
        // at LAST: hold
       end
        //flags 
        assign running  = (counter <  LAST);
        assign in_flush = (counter >= NUM_SAMPLES);
        
       //read rom 
        always_ff @(posedge clk) begin
           rom_q <= rom[counter[6:0]];
        end
        
        //delay flags 
        always_ff @(posedge clk )begin 
           if(rst) begin
              running_d <= 1'b0;
              in_flush_d <= 1'b0;
      
           end else begin
              running_d <= running;
              in_flush_d <= in_flush;
           
           end
        
        end
   always_ff @(posedge clk) begin
    if (rst)
        rom_q <= 32'd0;
    else
        rom_q <= rom[counter[6:0]];
end
    assign {Qy_s, Iy_s, Qx_s, Ix_s} = rom_q;
 
   
    assign Ix_m = in_flush_d ? 8'sd0 : Ix_s;
    assign Qx_m = in_flush_d ? 8'sd0 : Qx_s;
    assign Iy_m = in_flush_d ? 8'sd0 : Iy_s;
    assign Qy_m = in_flush_d ? 8'sd0 : Qy_s;

    dp_matched_filter_pipeline #(
        .NUM_TAPS(17)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .valid_in  (running_d),
        .Ix        (Ix_m),
        .Qx        (Qx_m),
        .Iy        (Iy_m),
        .Qy        (Qy_m),
        .valid_out (valid_out),
        .Ix_out    (Ix_out),
        .Qx_out    (Qx_out),
        .Iy_out    (Iy_out),
        .Qy_out    (Qy_out)
    );
 
endmodule
 
       
