"""
cma_int.py
==========
Bit-exact integer model of the 2x2 CMA butterfly equaliser. This is the
reference the RTL must match with 0 mismatches. Formats: ../FORMATS.md.

It works the way the hardware will, not the way adaptive_equaliser.py loops:

  * one input symbol per step, shifted into a delay line with [0] = NEWEST
    (Python's window is oldest-first, so hardware tap i = Python tap N-1-i)
  * causal: output k uses inputs k-N+1 .. k, so it equals Python output[k-c]
  * fill phase: no output and no update until N symbols are in the delay line
    (Python's loop starts at n = c for the same reason)

Integers only inside the loop. Every rounding point is (v + 2^(s-1)) >> s,
which is Python's arithmetic shift, identical to SystemVerilog's >>>.

Usage:
    python cma_int.py               # validate against float, N = 5 and 21
    python cma_int.py --dump 5      # write test vectors for N = 5
"""

import argparse
import os

import numpy as np

import chain
import float_ranges

# ---- formats (FORMATS.md) ---------------------------------------------------
X_BITS, X_FRAC = 8, 5        # input, Q3.5
W_BITS, W_FRAC = 24, 22      # taps, Q2.22
Y_BITS, Y_FRAC = 16, 13      # output, Q3.13
E_BITS, E_FRAC = 16, 12      # error, Q4.12
G_BITS, G_FRAC = 18, 23      # g = mu*e*conj(y), 23 fractional bits
MU_SHIFT = 10                # mu = 2^-10

PROD_FRAC = X_FRAC + W_FRAC              # 27: x * w
Y_SHIFT = PROD_FRAC - Y_FRAC             # 14
MAG2_FRAC = 2 * Y_FRAC                   # 26
R_INT = 1 << MAG2_FRAC                   # R = 1.0 in the |y|^2 format
E_SHIFT = MAG2_FRAC - E_FRAC             # 14
EY_FRAC = E_FRAC + Y_FRAC                # 25
G_SHIFT = EY_FRAC + MU_SHIFT - G_FRAC    # 12
DW_FRAC = G_FRAC + X_FRAC                # 28
DW_SHIFT = DW_FRAC - W_FRAC              # 6

FILTERS = ("xx", "xy", "yx", "yy")       # input, output (your Python names)


def rshift_round(v, s):
    """Round half up then arithmetic shift right: (v + 2^(s-1)) >>> s."""
    return (v + (1 << (s - 1))) >> s


def sat(v, bits):
    """Clamp to a signed bits-wide range."""
    lo, hi = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    return np.clip(v, lo, hi)


def quantise_input(rx):
    """Float rx (N, 2) complex -> int8 Q3.5, columns xr xi yr yi."""
    cols = (rx[:, 0].real, rx[:, 0].imag, rx[:, 1].real, rx[:, 1].imag)
    q = [sat(np.floor(c * (1 << X_FRAC) + 0.5).astype(np.int64), X_BITS) for c in cols]
    return np.column_stack(q)


def run(x_int, num_taps, trace=False):
    """
    x_int: (L, 4) int, columns xr xi yr yi.
    Returns (k, y) where k are the input indices that produced an output and
    y is (len(k), 4): yx_re yx_im yy_re yy_im (Q3.13). With trace=True also
    returns per-output internals and the taps after every update.
    """
    n = num_taps
    c = n // 2
    i64 = np.int64

    # delay lines, [0] = newest
    xr = np.zeros(n, i64); xi = np.zeros(n, i64)
    yr = np.zeros(n, i64); yi = np.zeros(n, i64)

    # taps [filter][tap], HW order (index 0 multiplies the newest sample)
    wr = {f: np.zeros(n, i64) for f in FILTERS}
    wi = {f: np.zeros(n, i64) for f in FILTERS}
    wr["xx"][c] = 1 << W_FRAC          # single spike: centre is the same in both orders
    wr["yy"][c] = 1 << W_FRAC

    ks, outs, tr = [], [], []
    for k in range(len(x_int)):
        a, b, p, q = (int(v) for v in x_int[k])
        xr[1:] = xr[:-1].copy(); xr[0] = a
        xi[1:] = xi[:-1].copy(); xi[0] = b
        yr[1:] = yr[:-1].copy(); yr[0] = p
        yi[1:] = yi[:-1].copy(); yi[0] = q
        if k < n - 1:
            continue                    # fill phase

        win = {"x": (xr, xi), "y": (yr, yi)}

        # ---- FIR: sum over taps of conj(w) * x, exact (frac 27) ----------
        def fir(f):
            vr, vi = win[f[0]]
            re = np.sum(vr * wr[f] + vi * wi[f])
            im = np.sum(vi * wr[f] - vr * wi[f])
            return int(re), int(im)

        sxx, syx = fir("xx"), fir("yx")
        sxy, syy = fir("xy"), fir("yy")
        acc = {"x": (sxx[0] + syx[0], sxx[1] + syx[1]),
               "y": (sxy[0] + syy[0], sxy[1] + syy[1])}

        # ---- output: round to Q3.13, saturate ---------------------------
        y = {o: tuple(int(sat(rshift_round(v, Y_SHIFT), Y_BITS)) for v in acc[o])
             for o in ("x", "y")}

        # ---- error and g, per output ------------------------------------
        e, g = {}, {}
        for o in ("x", "y"):
            mag2 = y[o][0] ** 2 + y[o][1] ** 2                         # frac 26
            e[o] = int(sat(rshift_round(R_INT - mag2, E_SHIFT), E_BITS))  # frac 12
            ey_re = e[o] * y[o][0]                                     # e * conj(y)
            ey_im = -e[o] * y[o][1]                                    # frac 25
            g[o] = (int(sat(rshift_round(ey_re, G_SHIFT), G_BITS)),    # frac 23
                    int(sat(rshift_round(ey_im, G_SHIFT), G_BITS)))

        # ---- update: w += round(g_out * x_in) ---------------------------
        # filter name = input, output: w_xx and w_yx use g_x, w_xy and w_yy use g_y
        for f in FILTERS:
            gr, gi = g[f[1]]
            vr, vi = win[f[0]]
            dr = rshift_round(gr * vr - gi * vi, DW_SHIFT)              # frac 22
            di = rshift_round(gr * vi + gi * vr, DW_SHIFT)
            wr[f] = sat(wr[f] + dr, W_BITS)
            wi[f] = sat(wi[f] + di, W_BITS)

        ks.append(k)
        outs.append((*y["x"], *y["y"]))
        if trace:
            taps = np.concatenate([np.stack((wr[f], wi[f]), 1).ravel() for f in FILTERS])
            tr.append(((e["x"], e["y"], *g["x"], *g["y"]), taps))

    ks = np.array(ks)
    outs = np.array(outs, dtype=np.int64)
    if trace:
        return ks, outs, tr
    return ks, outs


def to_python_layout(ks, outs, length, num_taps):
    """Int outputs -> complex arrays laid out like adaptive_equalizer() output."""
    c = num_taps // 2
    scale = 1.0 / (1 << Y_FRAC)
    ox = np.zeros(length, complex)
    oy = np.zeros(length, complex)
    ox[ks - c] = (outs[:, 0] + 1j * outs[:, 1]) * scale
    oy[ks - c] = (outs[:, 2] + 1j * outs[:, 3]) * scale
    return ox, oy


def dump(num_taps, out_dir, seed=2, osnr_db=20):
    rx, _, _ = chain.make_rx(seed=seed, osnr_db=osnr_db)
    x_int = quantise_input(rx)
    ks, outs, tr = run(x_int, num_taps, trace=True)
    os.makedirs(out_dir, exist_ok=True)

    np.savetxt(os.path.join(out_dir, "eq_in.txt"), x_int, fmt="%d")
    np.savetxt(os.path.join(out_dir, "eq_out_ref.txt"),
               np.column_stack((ks, outs)), fmt="%d")
    np.savetxt(os.path.join(out_dir, "eq_dbg_ref.txt"),
               np.column_stack((ks, np.array([t[0] for t in tr]))), fmt="%d")
    np.savetxt(os.path.join(out_dir, "eq_taps_ref.txt"),
               np.column_stack((ks, np.array([t[1] for t in tr]))), fmt="%d")
    with open(os.path.join(out_dir, "README.txt"), "w") as fh:
        fh.write(
            f"cma_int.py vectors: N={num_taps}, seed={seed}, OSNR={osnr_db} dB, "
            f"{len(x_int)} input symbols, {len(ks)} outputs (first at k={ks[0]}).\n"
            "eq_in.txt       xr xi yr yi                    int8 Q3.5, one row per input symbol\n"
            "eq_out_ref.txt  k yx_re yx_im yy_re yy_im       Q3.13, one row per output\n"
            "eq_dbg_ref.txt  k e_x e_y gx_re gx_im gy_re gy_im   e Q4.12, g 23 frac bits\n"
            "eq_taps_ref.txt k then taps AFTER the update at k: filters xx, xy, yx, yy;\n"
            "                per filter tap 0..N-1 (0 = newest sample), each re im, Q2.22\n"
        )
    print(f"wrote {out_dir}: {len(x_int)} inputs, {len(ks)} outputs")


def validate():
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    res_dir = os.path.join(os.path.dirname(__file__), "..", "results")
    os.makedirs(res_dir, exist_ok=True)

    print(f"{'OSNR':>4} {'N':>3} {'float SER':>10} {'float BER':>10} {'int SER':>10} {'int BER':>10} {'rms |dy|':>9}")
    for osnr in (20, 14, 12):
        rx, th, tv = chain.make_rx(seed=2, osnr_db=osnr)
        x_int = quantise_input(rx)
        for n in (5, 21):
            fx, fy, _ = float_ranges.equalise_traced(rx, n, 2.0 ** -MU_SHIFT, chain.R)
            ks, outs = run(x_int, n)
            ix, iy = to_python_layout(ks, outs, len(rx), n)
            fs, fb = chain.score(fx, fy, th, tv)
            is_, ib = chain.score(ix, iy, th, tv)
            dy = np.sqrt(np.mean(np.abs(np.concatenate((ix - fx, iy - fy))) ** 2))
            print(f"{osnr:>4} {n:>3} {fs:>10.3e} {fb:>10.3e} {is_:>10.3e} {ib:>10.3e} {dy:>9.4f}")

            if osnr == 20:
                fig, ax = plt.subplots(figsize=(9, 3.6))
                idx = np.arange(len(fx))
                ax.plot(idx, np.abs(ix), ".", ms=1.2, label="integer model, |y_x|")
                ax.plot(idx, np.abs(fx), ".", ms=1.2, alpha=.5, label="float model, |y_x|")
                ax.axvline(chain.CONVERGENCE_SYMBOLS, color="k", lw=.8, ls="--")
                ax.set_xlabel("symbol index"); ax.set_ylabel("|y|"); ax.set_ylim(0, 2)
                ax.set_title(f"CMA convergence, N = {n}, OSNR {osnr} dB, mu = 2^-10")
                ax.legend(loc="upper right", markerscale=8)
                fig.tight_layout()
                fig.savefig(os.path.join(res_dir, f"cma_int_convergence_N{n}.png"), dpi=140)
                plt.close(fig)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump", type=int, metavar="N", help="write test vectors for N taps")
    args = ap.parse_args()
    if args.dump:
        dump(args.dump, os.path.join(os.path.dirname(__file__), "..", "vectors", f"N{args.dump}"))
    else:
        validate()
