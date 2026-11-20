"""
rtl_ber.py
==========
Step 4b: score the RTL's own output (results/rtl_out_N5.txt, written by
tb_eq.sv) with the golden-model back end: swap check, BPS, ambiguity,
decision, SER/BER. Also plots the constellation before and after.

Usage:  python rtl_ber.py
"""

import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

import chain
import cma_int as ci

N = 5
HERE = os.path.dirname(__file__)
RES = os.path.join(HERE, "..", "results")

rx, th, tv = chain.make_rx(seed=2, osnr_db=20)
rtl = np.loadtxt(os.path.join(RES, f"rtl_out_N{N}.txt"), dtype=np.int64)
ref = np.loadtxt(os.path.join(HERE, "..", "vectors", f"N{N}", "eq_out_ref.txt"), dtype=np.int64)

print(f"RTL rows {len(rtl)}, reference rows {len(ref)}, "
      f"identical: {np.array_equal(rtl, ref[:, 1:])}")

ox, oy = ci.to_python_layout(ref[:, 0], rtl, len(rx), N)
ser, ber = chain.score(ox, oy, th, tv, verbose=True)
print(f"RTL output through BPS + decision: SER {ser:.3e}  BER {ber:.3e}  (OSNR 20 dB)")

fig, ax = plt.subplots(1, 3, figsize=(12, 4.2))
conv = chain.CONVERGENCE_SYMBOLS
ax[0].plot(rx[conv:, 0].real, rx[conv:, 0].imag, ".", ms=1.5)
ax[0].set_title("equaliser input, X (after matched filter)")
ax[1].plot(ox[conv:-N].real, ox[conv:-N].imag, ".", ms=1.5)
ax[1].set_title("RTL output y_x (before phase recovery)")
ax[2].plot(np.arange(len(ox) - N), np.abs(ox[:-N]), ".", ms=1)
ax[2].axvline(conv, color="k", ls="--", lw=.8)
ax[2].set_title("RTL |y_x| against symbol index"); ax[2].set_ylim(0, 2)
for a in ax[:2]:
    a.set_aspect("equal"); a.set_xlim(-2, 2); a.set_ylim(-2, 2); a.grid(alpha=.3)
fig.tight_layout()
fig.savefig(os.path.join(RES, "rtl_constellation_N5.png"), dpi=140)
print("saved results/rtl_constellation_N5.png")
