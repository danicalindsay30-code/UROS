`timescale 1ns / 1ps
//=====================================================================
// eq_board_top: KR260 hardware test harness for the CMA equaliser
//---------------------------------------------------------------------
// Same idea as the matched filter top_module, plus an on-chip checker:
//
//   ROM_IN  (10,008 x 32 bit)  input symbols from eq_in.txt
//      │  {yi, yr, xi, xr}, one per address
//      ▼
//   cma_equaliser (N = 5)  ── ready/valid handshake ──
//      │  out_valid, y_x, y_y
//      ▼
//   compare with ROM_REF (10,004 x 64 bit, eq_out_ref.txt from cma_int.py)
//      │
//      ▼
//   out_count, err_count, done, pass   ──► VIO (read them in Vivado)
//   out_valid, y_x, y_y                ──► ILA (capture the constellation)
//
// ROM reads take one clock, so each ROM is read one address AHEAD:
// when a sample is consumed (in_valid & in_ready), the ROM is already
// fetching the next one. That keeps a valid sample on the pins every
// clock, which the fill phase needs (it takes a sample every clock).
//
// Result on hardware: pass = 1 and err_count = 0 means the FPGA produced
// exactly the integers of the Python bit-exact model for all 10,004
// outputs.
//=====================================================================

import eq_pkg::*;

module eq_board_top #(
    parameter int    N       = 5,
    parameter int    N_IN    = 10008,
    parameter int    N_OUT   = 10004,
    parameter string IN_MEM  = "eq_in_rom.mem",
    parameter string REF_MEM = "eq_ref_rom.mem"
)(
    input  logic        clk,
    input  logic        rst,

    output logic        done,          // all outputs checked
    output logic        pass,          // done and no mismatches
    output logic [15:0] out_count,
    output logic [15:0] err_count,

    // literal 16 (= Y_W): a block design module reference can't read
    // package constants in its port list
    output logic        out_valid,     // for the ILA
    output logic signed [15:0] yx_re, yx_im, yy_re, yy_im
);

    localparam int DEPTH = 16384;      // 2^14 >= 10,008

    // ---- ROMs (block RAM) -------------------------------------------
    (* rom_style = "block" *) logic [31:0] rom_in  [0:DEPTH-1];
    (* rom_style = "block" *) logic [63:0] rom_ref [0:DEPTH-1];
    initial begin
        $readmemh(IN_MEM,  rom_in);
        $readmemh(REF_MEM, rom_ref);
    end

    // ---- driver: feed the equaliser from ROM_IN --------------------
    logic [13:0] in_idx, in_addr;
    logic [31:0] in_q;
    logic        primed, in_valid, in_ready;

    assign in_valid = primed && (in_idx < N_IN);
    assign in_addr  = (in_valid && in_ready) ? in_idx + 1'b1 : in_idx;   // read ahead

    always_ff @(posedge clk) in_q <= rom_in[in_addr];

    always_ff @(posedge clk) begin
        if (rst) begin
            in_idx <= '0;
            primed <= 1'b0;
        end else begin
            primed <= 1'b1;                        // in_q holds rom_in[0] by now
            if (in_valid && in_ready) in_idx <= in_idx + 1'b1;
        end
    end

    // ---- the equaliser --------------------------------------------------
    cma_equaliser #(.N(N)) u_eq (
        .clk(clk), .rst(rst),
        .in_valid(in_valid), .in_ready(in_ready),
        .x_re_in(in_q[7:0]),   .x_im_in(in_q[15:8]),
        .y_re_in(in_q[23:16]), .y_im_in(in_q[31:24]),
        .out_valid(out_valid),
        .yx_re(yx_re), .yx_im(yx_im), .yy_re(yy_re), .yy_im(yy_im),
        .dbg_e_x(), .dbg_e_y(), .dbg_gx_re(), .dbg_gx_im(), .dbg_gy_re(), .dbg_gy_im()
    );

    // ---- checker: compare every output with ROM_REF -----------------
    logic [13:0] out_idx, ref_addr;
    logic [63:0] ref_q;

    assign ref_addr = out_valid ? out_idx + 1'b1 : out_idx;              // read ahead
    always_ff @(posedge clk) ref_q <= rom_ref[ref_addr];

    always_ff @(posedge clk) begin
        if (rst) begin
            out_idx   <= '0;
            err_count <= '0;
        end else if (out_valid && out_idx < N_OUT) begin
            out_idx <= out_idx + 1'b1;
            if ({yy_im, yy_re, yx_im, yx_re} != ref_q && err_count != 16'hFFFF)
                err_count <= err_count + 1'b1;
        end
    end

    assign out_count = 16'(out_idx);
    assign done      = (out_idx == N_OUT);
    assign pass      = done && (err_count == 0);

endmodule
