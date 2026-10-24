# Running the CMA equaliser on the KR260

The FPGA checks itself: it plays the 10,008 test symbols from an on-chip
ROM through the equaliser and compares every one of the 10,004 outputs with
the answers from `cma_int.py`, stored in a second ROM. You read the result
on the VIO.

**Expected result:** `pass = 1`, `done = 1`, `out_count = 10004`, `err_count = 0`.

## 1. Files you need

| File | Where |
|---|---|
| Bitstream | `06_rebuild/eq/vivado/eq_board.runs/impl_1/system_wrapper.bit` |
| Probes file (VIO/ILA names) | `06_rebuild/eq/vivado/eq_board.runs/impl_1/system_wrapper.ltx` |

To rebuild them from scratch (about 15 minutes):
```
cd C:/dev/UROS/06_rebuild/eq
/c/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -source vivado_build.tcl
```
Or open `vivado/eq_board.xpr` in the Vivado GUI and click Generate Bitstream.

## 2. Board

Use **exactly the same board setup as your matched filter test**
(`mf_board_test`, the one that gave 0 mismatches): same power, same USB/JTAG cable,
same boot state. The design takes its 100 MHz clock from the Zynq PS
(`pl_clk0`), just like that test did, so the PS must be running the same way.

## 3. Program

1. Vivado → **Open Hardware Manager** → **Open Target** → **Auto Connect**.
2. Right-click the device (`xck26`) → **Program Device**.
   - Bitstream file: `system_wrapper.bit`
   - Debug probes file: `system_wrapper.ltx`
3. Program. The VIO and ILA dashboards appear (`hw_vio_1`, `hw_ila_1`).

## 4. Run and read the result (VIO)

1. In the VIO dashboard click **+** and add all probes.
2. `probe_out0` is **rst**. It starts at **1** (the design is held in reset).
3. Set `probe_out0` to **0**. The whole test takes 0.4 ms, so it's finished instantly.
4. Read the inputs:

| VIO probe | Signal | Expect |
|---|---|---|
| `probe_in0` | done | 1 |
| `probe_in1` | pass | 1 |
| `probe_in2` | out_count | 10004 (0x2714) |
| `probe_in3` | err_count | 0 |

5. To run it again: set `probe_out0` to 1, then back to 0.

**pass = 1 means the FPGA produced exactly the same integers as the Python
bit-exact model for every output.** That is your hardware result.

## 5. Optional: capture the constellation (ILA)

The ILA stores only the clocks where `out_valid = 1` (storage qualification),
so its 4,096 samples are 4,096 consecutive equaliser outputs.

1. Set `probe_out0` (rst) to **1** first.
2. In the ILA dashboard:
   - **Trigger setup**: add `out_valid` (probe0), condition `== 1` (R).
   - **Capture setup**: add `out_valid`, condition `== 1`. If there's no Capture tab,
     set Capture mode to **BASIC** in the ILA settings window first.
   - Trigger position: **0**.
3. Click **Run Trigger** (▶). The ILA waits.
4. Set `probe_out0` (rst) to **0**. The ILA triggers on the first output and fills.
5. Right-click the waveform → **Export ILA Data** → CSV.
6. On the PC:
   ```
   python 06_rebuild/eq/py/plot_ila.py path/to/iladata.csv
   ```
   It prints how many captured outputs match the Python model exactly (expect 4096 / 4096)
   and saves `results/kr260_ila_N5.png`: the convergence from mixed polarisations to
   4 clusters, captured on the real chip.

## If something is wrong

| You see | Likely cause |
|---|---|
| No VIO/ILA after programming | `.ltx` not loaded, or the clock isn't running (PS not booted the same way as the MF test) |
| `done = 0`, `out_count = 0` | still in reset: `probe_out0` is 1 |
| `done = 0`, `out_count` stuck between 0 and 10004 | clock stopped, or the reset was toggled mid-run |
| `err_count > 0` | the ROMs didn't load: check the build log for `eq_in_rom.mem` / `eq_ref_rom.mem` warnings |
