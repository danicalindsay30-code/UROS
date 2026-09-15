`timescale 1ns / 1ps

module cma #(
    parameter NUM_TAPS = 21,
    parameter signed [47:0] RADIUS = 48'sd1
)(
    input logic clk,

    // =========================================================
    // Input samples
    // =========================================================

    input logic signed [7:0] sample_x_real,
    input logic signed [7:0] sample_x_imag,

    input logic signed [7:0] sample_y_real,
    input logic signed [7:0] sample_y_imag,


    // =========================================================
    // Equaliser outputs
    //
    // These are the outputs produced by the 2x2 butterfly
    // equaliser.
    // =========================================================

    input logic signed [28:0] output_x_real,
    input logic signed [28:0] output_x_imag,

    input logic signed [28:0] output_y_real,
    input logic signed [28:0] output_y_imag

);


    // =========================================================
    // Squared magnitude
    //
    // CMA uses |y|² rather than |y|.
    //
    // |y|² = real² + imag²
    //
    // We do NOT need a square root because CMA compares
    // the squared magnitude directly with R.
    // =========================================================

    logic signed [57:0] magnitude_squared_x;
    logic signed [57:0] magnitude_squared_y;


    always_comb begin

        magnitude_squared_x =
            (output_x_real * output_x_real) +
            (output_x_imag * output_x_imag);

        magnitude_squared_y =
            (output_y_real * output_y_real) +
            (output_y_imag * output_y_imag);

    end


    // =========================================================
    // CMA error
    //
    // e_x = R - |y_x|²
    // e_y = R - |y_y|²
    //
    // The error tells the adaptive equaliser whether the
    // output magnitude is too large or too small.
    // =========================================================

    logic signed [57:0] error_x;
    logic signed [57:0] error_y;


    always_comb begin

        error_x = RADIUS - magnitude_squared_x;
        error_y = RADIUS - magnitude_squared_y;

    end


endmodule