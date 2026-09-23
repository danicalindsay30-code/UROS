#!/usr/bin/env python3
"""
make_mem.py
===========

Converts MF_input_samples.txt into MF_input_samples.mem, the hex file
that $readmemh loads into the ROM inside the FPGA.

Each line of the output is one 32-bit word holding four int8 samples:

    bits 31..24 = Qy
    bits 23..16 = Iy
    bits 15.. 8 = Qx
    bits  7.. 0 = Ix

Negative values are converted to 8-bit two's complement first, because
the ROM stores raw bits with no notion of sign. The RTL reinterprets
them as signed when it unpacks.

Usage:
    python make_mem.py MF_input_samples.txt MF_input_samples.mem
"""

import sys

ROM_DEPTH = 128          # must match the RTL: logic [31:0] rom [0:127]


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "MF_input_samples.txt"
    dst = sys.argv[2] if len(sys.argv) > 2 else "MF_input_samples.mem"

    words = []
    with open(src) as f:
        for line_no, line in enumerate(f, 1):
            parts = line.split()
            if not parts:
                continue
            if len(parts) != 4:
                raise ValueError(f"{src}:{line_no} has {len(parts)} values, expected 4")

            ix, qx, iy, qy = (int(p) for p in parts)

            for name, v in (("Ix", ix), ("Qx", qx), ("Iy", iy), ("Qy", qy)):
                if not -128 <= v <= 127:
                    raise ValueError(f"{src}:{line_no} {name}={v} does not fit in int8")

            # & 0xFF turns a negative int into its 8-bit two's complement
            word = ((qy & 0xFF) << 24) | ((iy & 0xFF) << 16) \
                 | ((qx & 0xFF) <<  8) |  (ix & 0xFF)
            words.append(word)

    if len(words) > ROM_DEPTH:
        raise ValueError(f"{len(words)} samples will not fit in a {ROM_DEPTH}-entry ROM")

    n_real = len(words)
    words += [0] * (ROM_DEPTH - n_real)     # pad so every entry is defined

    with open(dst, "w") as f:
        for w in words:
            f.write(f"{w:08X}\n")

    print(f"wrote {dst}: {n_real} samples, padded to {ROM_DEPTH} lines")
    print(f"first word: {words[0]:08X}   (expect 02FA09EB for input -21 9 -6 2)")

    if words[0] != 0x02FA09EB:
        print("WARNING: first word is not the expected value - check the byte order")


if __name__ == "__main__":
    main()