"""
gen_unit_vectors.py
===================
Cuts the full cma_int.py dump (vectors/N<n>/) into one small file per RTL
module, so each module can be unit-tested on its own before integration.

Every row is plain integers separated by spaces. Arrays are written as
N values in a row, index 0 first (0 = NEWEST sample, the hardware order).
Filter order is always xx, xy, yx, yy (input, output: your Python names).

  unit_fir.txt        xr[N] xi[N] wr[N] wi[N]  sum_re sum_im
                      one complex FIR: exact sum of conj(w)*x, 27 frac bits
  unit_butterfly.txt  xr[N] xi[N] yr[N] yi[N]  (wr[N] wi[N]) x 4 filters
                      yx_re yx_im yy_re yy_im          (Q3.13, rounded + saturated)
  unit_error.txt      yx_re yx_im yy_re yy_im  e_x e_y gx_re gx_im gy_re gy_im
  unit_update.txt     gx_re gx_im gy_re gy_im  xr[N] xi[N] yr[N] yi[N]
                      (wr[N] wi[N]) x 4 BEFORE   (wr[N] wi[N]) x 4 AFTER

Rows come from two places in the run: the first 150 outputs (start-up, big
errors) and 150 outputs from k = 5000 on (converged).

Usage:  python gen_unit_vectors.py 5
"""

import os
import sys

import numpy as np

import cma_int as ci

FILTERS = ci.FILTERS                                   # xx, xy, yx, yy


def load(n):
    d = os.path.join(os.path.dirname(__file__), "..", "vectors", f"N{n}")
    x_in = np.loadtxt(os.path.join(d, "eq_in.txt"), dtype=np.int64)
    out = np.loadtxt(os.path.join(d, "eq_out_ref.txt"), dtype=np.int64)
    dbg = np.loadtxt(os.path.join(d, "eq_dbg_ref.txt"), dtype=np.int64)
    taps = np.loadtxt(os.path.join(d, "eq_taps_ref.txt"), dtype=np.int64)
    return d, x_in, out, dbg, taps


def split_taps(row, n):
    """Flat dump row (per filter, per tap: re im) -> {f: (wr[n], wi[n])}."""
    t = row.reshape(4, n, 2)
    return {f: (t[j, :, 0], t[j, :, 1]) for j, f in enumerate(FILTERS)}


def initial_taps(n):
    z = np.zeros(n, np.int64)
    spike = z.copy(); spike[n // 2] = 1 << ci.W_FRAC
    return {"xx": (spike, z), "xy": (z, z), "yx": (z, z), "yy": (spike, z)}


def window(x_in, k, n, col):
    return x_in[k - np.arange(n), col]                 # [0] = newest = x_in[k]


def fir_sum(vr, vi, wr, wi):
    return int(np.sum(vr * wr + vi * wi)), int(np.sum(vi * wr - vr * wi))


def flat(*arrays):
    return " ".join(str(int(v)) for a in arrays for v in np.atleast_1d(a))


def main(n):
    d, x_in, out, dbg, taps = load(n)
    ks = out[:, 0]
    rows = list(range(150)) + list(range(5000 - (n - 1), 5000 - (n - 1) + 150))

    f_fir, f_bf, f_err, f_upd = ([] for _ in range(4))
    for r in rows:
        k = ks[r]
        w_before = initial_taps(n) if r == 0 else split_taps(taps[r - 1, 1:], n)
        w_after = split_taps(taps[r, 1:], n)
        win = {"x": (window(x_in, k, n, 0), window(x_in, k, n, 1)),
               "y": (window(x_in, k, n, 2), window(x_in, k, n, 3))}

        # one row per filter for the FIR test
        sums = {}
        for f in FILTERS:
            sums[f] = fir_sum(*win[f[0]], *w_before[f])
            f_fir.append(flat(*win[f[0]], *w_before[f], *sums[f]))

        # butterfly: check our bookkeeping reproduces cma_int's output exactly
        y = []
        for a, b in (("xx", "yx"), ("xy", "yy")):
            for part in (0, 1):
                s = sums[a][part] + sums[b][part]
                y.append(int(ci.sat(ci.rshift_round(s, ci.Y_SHIFT), ci.Y_BITS)))
        assert y == list(out[r, 1:]), f"butterfly mismatch at k={k}"
        f_bf.append(flat(*win["x"], *win["y"],
                         *[a for f in FILTERS for a in w_before[f]], *y))

        e_g = dbg[r, 1:]                                   # e_x e_y gx_re gx_im gy_re gy_im
        f_err.append(flat(out[r, 1:], e_g))

        # recompute the update from this row's own numbers
        g = {"x": (e_g[2], e_g[3]), "y": (e_g[4], e_g[5])}
        for f in FILTERS:
            gr, gi = g[f[1]]
            vr, vi = win[f[0]]
            nr = ci.sat(w_before[f][0] + ci.rshift_round(gr * vr - gi * vi, ci.DW_SHIFT), ci.W_BITS)
            ni = ci.sat(w_before[f][1] + ci.rshift_round(gr * vi + gi * vr, ci.DW_SHIFT), ci.W_BITS)
            assert np.array_equal(nr, w_after[f][0]) and np.array_equal(ni, w_after[f][1]), \
                f"update mismatch at k={k}, filter {f}"

        f_upd.append(flat(e_g[2:], *win["x"], *win["y"],
                          *[a for f in FILTERS for a in w_before[f]],
                          *[a for f in FILTERS for a in w_after[f]]))

    for name, lines in (("unit_fir.txt", f_fir), ("unit_butterfly.txt", f_bf),
                        ("unit_error.txt", f_err), ("unit_update.txt", f_upd)):
        with open(os.path.join(d, name), "w") as fh:
            fh.write("\n".join(lines) + "\n")
        print(f"{name:<20} {len(lines):>4} rows")


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 5)
