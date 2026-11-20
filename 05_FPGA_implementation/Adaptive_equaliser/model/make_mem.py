"""
make_mem.py
===========
Turns the cma_int.py vectors into the two ROM images for eq_board_top.

  eq_in_rom.mem   one 32-bit hex word per input symbol   {yi, yr, xi, xr}
  eq_ref_rom.mem  one 64-bit hex word per output         {yy_im, yy_re, yx_im, yx_re}

Each field is two's complement (v & mask), same packing as the matched
filter's convert_samples_to_coe.py. Unused ROM addresses are padded with 0.

Usage:  python make_mem.py 5
"""

import os
import sys

import numpy as np

DEPTH = 16384


def pack(values, width):
    word = 0
    for j, v in enumerate(values):                 # values[0] goes in the low bits
        word |= (int(v) & ((1 << width) - 1)) << (j * width)
    return word


def main(n):
    d = os.path.join(os.path.dirname(__file__), "..", "vectors", f"N{n}")
    x_in = np.loadtxt(os.path.join(d, "eq_in.txt"), dtype=np.int64)        # xr xi yr yi
    out = np.loadtxt(os.path.join(d, "eq_out_ref.txt"), dtype=np.int64)    # k yx_re yx_im yy_re yy_im

    with open(os.path.join(d, "eq_in_rom.mem"), "w") as fh:
        for i in range(DEPTH):
            fh.write(f"{pack(x_in[i], 8) if i < len(x_in) else 0:08X}\n")
    with open(os.path.join(d, "eq_ref_rom.mem"), "w") as fh:
        for i in range(DEPTH):
            fh.write(f"{pack(out[i, 1:], 16) if i < len(out) else 0:016X}\n")
    print(f"wrote eq_in_rom.mem ({len(x_in)} words) and eq_ref_rom.mem ({len(out)} words) in {d}")


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 5)
