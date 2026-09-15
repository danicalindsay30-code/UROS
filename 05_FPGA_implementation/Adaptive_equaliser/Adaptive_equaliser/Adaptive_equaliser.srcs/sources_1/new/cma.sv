`timescale 1ns / 1ps

module cma #(
    parameter NUM_TAPS = 17,parameter RADIUS
)(
    input logic clk,

    input logic signed [7:0] sample_x_real,
    input logic signed [7:0] sample_x_imag,

    input logic signed [7:0] sample_y_real,
    input logic signed [7:0] sample_y_imag,

    input logic signed [23:0] output_x_real,
    input logic signed [23:0] output_x_imag,

    input logic signed [23:0] output_y_real,
    input logic signed [23:0] output_y_imag
);

logic signed [47:0] magnitude_x;
logic signed [47:0] magnitude_y;

always_comb begin

    magnitude_x =
        (output_x_real * output_x_real) +
        (output_x_imag * output_x_imag);

    magnitude_y =
        (output_y_real * output_y_real) +
        (output_y_imag * output_y_imag);

end
logic signed [47:0] error_x;
logic signed [47:0] error_y;



always_comb begin

    error_x = RADIUS - magnitude_x;
    error_y = RADIUS - magnitude_y;

end
endmodule 
