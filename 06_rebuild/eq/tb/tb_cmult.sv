`timescale 1ns / 1ps
//=====================================================================
// tb_cmult: self-checking random test of both cmult variants
//---------------------------------------------------------------------
// The expected answer is computed here with 64-bit integer maths, so it
// can't overflow. 1000 random sets plus the corner cases that break
// naive widths (most negative values, which have no positive twin).
//=====================================================================

module tb_cmult;

    logic signed [23:0] a_re_c, a_im_c;          // u_conj: AW = 24 (tap)
    logic signed [7:0]  b_re_c, b_im_c;
    logic signed [32:0] p_re_c, p_im_c;

    logic signed [17:0] a_re_p, a_im_p;          // u_plain: AW = 18 (g)
    logic signed [7:0]  b_re_p, b_im_p;
    logic signed [26:0] p_re_p, p_im_p;

    cmult #(.AW(24), .BW(8), .CONJ_A(1)) u_conj (
        .a_re(a_re_c), .a_im(a_im_c), .b_re(b_re_c), .b_im(b_im_c), .p_re(p_re_c), .p_im(p_im_c));
    cmult #(.AW(18), .BW(8), .CONJ_A(0)) u_plain (
        .a_re(a_re_p), .a_im(a_im_p), .b_re(b_re_p), .b_im(b_im_p), .p_re(p_re_p), .p_im(p_im_p));

    int errors = 0, checks = 0;

    task automatic check(input longint ar, ai, br, bi);
        longint er, ei;
        // conj(a) * b
        a_re_c = ar; a_im_c = ai; b_re_c = br; b_im_c = bi;
        // a * b (a narrowed to 18 bits for this DUT)
        a_re_p = ar >>> 6; a_im_p = ai >>> 6; b_re_p = br; b_im_p = bi;
        #1;
        er = ar * br + ai * bi;  ei = ar * bi - ai * br;
        if (p_re_c !== er || p_im_c !== ei) begin
            errors++;
            if (errors <= 5) $display("conj  a=(%0d,%0d) b=(%0d,%0d): got (%0d,%0d) exp (%0d,%0d)",
                                      ar, ai, br, bi, p_re_c, p_im_c, er, ei);
        end
        er = (ar >>> 6) * br - (ai >>> 6) * bi;  ei = (ar >>> 6) * bi + (ai >>> 6) * br;
        if (p_re_p !== er || p_im_p !== ei) begin
            errors++;
            if (errors <= 5) $display("plain a=(%0d,%0d) b=(%0d,%0d): got (%0d,%0d) exp (%0d,%0d)",
                                      ar >>> 6, ai >>> 6, br, bi, p_re_p, p_im_p, er, ei);
        end
        checks++;
    endtask

    initial begin
        // corner cases
        check(-(1 <<< 23), -(1 <<< 23), -128, -128);
        check((1 <<< 23) - 1, (1 <<< 23) - 1, 127, 127);
        check(-(1 <<< 23), (1 <<< 23) - 1, 127, -128);
        check(0, 0, -128, 127);
        check(4194304, 0, 5, -3);          // 1.0 tap times a sample
        // random
        repeat (1000)
            check($signed(24'($urandom)), $signed(24'($urandom)),
                  $signed(8'($urandom)),  $signed(8'($urandom)));
        $display("tb_cmult: %0d checks, %0d errors -> %s", checks, errors, errors ? "FAIL" : "PASS");
        $finish;
    end

endmodule
