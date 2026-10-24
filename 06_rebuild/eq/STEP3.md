# Step 3: write the RTL, one module at a time

You write every `TODO`. Ports, the package and the test vectors are fixed,
because they have to match `cma_int.py`. Each module passes its own
test (0 errors) before you start the next.

## Vivado setup (once)

1. New project, or reuse `06_rebuild/matched_filter`, targeting XCK26-SFVC784-2LV-C.
2. Add sources **by reference** (untick "Copy sources into project"):
   - Design sources: everything in `06_rebuild/eq/src/`. `eq_pkg.sv` must compile first
     (Vivado usually works this out; if not: right-click it, Move to top).
   - Simulation sources: everything in `06_rebuild/eq/tb/`.
3. For each test: right-click the tb, **Set as Top**, Run Behavioral Simulation, then `run -all` in the Tcl console.
4. Test vectors already exist in `vectors/N5/`. If they ever go missing:
   `python py/cma_int.py --dump 5` then `python py/gen_unit_vectors.py 5`.

## Order of work

| # | Write | Test with | Done when | What it teaches |
|---|---|---|---|---|
| 1 | `cmult.sv` | `tb_cmult.sv` (random, no file) | 0 errors, both variants | signed widths, conj |
| 2 | `cma_error.sv` + `tb_cma_error.sv` | `unit_error.txt` (300 rows) | 0 errors | **the file-test pattern**: get it right once, copy it after |
| 3 | `complex_fir.sv` | `unit_fir.txt` (1200 rows) | 0 errors | generate loops, exact sums |
| 4 | `butterfly.sv` | `unit_butterfly.txt` (300 rows) | 0 errors | 2-D arrays, round + saturate |
| 5 | `cma_update.sv` | `unit_update.txt` (300 rows) | 0 errors | nested generate, which g / which window |
| 6 | `cma_equaliser.sv` | `tb_eq.sv`, `eq_in.txt` → `eq_out_ref.txt` | 10,004 outputs, 0 mismatches | FSM, handshake, the feedback loop |

`cma_error` is second, before the FIR, on purpose: it is the smallest
file-driven test, so you learn the reading/compare pattern on 10 numbers a row
instead of 64.

## Architecture: K = 4 clocks per symbol

| Clock | State | Captured at the end of the clock |
|---|---|---|
| 1 | `S_IDLE` | sample shifted into both delay lines (`in_ready = 1`) |
| 2 | `S_FIR` | y = butterfly(windows, taps) |
| 3 | `S_ERR` | e, g = cma_error(y) |
| 4 | `S_UPD` | taps = cma_update(g, windows, taps); `out_valid = 1` |

Throughput = f_clk / 4: 25 MBd per polarisation at 100 MHz.

## Why 5 taps

Your own plan said "start with 5" to keep the build small. The tap sweep shows
it is also a sound choice, not just a convenient one (float model, OSNR 14,
mu = 2^-10, DGD 0.1, BER):

| N | 3 | 5 | 7 | 9 | 13 | 21 |
|---|---|---|---|---|---|---|
| seed 2 | 1.003e-3 | 1.239e-3 | 1.209e-3 | 1.534e-3 | 1.711e-3 | 2.242e-3 |
| seed 3 | 1.327e-3 | 1.357e-3 | 1.416e-3 | 1.386e-3 | 1.681e-3 | 2.124e-3 |
| seed 4 | 1.121e-3 | 1.209e-3 | 1.239e-3 | 1.209e-3 | 1.209e-3 | 1.386e-3 |
| mean | 1.15e-3 | 1.27e-3 | 1.29e-3 | 1.38e-3 | 1.53e-3 | 1.92e-3 |

- **The channel's memory is tiny.** Mean DGD = 0.1 ps/√km × √80 km ≈ 0.9 ps, under
  3 % of the 31.25 ps symbol period. Almost no ISI reaches a neighbouring symbol.
- **3 to 9 taps are equal within the noise** (a few bit errors out of 33,904). From 13 taps
  the BER rises: each extra tap adds adaptation noise and removes no ISI.
- **5 is the smallest with margin**: ±2 symbols of reach for a larger DGD or a timing
  offset, at the same BER as 3.
- **Hardware**: 168 DSPs for 5 taps against 680 for 21.
- **It is a parameter**: `N` changes the RTL and the vectors (`--dump 21`) in one place.
  At a high DGD (your `taps_sweep.py` high-DGD case) more taps would win.
