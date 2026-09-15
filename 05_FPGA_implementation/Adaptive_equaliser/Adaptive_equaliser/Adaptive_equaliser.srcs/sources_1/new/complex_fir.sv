`timescale 1ns / 1ps

module complex_fir #(
    parameter NUM_TAPS = 17
)(
    input  logic                    clk,

    input  logic signed [7:0]       sample_real,
    input  logic signed [7:0]       sample_imag,

    output logic signed [23:0]      output_real,
    output logic signed [23:0]      output_imag
);


    // Complex shift registers
   

    logic signed [7:0] shift_real [0:NUM_TAPS-1];
    logic signed [7:0] shift_imag [0:NUM_TAPS-1];

    initial begin
        for (int i = 0; i < NUM_TAPS; i++) begin
            shift_real[i] = 0;
            shift_imag[i] = 0;
        end
    end


    // Complex tap coefficients

    logic signed [7:0] taps_real [0:NUM_TAPS-1];
    logic signed [7:0] taps_imag [0:NUM_TAPS-1];

    initial begin

        for (int i = 0; i < NUM_TAPS; i++) begin
            taps_real[i] = 0;
            taps_imag[i] = 0;
        end

        // Initial identity filter
        taps_real[NUM_TAPS/2] = 1;
        taps_imag[NUM_TAPS/2] = 0;

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


=
    // Complex multiplication results
    //
    // need w* × x because Python uses np.vdot().
    //
    // (x_real + jx_imag)(w_real - jw_imag)
    //
    // real = x_real*w_real + x_imag*w_imag
    // imag = x_imag*w_real - x_real*w_imag


    logic signed [15:0] mul_real [0:NUM_TAPS-1];
    logic signed [15:0] mul_imag [0:NUM_TAPS-1];



    // Accumulators


    logic signed [23:0] accumulator_real;
    logic signed [23:0] accumulator_imag;


  
    // Complex FIR calculation
  

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