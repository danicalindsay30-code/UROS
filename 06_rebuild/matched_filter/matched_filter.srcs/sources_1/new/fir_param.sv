
`timescale 1ns / 1ps

module fir_param #(
    parameter int NUM_TAPS = 17
)(
    input  logic clk,
    input  logic rst,
    input  logic signed [7:0] in,
    output logic signed [16:0] out
);

    // Fixed 17-tap, signed 8-bit coefficient array.
    // NUM_TAPS must be 17 for this coefficient set.
    localparam logic signed [7:0] taps [0:NUM_TAPS-1] = '{
        0, 1, -2, 2, 5, -12, -8, 55, 99,
        55, -8, -12, 5, 2, -2, 1, 0
    };

    // Delay line: NUM_TAPS signed input samples
    logic signed [7:0] delay_line [0:NUM_TAPS-1];

    // Full-width signed products: 8-bit x 8-bit = 16 bits
    logic signed [15:0] products [0:NUM_TAPS-1];

    // Raw accumulator: 17 signed bits
    logic signed [16:0] accum;

    // Shift register with synchronous, active-high reset
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM_TAPS; i++) begin
                delay_line[i] <= '0;
            end

            out <= '0;
        end
        else begin
            delay_line[0] <= in;

            for (int i = 1; i < NUM_TAPS; i++) begin
                delay_line[i] <= delay_line[i-1];
            end

            // Registered output: raw sum, no scaling
            out <= accum;
        end
    end

    // Combinational multiplication and accumulation
    always_comb begin
        accum = '0;

        for (int i = 0; i < NUM_TAPS; i++) begin
            products[i] = delay_line[i] * taps[i];
            accum = accum + products[i];
        end
    end

endmodule
