"""
plot_ila.py
===========
After the board run: export the ILA capture to CSV (Hardware Manager,
ILA waveform, right-click, Export ILA Data, CSV) and run

    python plot_ila.py path/to/iladata.csv

It reads out_valid, yx_re, yx_im, yy_re, yy_im (any radix Vivado used),
keeps the rows where out_valid = 1, checks them against eq_out_ref.txt
(they should be the first outputs, in order) and plots the constellation
and |y| like the simulation plot.
"""

import csv
import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

HERE = os.path.dirname(__file__)
NAMES = ("out_valid", "yx_re", "yx_im", "yy_re", "yy_im")


def parse(value, radix, width):
    radix = radix.upper()
    if "HEX" in radix:
        v = int(value, 16)
    elif "BIN" in radix:
        v = int(value, 2)
    else:
        v = int(value)
    already_signed = "SIGNED" in radix and "UNSIGNED" not in radix
    if not already_signed and width > 1 and v >= 1 << (width - 1):
        v -= 1 << width                       # two's complement for HEX / BINARY / UNSIGNED
    return v


def main(path):
    with open(path, newline="") as fh:
        rows = list(csv.reader(fh))
    header, radix_row, data = rows[0], rows[1], rows[2:]
    cols = {}
    for name in NAMES:
        hit = [j for j, h in enumerate(header) if name in h]
        if not hit:
            sys.exit(f"no column containing '{name}' in {header}")
        cols[name] = hit[0]

    out = []
    for r in data:
        if parse(r[cols["out_valid"]], radix_row[cols["out_valid"]], 1) == 1:
            out.append([parse(r[cols[n]], radix_row[cols[n]], 16) for n in NAMES[1:]])
    out = np.array(out)
    print(f"{len(out)} captured outputs")

    ref = np.loadtxt(os.path.join(HERE, "..", "vectors", "N5", "eq_out_ref.txt"), dtype=np.int64)[:, 1:]
    # find where the capture starts in the reference (usually row 0)
    start = next((s for s in range(len(ref) - len(out) + 1)
                  if np.array_equal(ref[s:s + 5], out[:5])), None)
    if start is None:
        print("could not line the capture up with eq_out_ref.txt")
    else:
        same = np.all(out == ref[start:start + len(out)], axis=1)
        print(f"capture starts at output {start}: {same.sum()} / {len(out)} match the Python model exactly")

    y = (out[:, 0] + 1j * out[:, 1]) / 2 ** 13
    fig, ax = plt.subplots(1, 2, figsize=(9, 4.2))
    ax[0].plot(y.real, y.imag, ".", ms=1.5); ax[0].set_aspect("equal")
    ax[0].set_xlim(-2, 2); ax[0].set_ylim(-2, 2); ax[0].grid(alpha=.3)
    ax[0].set_title("KR260 output y_x (ILA)")
    ax[1].plot(np.abs(y), ".", ms=1); ax[1].set_ylim(0, 2)
    ax[1].set_title("KR260 |y_x| against captured output")
    fig.tight_layout()
    dst = os.path.join(HERE, "..", "results", "kr260_ila_N5.png")
    fig.savefig(dst, dpi=140)
    print(f"saved {dst}")


if __name__ == "__main__":
    main(sys.argv[1])
