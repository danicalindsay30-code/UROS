`timescale 1ns / 1ps
//=====================================================================
// cmult: complex multiplier, combinational
//---------------------------------------------------------------------
// p = conj(a) * b   when CONJ_A = 1   (FIR:    conj(w) * x)
// p = a * b         when CONJ_A = 0   (update: g * x)
//
//   conj(a) * b : re = ar*br + ai*bi      im = ar*bi - ai*br
//   a * b       : re = ar*br - ai*bi      im = ar*bi + ai*br
//
// The two only differ in the sign of every a_im term. So the sign is
// folded into the two products that use a_im, and one combine step
//     re = ar_br + ai_bi        im = ar_bi - ai_br
// serves both modes. CONJ_A is a parameter, so synthesis keeps only one
// branch: no mux in hardware.
//
// Widths: AW-bit x BW-bit signed = AW+BW bits. Adding two of them can
// carry one more bit: PW = AW+BW+1. Four real multiplies = 4 DSP48E2.
//=====================================================================

module cmult #(
    parameter int AW     = 24,
    parameter int BW     = 8,
    parameter bit CONJ_A = 1,
    parameter int PW     = AW + BW + 1
)(
    input  logic signed [AW-1:0] a_re, a_im,
    input  logic signed [BW-1:0] b_re, b_im,
    output logic signed [PW-1:0] p_re, p_im
);

    logic signed [AW+BW-1:0] ar_br, ai_bi, ar_bi, ai_br;

    always_comb begin
        ar_br = a_re * b_re;
        ar_bi = a_re * b_im;
        if (CONJ_A) begin
            ai_bi = a_im * b_im;
            ai_br = a_im * b_re;
        end else begin
            ai_bi = -(a_im * b_im);      // a_im sign flipped for a plain a*b
            ai_br = -(a_im * b_re);
        end
        p_re = ar_br + ai_bi;
        p_im = ar_bi - ai_br;
    end

endmodule
