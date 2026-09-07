`timescale 1ns / 1ps

module dp_matched_filter #(
    parameter NUM_TAPS = 17,
    parameter NUM_BITS = 100
)(
    input logic clk,

    // Horizontal polarization
    input logic signed [7:0] Ix,
    input logic signed [7:0] Qx,

    // Vertical polarization
    input logic signed [7:0] Iy,
    input logic signed [7:0] Qy,

    // Outputs
    output logic signed [17:0] Ix_out,
    output logic signed [17:0] Qx_out,
    output logic signed [17:0] Iy_out,
    output logic signed [17:0] Qy_out
);

    matched_filter #(
        .NUM_TAPS(NUM_TAPS)
    ) fir_Ix (
        .clk(clk),
        .sample_in(Ix),
        .sample_out(Ix_out)
    );

    matched_filter #(
        .NUM_TAPS(NUM_TAPS)
    ) fir_Qx (
        .clk(clk),
        .sample_in(Qx),
        .sample_out(Qx_out)
    );

    matched_filter #(
        .NUM_TAPS(NUM_TAPS)
    ) fir_Iy (
        .clk(clk),
        .sample_in(Iy),
        .sample_out(Iy_out)
    );

    matched_filter #(
        .NUM_TAPS(NUM_TAPS)
    ) fir_Qy (
        .clk(clk),
        .sample_in(Qy),
        .sample_out(Qy_out)
    );

endmodule