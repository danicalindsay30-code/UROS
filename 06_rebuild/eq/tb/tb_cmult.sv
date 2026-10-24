`timescale 1ns / 1ps
//=====================================================================
// tb_cmult: self-checking random test, no vector file          YOU WRITE
//---------------------------------------------------------------------
// The expected answer is computed HERE, in the testbench, with plain
// integer maths. That works for a block this small. Bigger blocks use
// Python vectors instead.
//
// Test both variants: instantiate TWO DUTs,
//     u_conj  : cmult #(.AW(24), .BW(8), .CONJ_A(1))   (FIR use)
//     u_plain : cmult #(.AW(18), .BW(8), .CONJ_A(0))   (update use)
//
// PASS when: 0 errors over 1000 random sets AND the corner cases.
//=====================================================================


module tb_cmult;

    // Signals for u_conj: AW=24, BW=8
    logic signed [23:0] a_re_conj, a_im_conj;
    logic signed [7:0]  b_re_conj, b_im_conj;
    logic signed [32:0] p_re_conj, p_im_conj;

    // Signals for u_plain: AW=18, BW=8
    logic signed [17:0] a_re_plain, a_im_plain;
    logic signed [7:0]  b_re_plain, b_im_plain;
    logic signed [26:0] p_re_plain, p_im_plain;

    // Conjugate complex multiplier
    cmult #(
        .AW(24),
        .BW(8),
        .CONJ_A(1)
    ) u_conj (
        .a_re(a_re_conj),
        .a_im(a_im_conj),
        .b_re(b_re_conj),
        .b_im(b_im_conj),
        .p_re(p_re_conj),
        .p_im(p_im_conj)
    );

    // Ordinary complex multiplier
    cmult #(
        .AW(18),
        .BW(8),
        .CONJ_A(0)
    ) u_plain (
        .a_re(a_re_plain),
        .a_im(a_im_plain),
        .b_re(b_re_plain),
        .b_im(b_im_plain),
        .p_re(p_re_plain),
        .p_im(p_im_plain)
    );

endmodule
    

    // TODO 2. Instantiate u_conj and u_plain.

    // TODO 3. In an initial block, a check task:
    //
    //   task automatic check_conj(input longint ar, ai, br, bi);
    //       longint er, ei;
    //       {drive the DUT inputs}; #1;               // let always_comb settle
    //       er = ar*br + ai*bi;  ei = ar*bi - ai*br;  // conj(a)*b in 64-bit
    //       if (u_conj.p_re !== er || ...) begin errors++; $display(...); end
    //   endtask
    //
    //   TIP: longint is 64-bit signed, so this reference maths can't
    //   overflow, and comparing a 33-bit signed port with a longint
    //   sign-extends the port. That makes the compare correct.
    //
    // TODO 4. Random sets:  $urandom returns 32 unsigned bits. For a signed
    //   24-bit value:  ar = $signed(24'($urandom));   (8-bit: 8'(...))
    //
    // TODO 5. Corner cases, the ones that break naive widths:
    //   a = -2^23 (most negative 24-bit), b = -128: does the product fit?
    //   a = 2^23-1, b = 127;  a = 0;  b = 0;  and mixed signs.
    //
    // TODO 6. $display("tb_cmult: %0d errors -> %s", errors, errors ? "FAIL" : "PASS"); $finish;

endmodule
