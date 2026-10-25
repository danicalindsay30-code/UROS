# Hardware test on the Kria KR260

## Method

`rtl/eq_board_top.sv` makes the FPGA check itself:

```
ROM_IN  10,008 × 32 bit  (eq_in.txt)   ──► cma_equaliser (N = 5) ──► compare ◄── ROM_REF 10,004 × 64 bit
                                                                         │       (eq_out_ref.txt, cma_int.py)
                                       VIO ◄── done, pass, out_count, err_count
                                       ILA ◄── out_valid, y_x, y_y
```

The block design (`scripts/build_kr260.tcl`) takes its 100 MHz clock from the Zynq
PS (`pl_clk0`). A VIO drives reset and reads the result. An ILA can capture the outputs.

## Recorded result

| VIO probe | Value |
|---|---|
| `system_i/eq_top_done` | 1 |
| `system_i/eq_top_pass` | 1 |
| `system_i/eq_top_out_count` | 10004 |
| `system_i/eq_top_err_count` | 0 |

Every one of the 10,004 hardware outputs equals the bit-exact model.

## Procedure

**Files** (in `results/bitstream/`): `system_wrapper.bit`, `system_wrapper.ltx`.
They were built from `scripts/build_kr260.tcl`, with timing met (WNS +1.643 ns).

1. **Board.** SD card in (the same image used for the matched filter test),
   micro-USB to the PC (JTAG), 12 V power. Wait about one minute for the boot.
   The PS must be running, because it supplies the 100 MHz clock.
2. **Program.** Vivado → Open Hardware Manager → Open Target → Auto Connect.
   Right-click `xck26_0` → Program Device, with the bitstream and probes files above.
   The dashboards `hw_vio_1` and `hw_ila_1` appear.
3. **Run.** In `hw_vio_1` add all probes. Set the counts' radix to Unsigned Decimal.
   Change `system_i/vio_0_probe_out0` (reset, starts at 1) to **0**.
   The test takes 0.6 ms (10,008 symbols × 6 clocks).
4. **Read** `done`, `pass`, `out_count` and `err_count` (expected values in the table above).
   To repeat: reset 0 → 1 → 0.

### Optional: capture outputs with the ILA

The ILA stores only the clocks where `out_valid = 1`, so its 4,096 samples are 4,096
consecutive outputs.

1. Set reset to 1.
2. `hw_ila_1` → Settings window (if hidden: the dashboard's gear icon, tick Settings,
   Trigger Setup and Capture Setup):
   - Capture mode **BASIC**
   - Window depth **4096**
   - Trigger position **0**
3. Trigger Setup: `eq_top_out_valid == 1`. Capture Setup: `eq_top_out_valid == 1`.
4. Run Trigger, then set reset to 0.
5. Export ILA Data → CSV, then run:
   `python model/plot_ila.py <file.csv>`
   It checks every captured output against the model and plots the constellation.

## Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| no `xck26_0` | cable or driver | check USB, board power, Vivado cable drivers |
| "debug hub core was not detected" | no clock from the PS | use `scripts/program_kr260_xsdb.tcl` (runs `psu_init`, then loads the bitstream) |
| `done = 0`, `out_count = 0` | held in reset | set reset to 0 |
| `out_count` stuck below 10004 | clock stopped or reset toggled mid-run | reset 1 → 0 |
| `err_count > 0` | ROM images not loaded | check the build log for `eq_in_rom.mem` / `eq_ref_rom.mem` |
