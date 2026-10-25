# FPGA Receiver DSP for Dual-Polarisation Coherent Optical Links

UROS summer research project, UCL.

This project takes two blocks of a dual-polarisation QPSK coherent optical receiver
from a Python golden model to verified hardware on the AMD Kria KR260
(Zynq UltraScale+ XCK26):

- the root-raised-cosine **matched filter**, and
- the 2×2 butterfly **adaptive equaliser**, which adapts its taps with the constant
  modulus algorithm (CMA).

Each block was designed from fixed-point analysis of the golden model, verified
against a bit-exact model in simulation, implemented, and run on the board.

```
 Tx RRC ─► fibre (PMD + ASE noise) ─► Rx RRC matched filter ─► ↓2 ─► 2×2 CMA equaliser ─► BPS phase recovery ─► decision
                                      └──────── FPGA ────────┘        └────── FPGA ──────┘
```

## Results

| Block | Verification | Implementation (XCK26) | Hardware |
|---|---|---|---|
| Matched filter: 4 × 17-tap RRC FIR, pipelined, 1 sample/clock/channel | RTL vs Python: 100 % within ±1 LSB of the float model (quantisation, measured) | 68 DSP; timing met up to 278 MHz, 250 MHz recommended | 0 mismatches vs simulation |
| CMA equaliser: 2×2 butterfly, 5 complex taps per filter, 6 clocks/symbol | RTL vs bit-exact model: 10,004 / 10,004 outputs identical; BER 0 at OSNR 20 dB | 176 DSP, 2,517 LUT; timing met at 100 MHz (WNS +1.643 ns) | 10,004 outputs, 0 mismatches |

## Repository

| Folder | Contents |
|---|---|
| `01_Python/Golden_model/` | floating-point system model: QPSK, RRC pulse shaping, PMD and ASE channel, matched filter, CMA butterfly equaliser, BPS phase recovery, decision and BER (`main.py`) |
| `02_Experiments/` | parameter sweeps on the golden model: OSNR, DGD, μ, tap count, convergence |
| `03_Data/` | matched filter stimulus, references, RTL and hardware outputs |
| `04_Fixed_point_analysis/` | word-length studies: quantisation, OSNR penalty, coefficient range |
| `05_FPGA_implementation/Matched_filter/` | matched filter RTL, testbenches, timing sweep, hardware harness. [README](05_FPGA_implementation/Matched_filter/README.md) |
| `05_FPGA_implementation/Adaptive_equaliser/` | CMA equaliser: bit-exact model, RTL, unit and system testbenches, KR260 build and hardware test. [README](05_FPGA_implementation/Adaptive_equaliser/README.md) |
| `results/` | golden-model plots (BER vs OSNR, μ, taps, DGD; CMA convergence) and matched filter implementation reports |

## Method

The same flow is used for both blocks:

1. **Golden model.** A floating-point Python model of the whole link, scored by BER.
2. **Fixed-point design.** Measure the range of every signal in the golden model.
   Choose integer bits from the largest values and fractional bits from the smallest
   change that matters. Check the BER cost.
3. **Bit-exact integer model.** Python using only integers, rounding exactly where the
   hardware does. This is the reference for the RTL; the float model isn't, because the
   two compute different things.
4. **RTL and verification.** SystemVerilog modules, each with a self-checking
   testbench driven by vectors from step 3. The pass bar is 0 mismatches.
5. **Implementation.** Vivado synthesis and place-and-route for the KR260, then timing
   and utilisation reports.
6. **Hardware.** The FPGA runs the same stimulus from on-chip ROM. Results are read
   through VIO and ILA debug cores and compared with simulation or the bit-exact model.

## Tools

- Python 3 with NumPy and Matplotlib
- AMD Vivado 2026.1 (xsim for simulation)
- Kria KR260 Robotics Starter Kit (XCK26-SFVC784-2LV-C)

## Reference

D. A. A. Mello and F. A. Barbosa, *Digital Coherent Optical Systems: Architecture and
Algorithms*, Optical Networks series, Springer, 2021.
Equation and figure numbers (5.7–5.39, Figs. 5.6–5.9) refer to its Section 5.2,
"Adaptive Equalization".
