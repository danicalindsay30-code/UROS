# Dual-Polarisation RRC Matched Filter

SystemVerilog receiver matched filter for a dual-polarisation QPSK
coherent optical DSP chain, verified against a Python golden model and
implemented for the Kria KR260.

## Status

| Stage | State |
|---|---|
| Python golden model | complete |
| Fixed-point word-length analysis | complete |
| RTL implementation (pipelined) | complete |
| Simulation vs golden model | verified, 100 % within ±1 LSB |
| Synthesis and implementation | complete, 100–278 MHz sweep |
| Hardware verification on KR260 | not yet run |

---

## 1. Function

- Receiver half of a root-raised-cosine (RRC) pulse-shaping pair
- Transmit RRC + receive RRC = raised cosine → zero inter-symbol interference at symbol instants
- Maximises SNR at the decision point for white Gaussian noise
- Four independent real streams, one identical FIR each:

| Stream | Meaning |
|---|---|
| `Ix` | X polarisation, in-phase |
| `Qx` | X polarisation, quadrature |
| `Iy` | Y polarisation, in-phase |
| `Qy` | Y polarisation, quadrature |

---

## 2. Architecture

```
Ix ──► matched_filter_pipeline ──► Ix_out
Qx ──► matched_filter_pipeline ──► Qx_out
Iy ──► matched_filter_pipeline ──► Iy_out
Qy ──► matched_filter_pipeline ──► Qy_out
         dp_matched_filter_pipeline
```

### Pipeline stages (per channel)

| Stage | Operation | Register |
|---|---|---|
| 0 | shift register, 17 × 8-bit | `shift_reg` |
| 1 | 17 multiplies, 8 × 8 → 16-bit | `product_reg` |
| 2 | 4 partial sums | `partial_sum` |
| 3 | final accumulate, 24-bit | `accumulator_reg` |
| 4 | round and rescale, `(acc + 64) >>> 7` | `scaled_val` |
| 5 | output register | `sample_out` |

- Latency: 6 clock cycles
- Throughput: 1 sample per clock per channel
- `valid_in` delayed through a matching 6-stage chain → `valid_out`
- Reset clears all pipeline and valid registers
- Coefficients held as a `localparam` array in the RTL

---

## 3. Fixed-point analysis

### Formats

| Signal | Width | Format | Notes |
|---|---|---|---|
| Input | 8-bit signed | Q1.7 | models an 8-bit ADC |
| Coefficients | 8-bit signed | Q1.7 | `round(128 × c)` |
| Product | 16-bit | — | 8 × 8 |
| Accumulator | 24-bit | — | 17 bits provably sufficient |
| Output | 18-bit | — | 10 bits provably sufficient |

### Input scaling

- `input_scale = 127 / max|E_noise|`
- Same scale applied to input samples **and** reference output
- Earlier bug: two independent scale factors → constant ≈1.36× offset that looked like a hardware gain error

### Coefficients

- RRC: span 8, 2 samples/symbol, roll-off 0.35, unit energy → 17 taps
- Quantised taps: `[0, 1, −2, 2, 5, −12, −8, 55, 99, 55, −8, −12, 5, 2, −2, 1, 0]`
- Peak tap 99 of 127
- Max coefficient error: 0.0026
- Symmetric, outer two taps zero — not yet exploited

### Accumulator width

- Bit growth set by Σ|taps|, not tap count
- Σ|taps| = 269
- Worst case: 127 × 269 = 34,163 → **17 bits** signed
- Implemented: 24 bits → 7 bits unused headroom

### Rounding

- `>>> 7` alone truncates toward −∞ → systematic −0.5 LSB bias
- Fix: add half an LSB (64) before the shift

| | Truncation | Round to nearest |
|---|---|---|
| Exact match | 50.43 % | **70.47 %** |
| Mean error | −0.51 LSB | **+0.015 LSB** |
| Max \|error\| | 2 LSB | **1 LSB** |

---

## 4. Verification method

| Level | Model | Question | Criterion |
|---|---|---|---|
| 1 | Floating-point pipeline | Does the algorithm work? | BER vs OSNR |
| 2 | Bit-exact integer model | What does quantisation cost? | measured |
| 3 | RTL | Is the implementation correct? | 0 mismatches vs level 2 |

- RTL is **not** pass/failed against the float model — they compute different things
- Float model: float samples × float taps
- RTL: int8 samples × int8 taps
- Difference = input quantisation + coefficient quantisation + output rounding
- ±1 LSB spread is a measurement, not a tolerance

### Testbench

- Driver pushes samples in with `valid_in` high
- Separate monitor writes a row whenever `valid_out` is high
- Monitor needs no knowledge of pipeline latency
- Sample count read from file, not hardcoded
- Flush: `NUM_TAPS − 1` zero samples with valid high, then drain

---

## 5. Simulation results

116 samples × 4 channels, seed 42, OSNR 20 dB, DGD 0.1.

| Metric | Unpipelined | Pipelined |
|---|---|---|
| Exact match | 70.47 % | 70.47 % |
| Within ±1 LSB | 100.00 % | 100.00 % |
| Max \|error\| | 1 LSB | 1 LSB |
| Mean error | +0.015 LSB | +0.015 LSB |
| RMS error | 0.543 LSB | 0.543 LSB |

- Pipelined and unpipelined results identical → pipelining changed timing, not arithmetic
- Best alignment at shift 0; shift 1 drops to 5 % → valid chain depth is correct
- 132 output rows = 116 samples + 16 flush, as expected
- Per channel exact match: 73.3 / 69.0 / 74.1 / 65.5 % (Ix / Qx / Iy / Qy)
- All channel means within ±0.09 LSB → no channel-specific fault
- RMS 0.543 LSB consistent with combined input and coefficient quantisation noise

---

## 6. Implementation results

- Vivado 2026.1
- Target: XCK26-SFVC784-2LV-C (Kria KR260)
- Top: `dp_matched_filter_pipeline`, ports mapped to I/O, no pin location constraints
- All figures post-route

### Frequency sweep

| Period (ns) | Freq (MHz) | WNS (ns) | Critical path (ns) | Registers | CLB | DSP | Result |
|---|---|---|---|---|---|---|---|
| 10.000 | 100 | +5.147 | 4.853 | 557 | 59 | 68 | pass |
| 5.000 | 200 | +0.859 | 4.141 | 553 | — | 68 | pass |
| 4.000 | 250 | +0.241 | 3.759 | 557 | 62 | 68 | pass |
| 3.800 | 263 | +0.146 | 3.654 | 557 | 79 | 68 | pass |
| 3.600 | 278 | +0.008 | 3.592 | 653 | 87 | 68 | marginal pass |

- Hold slack positive at every point (+0.024 to +0.044 ns)
- Zero failing endpoints at every point
- **Maximum measured frequency: 278 MHz**
- **Recommended operating point: 250 MHz**
- 278 MHz has 8 ps of slack — not usable once process, voltage and temperature variation are considered

### Observations

- **Critical path shortens as the constraint tightens** — 4.853 → 3.592 ns
  - Tool only optimises as hard as the constraint demands
  - A single relaxed run underestimates Fmax; the constraint must be swept
- **Speed is bought with area** — 250 → 278 MHz:
  - +11 % frequency
  - +17 % registers (557 → 653)
  - +40 % CLB (62 → 87)
  - DSPs unchanged
  - Extra resources come from logic replication to shorten paths
- **Diminishing returns** at the top of the range

### Utilisation at 250 MHz

| Resource | Used | Available | Utilisation |
|---|---|---|---|
| CLB registers | 557 | 234,240 | 0.24 % |
| CLB | 62 | 14,640 | 0.42 % |
| DSP48E2 | 68 | 1,248 | 5.45 % |
| Bonded IOB | 108 | 189 | 57.14 % |
| BUFGCE | 1 | 112 | 0.89 % |

- 68 DSPs = 17 taps × 4 channels
- Registers far below the ~570 bits/channel in the RTL — DSP48E2 internal pipeline registers absorb the product and partial-sum stages
- I/O dominates at 57 %:
  - 4 × 8 in + 4 × 18 out + clk, rst, valid_in, valid_out = 108 pins
  - Test wrapper only; a real system streams over AXI

### Critical path (250 MHz)

- From: partial-sum register (stage 2)
- To: accumulator register (stage 3)
- Both inside DSP48E2 blocks

| Property | Value |
|---|---|
| Total delay | 3.603 ns |
| Logic delay | 2.432 ns (67 %) |
| Net delay | 1.171 ns (33 %) |
| Logic levels | 5 |

- Bottleneck: four-input 24-bit adder combining the partial sums
- Logic-dominated → arithmetic depth, not routing
- Possible fix: split into two-level adder tree (+1 cycle latency, ~half the depth)
- Not implemented — current frequency already exceeds requirement

### Context

- 32 GBd × 2 samples/symbol = 64 GSample/s
- No single one-sample-per-clock instance reaches that rate
- Real receivers process many samples per clock in parallel
- Results characterise the implementation, not a system throughput target

---

## 7. Hardware verification (planned)

| # | Test | Proves |
|---|---|---|
| 1 | Impulse response | tap order, scaling, latency |
| 2 | Worst-case magnitude | accumulator width |
| 3 | Golden-model regression | end-to-end correctness |
| 4 | Back-pressure | handshake (once AXI-Stream wrapped) |

- Pass criterion: hardware vs RTL simulation = **0 mismatches**

---

## 8. Known limitations

- `input_scale` is data-dependent, not a fixed design constant
- Accumulator 24 bits where 17 suffice; output 18 bits where 10 suffice
- Coefficients hardcoded in RTL — no longer generated from the Python model
- Reset is asynchronous; synchronous reset is preferred on Xilinx devices
- No clock enable — required before AXI-Stream back-pressure can work
- Coefficient symmetry not exploited (pre-adder could halve multipliers)
- Only one dataset tested (seed 42, OSNR 20 dB)
- DSP attribution: 4 × 10 per instance = 40, top level reports 68 — 28 unattributed
- 200 MHz CLB count not recorded
- No unpipelined baseline implemented — cost of pipelining not isolated

---

## 9. Files

| Path | Contents |
|---|---|
| `matched_filter_pipeline.sv` | single-channel pipelined FIR |
| `dp_matched_filter_pipeline.sv` | four-channel wrapper |
| `dp_matched_filter_pipeline_tb.sv` | valid-driven testbench |
| `timing.xdc` | clock constraint |
| `results/` | timing and utilisation reports |
| `03_Data/MF_input_samples.txt` | int8 stimulus |
| `03_Data/MF_python_model_out.txt` | golden reference |
| `03_Data/MF_sv_filter_output.txt` | RTL output |

### Reproducing

1. Run the pipeline script → writes stimulus and reference into `03_Data/`
2. Create a Vivado project, add sources by reference (copy unticked)
3. Simulate with `run -all` (default 1000 ns stops early, empty output file)
4. Compare RTL output against the golden reference

---

## 10. Next steps

1. Run on KR260 hardware (ROM + ILA test harness)
2. Implement the unpipelined baseline for a before/after comparison
3. Wrap in AXI-Stream with clock enable
4. Implement symmetric pre-adder variant and compare DSP usage
5. Move on to the CMA adaptive equaliser
