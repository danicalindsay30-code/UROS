`timescale 1ns / 1ps

module matched_filter_tb;

localparam NUM_TAPS = 17;

logic clk;
logic signed [7:0] sample_in;
logic signed [17:0] sample_out;


// Instantiate DUT
matched_filter #(
    .NUM_TAPS(NUM_TAPS)
) dut (
    .clk(clk),
    .sample_in(sample_in),
    .sample_out(sample_out)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

logic signed [7:0] samples [0:9];

integer file;
integer status;

//read sample in values 
initial begin 
    file = $fopen(
"C:/Users/zceedll/UROS project/FPGA_implentation/UROS_cma/input_samples.txt",
"r");

    if(file == 0) begin
        $display("ERROR: Could not open input_samples.txt");
        $finish;
    end

    for(int i=0; i<(NUM_TAPS*1.5); i++) begin
        status = $fscanf(file,"%d\n",samples[i]);
    end

    $fclose(file);

end

initial begin
    sample_in = 0;

    repeat(2) @(posedge clk);

    for(int i=0; i< (NUM_TAPS*1.5); i++) begin

        sample_in = samples[i];

        @(posedge clk);
    end

    $finish;

end

always @(posedge clk)
    $display("time=%0t in=%0d out=%0d",
              $time, sample_in, sample_out);





endmodule
