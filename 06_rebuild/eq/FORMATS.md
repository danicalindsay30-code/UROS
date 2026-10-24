# CMA equaliser: fixed-point formats

Spec for `py/cma_int.py` and every RTL module. `Qm.n` = m integer bits
including the sign, n fractional bits. Ranges measured by
`py/float_ranges.py` (main.py signal chain, seed 2, OSNR 20, N = 5 and 21,
mu = 2^-10, 10,008 symbols).

Rounding everywhere: round half up, `(v + 2^(s-1)) >>> s`, same as the
matched filter. Saturate (clamp) wherever a format is narrower than the
exact result; never wrap, because a wrapped value flips sign inside the
feedback loop.

| Signal | Bits | Format | Range | LSB | Float max | Why | Made by |
|---|---|---|---|---|---|---|---|
| x (re, im) | 8 | Q3.5 | ±4 | 3.1e-2 | 2.34 (rms 1.01) | 3 int bits hold 2.34; 8 bits = ADC / matched filter input width | round + saturate in Python (stimulus) |
| w taps | 24 | Q2.22 | ±2 | 2.4e-7 | 1.0002 | >1 needs 2 int bits; 22 frac bits so only 0.1 % of updates round to zero (Q4.12: 56 %); 24 ≤ 27-bit DSP A port | saturate on update |
| x · w* | 32 | Q5.27 | exact | | | 8 × 24, no rounding | DSP |
| FIR sum | 37 (N=5), 39 (N=21) | Q.27 | exact | | | 32 + ceil(log2(4N)) for 4N real products | DSP cascade, ≤ 48 |
| y (re, im) | 16 | Q3.13 | ±4 | 1.2e-4 | 2.16 | 3 int bits hold 2.16; 16 bits fits DSP ports for the squares | `(sum + 2^13) >>> 14`, saturate |
| \|y\|² | 33 | Q7.26 | exact | | 5.27 | 16 × 16 squared, two summed | DSP |
| R | 33 | Q7.26 | 1.0 = 2^26 | | | same format as \|y\|² so the subtraction lines up | constant |
| e = R − \|y\|² | 16 | Q4.12 | ±8 | 2.4e-4 | 4.27 | 4 int bits hold 4.27 | exact subtract, `>>> 14` rounded, saturate |
| e · y* | 32 | Q7.25 | exact | | 9.16 | 16 × 16 | DSP |
| g = mu·e·y* | 18 | 23 frac bits | ±2^-6 = ±0.0156 | 1.2e-7 | 0.0089 | mu = 2^-10 is free: frac 25 + 10 = 35, round to 23 (`>>> 12`); 18 bits = DSP B port, so g·x is one DSP | rounded, saturate |
| dw = g · x | 26 → tap LSB | frac 28 → 22 | | | 0.0226 | rounded to the tap LSB before adding | `(p + 2^5) >>> 6` |
| w_new | 24 | Q2.22 | ±2 | | 1.0002 | | `sat(w + dw)` |

Real multiplies per symbol, all parallel (architecture A):
N = 5: 80 FIR + 4 |y|² + 4 e·y* + 80 dw = **168 DSP48E2**;
N = 21: 336 + 4 + 4 + 336 = **680** (XCK26 has 1,248).

## Evidence

mu = 2^-10 against main.py's 1e-3 (33,904 bits scored, 1500-symbol convergence discarded):

| OSNR | N | BER mu = 1e-3 | BER mu = 2^-10 |
|---|---|---|---|
| 20 | 5 / 21 | 0 / 0 | 0 / 0 |
| 14 | 5 | 1.209e-3 | 1.239e-3 |
| 14 | 21 | 2.271e-3 | 2.242e-3 |
| 12 | 5 | 8.141e-3 | 8.229e-3 |
| 12 | 21 | 1.203e-2 | 1.221e-2 |

Differences are one or two bit errors, inside the statistical noise.

Tap updates lost to rounding (|dw| < half an LSB), N = 5:

| Tap LSB | 2^-12 | 2^-14 | 2^-18 | 2^-22 |
|---|---|---|---|---|
| updates rounded to 0 | 56.0 % | 17.9 % | 1.4 % | 0.1 % |

At DGD 0.1 even Q4.12 taps only cost ~2 bit errors (modified_equaliser.py, OSNR 14,
BER 1.298e-3 against 1.239e-3), because the channel is close to the identity start.
The finer tap LSB matters for tracking a channel that keeps changing, and costs no DSPs.
