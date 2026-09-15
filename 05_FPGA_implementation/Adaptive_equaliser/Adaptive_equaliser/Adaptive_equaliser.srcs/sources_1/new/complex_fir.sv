`timescale 1ns / 1ps

module complex_fir #(
    parameter NUM_TAPS = 17
)(
    input logic                    clk,

    input logic signed [7:0]       sample_real,
    input logic signed [7:0]       sample_imag,

    output logic signed [23:0]     output_real,
    output logic signed [23:0]     output_imag
);


    // =========================================================
    // Complex shift registers
    // Samples are represented using 8-bit signed integers.
    // We store the real and imaginary components separately
    // because SystemVerilog does not have a native complex type.
    // =========================================================

    logic signed [7:0] shift_real [0:NUM_TAPS-1];
    logic signed [7:0] shift_imag [0:NUM_TAPS-1];

    initial begin
        for (int i = 0; i < NUM_TAPS; i++) begin
            shift_real[i] = 0;
            shift_imag[i] = 0;
        end
    end


    // =========================================================
    // Complex tap coefficients
    //
    // Coefficients use 16-bit Q4.12 fixed-point format.
    //
    // 16 bits total:
    // 4 bits for signed/integer range
    // 12 bits for fractional precision
    //
    // The coefficients are adaptive and will be updated by CMA.
    // =========================================================

    logic signed [15:0] taps_real [0:NUM_TAPS-1];
    logic signed [15:0] taps_imag [0:NUM_TAPS-1];

    initial begin

        for (int i = 0; i < NUM_TAPS; i++) begin
            taps_real[i] = 0;
            taps_imag[i] = 0;
        end

        // Initial identity filter
        //
        // 1.0 in Q4.12 = 1 * 2^12 = 4096
        //
        // This means that initially:
        // X -> X
        // Y -> Y
        //
        // CMA will adapt these coefficients from this
        // initial identity state.

        taps_real[NUM_TAPS/2] = 16'sd4096;
        taps_imag[NUM_TAPS/2] = 16'sd0;

    end


    // =========================================================
    // Shift incoming complex samples
    // =========================================================

    always_ff @(posedge clk) begin

        for (int i = NUM_TAPS-1; i > 0; i--) begin
            shift_real[i] <= shift_real[i-1];
            shift_imag[i] <= shift_imag[i-1];
        end

        shift_real[0] <= sample_real;
        shift_imag[0] <= sample_imag;

    end


    // =========================================================
    // Complex multiplication results
    //
    // We need w* × x because Python uses np.vdot().
    //
    // (x_real + jx_imag)(w_real - jw_imag)
    //
    // real = x_real*w_real + x_imag*w_imag
    // imag = x_imag*w_real - x_real*w_imag
    //
    // Each sample is 8-bit and each coefficient is 16-bit,
    // therefore each multiplication produces a 24-bit result.
    // =========================================================

    logic signed [23:0] mul_real [0:NUM_TAPS-1];
    logic signed [23:0] mul_imag [0:NUM_TAPS-1];


    // =========================================================
    // Accumulators
    //
    // The FIR adds NUM_TAPS complex products together.
    // The accumulator therefore needs to be wider than
    // an individual multiplication result to prevent overflow.
    // =========================================================

    logic signed [28:0] accumulator_real;
    logic signed [28:0] accumulator_imag;


    // =========================================================
    // Complex FIR calculation
    // =========================================================

    always_comb begin

        accumulator_real = 0;
        accumulator_imag = 0;

        for (int i = 0; i < NUM_TAPS; i++) begin

            // w* × x

            mul_real[i] =
                (shift_real[i] * taps_real[i]) +
                (shift_imag[i] * taps_imag[i]);

            mul_imag[i] =
                (shift_imag[i] * taps_real[i]) -
                (shift_real[i] * taps_imag[i]);

            accumulator_real =
                accumulator_real + mul_real[i];

            accumulator_imag =
                accumulator_imag + mul_imag[i];

        end

        output_real = accumulator_real;
        output_imag = accumulator_imag;

    end

endmodule