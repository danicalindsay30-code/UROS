`timescale 1ns / 1ps
//=====================================================================
// cma_update: new taps for all four filters, combinational
//---------------------------------------------------------------------
// Golden model (adaptive_algorithim.cma), with g = mu*e*conj(y):
//     w_xx += g_x * x_window        w_yx += g_x * y_window
//     w_xy += g_y * x_window        w_yy += g_y * y_window
//
// Filter name = INPUT, OUTPUT: the OUTPUT picks g, the INPUT picks the window.
// Per tap:  dw  = (g * x[i] + 2^5) >>> 6     frac 28 -> 22 (tap LSB)
//           new = sat24(w + dw)
// 4 filters x N taps x 4 real multiplies = 80 DSPs for N = 5.
//=====================================================================

import eq_pkg::*;

module cma_update #(
    parameter int N = 5
)(
    input  logic signed [G_W-1:0] gx_re, gx_im, gy_re, gy_im,
    input  logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1],
    input  logic signed [X_W-1:0] yr [0:N-1], yi [0:N-1],
    input  logic signed [W_W-1:0] wr     [0:3][0:N-1],
    input  logic signed [W_W-1:0] wi     [0:3][0:N-1],
    output logic signed [W_W-1:0] wr_new [0:3][0:N-1],
    output logic signed [W_W-1:0] wi_new [0:3][0:N-1]
);

    localparam longint W_MAX = (64'sd1 <<< (W_W - 1)) - 1;
    localparam longint W_MIN = -(64'sd1 <<< (W_W - 1));

    // round the product to the tap LSB, add, saturate
    function automatic logic signed [W_W-1:0] upd(input logic signed [W_W-1:0] w,
                                                  input logic signed [DW_W-1:0] p);
        logic signed [DW_W-1:0] dw;
        logic signed [W_W:0]    s;            // one bit wider: catch the overflow
        dw = (p + (1 <<< (DW_SHIFT - 1))) >>> DW_SHIFT;
        s  = w + dw;
        if      (s > W_MAX) return W_W'(W_MAX);
        else if (s < W_MIN) return W_W'(W_MIN);
        else                return s[W_W-1:0];
    endfunction

    genvar f, i;
    generate
        for (f = 0; f < 4; f++) begin : g_filt
            // constant per filter: which g (output) and which window (input)
            localparam bit OUT_X = (f == XX) || (f == YX);
            localparam bit IN_X  = (f == XX) || (f == XY);

            for (i = 0; i < N; i++) begin : g_tap
                logic signed [DW_W-1:0] pr, pi;
                cmult #(.AW(G_W), .BW(X_W), .CONJ_A(0)) u_mul (
                    .a_re(OUT_X ? gx_re : gy_re), .a_im(OUT_X ? gx_im : gy_im),
                    .b_re(IN_X  ? xr[i] : yr[i]), .b_im(IN_X  ? xi[i] : yi[i]),
                    .p_re(pr), .p_im(pi)
                );
                assign wr_new[f][i] = upd(wr[f][i], pr);
                assign wi_new[f][i] = upd(wi[f][i], pi);
            end
        end
    endgenerate

endmodule
