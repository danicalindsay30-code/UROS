`timescale 1ns / 1ps
//=====================================================================
// cma_equaliser: top level, architecture A (multi-cycle)       YOU WRITE
//---------------------------------------------------------------------
// Owns all the STATE: two delay lines (the windows), the tap registers,
// and the registers between stages. Everything else is the combinational
// blocks you unit-tested: butterfly, cma_error, cma_update.
//
//      in ──► [delay lines x, y] ──► butterfly ──► [y regs] ──► cma_error ──► [e, g regs]
//                    │                   ▲                                         │
//                    │                [taps] ◄──────────── cma_update ◄────────────┘
//                    └─────────────────────────────────────────▲   (window also feeds the update)
//
// SCHEDULE: one symbol = K = 4 clocks. A small FSM steps through:
//
//   S_IDLE  in_ready = 1. When in_valid: shift the new sample into both
//           delay lines. If the window is now full (this is the N-th
//           sample or later) go to S_FIR, else stay in S_IDLE (fill phase).
//   S_FIR   y regs  <= butterfly(windows, taps)
//   S_ERR   e, g    <= cma_error(y regs)
//   S_UPD   taps    <= cma_update(g, windows, taps);  out_valid = 1
//           (y regs still hold this symbol's output) -> back to S_IDLE
//
// WHY the taps only change in S_UPD and the next sample only enters in
// S_IDLE: symbol k+1's FIR must use the taps updated by symbol k. That
// is your Python's "update after every output, before the next one",
// and it is what makes 0 mismatches against cma_int.py possible.
// The cost: throughput = f_clk / 4. That is the feedback-loop trade-off.
//
// FILL PHASE: no output and no update for the first N-1 samples
// (Python's loop starts at n = c). Count samples in a small counter that
// stops at N-1.
//
// RESET (synchronous, like your matched filter):
//   delay lines 0, fill counter 0, state S_IDLE,
//   taps: all 0 EXCEPT wr[XX][N/2] = wr[YY][N/2] = W_ONE (1.0)  <- single spike
//
// Reference: cma_int.py run(); test: tb_eq.sv with vectors/N5/eq_in.txt
// and eq_out_ref.txt (10,008 inputs -> 10,004 outputs).
//=====================================================================

import eq_pkg::*;

module cma_equaliser #(
    parameter int N = 5
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic signed [X_W-1:0] x_re_in, x_im_in,     // x polarisation sample
    input  logic signed [X_W-1:0] y_re_in, y_im_in,     // y polarisation sample

    output logic                  out_valid,
    output logic signed [Y_W-1:0] yx_re, yx_im,          // equalised output x
    output logic signed [Y_W-1:0] yy_re, yy_im,          // equalised output y

    // debug: compare against eq_dbg_ref.txt when outputs mismatch
    output logic signed [E_W-1:0] dbg_e_x, dbg_e_y,
    output logic signed [G_W-1:0] dbg_gx_re, dbg_gx_im, dbg_gy_re, dbg_gy_im
);

    // TODO 1. State machine type:
    //            typedef enum logic [1:0] {S_IDLE, S_FIR, S_ERR, S_UPD} state_t;
    //            state_t state;

    // TODO 2. Registers (all written only in always_ff):
    //            delay lines   xr, xi, yr, yi        [0:N-1]  X_W bits, [0] newest
    //            taps          wr, wi                [0:3][0:N-1]  W_W bits
    //            y regs        (4 x Y_W)             written in S_FIR
    //            e, g regs     (2 x E_W, 4 x G_W)    written in S_ERR
    //            fill counter  logic [$clog2(N):0] fill;

    // TODO 3. Combinational blocks, instantiated once, always computing:
    //            butterfly   #(N) u_bf  ( windows + taps  -> bf_* wires )
    //            cma_error        u_err ( y REGS          -> err_* wires )
    //            cma_update  #(N) u_upd ( g REGS + windows + taps -> wr_new, wi_new )
    //         The FSM decides WHEN each result is captured into a register.
    //         TIP: this is the "compute always, register when needed" style.
    //         It keeps every always_ff tiny.

    // TODO 4. always_ff @(posedge clk):
    //            if (rst) ... reset everything (see RESET above; use a for
    //            loop for the arrays, then set the two centre taps).
    //            else case (state)
    //              S_IDLE: if (in_valid) begin
    //                          shift: for (int i = N-1; i > 0; i--) xr[i] <= xr[i-1]; ...
    //                          xr[0] <= x_re_in; ... (all four)
    //                          if (fill == N-1) state <= S_FIR;
    //                          else fill <= fill + 1;
    //                      end
    //              S_FIR:  capture bf_* into y regs;            state <= S_ERR;
    //              S_ERR:  capture err_* into e, g regs;        state <= S_UPD;
    //              S_UPD:  wr <= wr_new; wi <= wi_new;          state <= S_IDLE;
    //            endcase
    //         Q to answer: in S_IDLE the shift uses "<=". On the edge that
    //         moves to S_FIR, does butterfly see the OLD or the NEW window
    //         during S_FIR? (NEW: the shift has landed by then. Good.)

    // TODO 5. Outputs (combinational from state and registers):
    //            assign in_ready  = (state == S_IDLE);
    //            assign out_valid = (state == S_UPD);
    //            assign yx_re = <y reg> ... and the dbg_* from the e, g regs.

endmodule
