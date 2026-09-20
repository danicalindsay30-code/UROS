`timescale 1ns / 1ps
//=====================================================================
// dp_matched_filter_pipeline
//---------------------------------------------------------------------
// Four identical pipelined RRC matched filters, one per real stream:
//
//   Ix = X polarisation, in-phase
//   Qx = X polarisation, quadrature
//   Iy = Y polarisation, in-phase
//   Qy = Y polarisation, quadrature
//
// All four instances share clk, rst and valid_in, so their pipelines
// advance in lockstep and their outputs appear on the same cycle.
// That is why a single valid_out is enough: it is taken from the Ix
// instance, and the other three are tied off.
//=====================================================================

module dp_matched_filter_pipeline #(
    parameter int NUM_TAPS = 17
)(
    input  logic               clk,
    input  logic               rst,
    input  logic               valid_in,

    input  logic signed [7:0]  Ix,
    input  logic signed [7:0]  Qx,
    input  logic signed [7:0]  Iy,
    input  logic signed [7:0]  Qy,

    output logic               valid_out,
    output logic signed [17:0] Ix_out,
    output logic signed [17:0] Qx_out,
    output logic signed [17:0] Iy_out,
    output logic signed [17:0] Qy_out
);

    // One valid per instance. They are identical by construction;
    // valid_out is driven from channel 0 and the rest are unused.
    logic v_Ix, v_Qx, v_Iy, v_Qy;

    matched_filter_pipeline #(.NUM_TAPS(NUM_TAPS)) fir_Ix (
        .clk        (clk),
        .rst        (rst),
        .valid_in   (valid_in),
        .sample_in  (Ix),
        .valid_out  (v_Ix),
        .sample_out (Ix_out)
    );

    matched_filter_pipeline #(.NUM_TAPS(NUM_TAPS)) fir_Qx (
        .clk        (clk),
        .rst        (rst),
        .valid_in   (valid_in),
        .sample_in  (Qx),
        .valid_out  (v_Qx),
        .sample_out (Qx_out)
    );

    matched_filter_pipeline #(.NUM_TAPS(NUM_TAPS)) fir_Iy (
        .clk        (clk),
        .rst        (rst),
        .valid_in   (valid_in),
        .sample_in  (Iy),
        .valid_out  (v_Iy),
        .sample_out (Iy_out)
    );

    matched_filter_pipeline #(.NUM_TAPS(NUM_TAPS)) fir_Qy (
        .clk        (clk),
        .rst        (rst),
        .valid_in   (valid_in),
        .sample_in  (Qy),
        .valid_out  (v_Qy),
        .sample_out (Qy_out)
    );

    assign valid_out = v_Ix;

    // Simulation-only check that the four channels really do stay in
    // step. If this ever fires, one instance was built differently.
    // synthesis translate_off
    always_ff @(posedge clk) begin
        if (!rst && (v_Ix !== v_Qx || v_Ix !== v_Iy || v_Ix !== v_Qy))
            $error("channel valids diverged: %b %b %b %b",
                   v_Ix, v_Qx, v_Iy, v_Qy);
    end
    // synthesis translate_on

endmodule