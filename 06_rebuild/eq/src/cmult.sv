`timescale 1ns / 1ps
//=====================================================================
// cmult: complex multiplier, combinational                      YOU WRITE
//---------------------------------------------------------------------
// p = a * b        when CONJ_A = 0      (used by the tap update: g * x)
// p = conj(a) * b  when CONJ_A = 1      (used by the FIR: conj(w) * x)
//
// Maths (write these out on paper first):
//   a * b       : re = ar*br - ai*bi      im = ar*bi + ai*br
//   conj(a) * b : re = ar*br + ai*bi      im = ar*bi - ai*br
//   (conj flips the sign of ai, so every ai term changes sign)
//
// Widths: a signed AW-bit times a signed BW-bit is AW+BW bits.
// Adding two of them can carry one more bit, so P_OUT = AW + BW + 1.
//
// Used as:   FIR     cmult #(.AW(24), .BW(8), .CONJ_A(1))  -> 33-bit parts
//            update  cmult #(.AW(18), .BW(8), .CONJ_A(0))  -> 27-bit parts
//
// Hardware: 4 real multiplies = 4 DSP48E2 (24x8 and 18x8 each fit one
// 27x18 multiplier). The 3-multiply trick exists; mention it, don't
// build it today.
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

    // TODO 1. Declare the four real products, each signed [AW+BW-1:0]:
    //         ar_br, ai_bi, ar_bi, ai_br.
    //         TIP: both operands are signed ports, so a plain * is signed.
    //         If either were unsigned the whole product would go unsigned
    //         (your A1.3 lab). Never mix.
    logic signed [AW+BW-1: 0 ] ar_br, ai_bi, ar_bi, ai_br;

    // TODO 2. In an always_comb, compute the four products.
    always_comb begin
    if (CONJ_A) begin
       ar_br = a_re * b_re;
       ai_bi = a_im * b_im;
       ar_bi = a_re * b_im;
       ai_br = a_im * b_re;  
    end
    else begin
       ar_br = a_re * b_re;
       ai_bi = -a_im * b_im;
       ar_bi = a_re * b_im;
       ai_br = -a_im * b_re;
        
    end  
    end 

    // TODO 3. Combine them. CONJ_A is a parameter, so use
    //             if (CONJ_A) ... else ...
    //         inside always_comb (or a generate if). Synthesis keeps only
    //         one branch because CONJ_A is fixed at compile time.
    //         TIP: when you add two AW+BW-bit signals into a PW-bit
    //         result, SystemVerilog sign-extends both to PW first, because
    //         the left-hand side sets the width. Check: is that true if
    //         you write  p_re = ar_br - ai_bi;  ?  (yes: all signed)

endmodule
