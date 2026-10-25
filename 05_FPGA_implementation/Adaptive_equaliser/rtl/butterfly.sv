`timescale 1ns / 1ps
//=====================================================================
// butterfly: four complex FIRs, two complex adders, round + saturate
//---------------------------------------------------------------------
// Book 5.25 / 5.26 in your Python names (filter = INPUT, OUTPUT):
//     y_x = FIR(w_xx on x window) + FIR(w_yx on y window)
//     y_y = FIR(w_xy on x window) + FIR(w_yy on y window)
//
// The exact sum has 27 fractional bits; y keeps 13 (Q3.13):
//     y = saturate_16( (sum + 2^13) >>> 14 )      round half up
// Outputs are valid one clock after the inputs (product registers in
// complex_fir). Saturate, never wrap: a wrapped y flips sign and pushes every tap
// the wrong way.
//=====================================================================

import eq_pkg::*;

module butterfly #(
    parameter int N = 5
)(
    input  logic                  clk,           // for the product registers in complex_fir
    input  logic signed [X_W-1:0] xr [0:N-1], xi [0:N-1],
    input  logic signed [X_W-1:0] yr [0:N-1], yi [0:N-1],
    input  logic signed [W_W-1:0] wr [0:3][0:N-1],
    input  logic signed [W_W-1:0] wi [0:3][0:N-1],
    output logic signed [Y_W-1:0] yx_re, yx_im,
    output logic signed [Y_W-1:0] yy_re, yy_im
);

    localparam int SW = P_W + 1 + $clog2(N);   // one FIR sum
    localparam int AW = SW + 1;                // two FIR sums added

    localparam logic signed [AW-1:0] HALF  = AW'(1) <<< (Y_SHIFT - 1);
    localparam longint               Y_MAX = (64'sd1 <<< (Y_W - 1)) - 1;
    localparam longint               Y_MIN = -(64'sd1 <<< (Y_W - 1));

    function automatic logic signed [Y_W-1:0] round_sat_y(input logic signed [AW-1:0] v);
        logic signed [AW-1:0] r;
        r = (v + HALF) >>> Y_SHIFT;
        if (r > Y_MAX)      return Y_W'(Y_MAX);
        else if (r < Y_MIN) return Y_W'(Y_MIN);
        else                return r[Y_W-1:0];
    endfunction

    logic signed [SW-1:0] s_xx_r, s_xx_i, s_xy_r, s_xy_i;
    logic signed [SW-1:0] s_yx_r, s_yx_i, s_yy_r, s_yy_i;

    complex_fir #(.N(N)) u_xx (.clk(clk), .xr(xr), .xi(xi), .wr(wr[XX]), .wi(wi[XX]), .sr(s_xx_r), .si(s_xx_i));
    complex_fir #(.N(N)) u_xy (.clk(clk), .xr(xr), .xi(xi), .wr(wr[XY]), .wi(wi[XY]), .sr(s_xy_r), .si(s_xy_i));
    complex_fir #(.N(N)) u_yx (.clk(clk), .xr(yr), .xi(yi), .wr(wr[YX]), .wi(wi[YX]), .sr(s_yx_r), .si(s_yx_i));
    complex_fir #(.N(N)) u_yy (.clk(clk), .xr(yr), .xi(yi), .wr(wr[YY]), .wi(wi[YY]), .sr(s_yy_r), .si(s_yy_i));

    logic signed [AW-1:0] ax_r, ax_i, ay_r, ay_i;

    always_comb begin
        ax_r = s_xx_r + s_yx_r;     // output x: x-input filter + y-input filter
        ax_i = s_xx_i + s_yx_i;
        ay_r = s_xy_r + s_yy_r;     // output y
        ay_i = s_xy_i + s_yy_i;

        yx_re = round_sat_y(ax_r);
        yx_im = round_sat_y(ax_i);
        yy_re = round_sat_y(ay_r);
        yy_im = round_sat_y(ay_i);
    end

endmodule
