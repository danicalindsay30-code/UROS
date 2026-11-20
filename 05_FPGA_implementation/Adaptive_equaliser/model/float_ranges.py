"""
float_ranges.py
===============
Range and step-size study. Runs the float equaliser (same maths as
adaptive_equaliser.py + adaptive_algorithim.cma) with every intermediate
recorded, then prints:

  1. a fidelity check: the instrumented copy gives the same outputs as
     adaptive_equalizer() in the golden model
  2. BER/SER for mu = 1e-3 (main.py) against mu = 2^-10
  3. the range of every signal the hardware has to carry

Usage:  python float_ranges.py
"""

import numpy as np

import chain
import adaptive_equaliser as ae


def equalise_traced(rx, num_taps, mu, R):
    """adaptive_equalizer() with a recorder bolted on. Maths unchanged."""
    xin, yin = rx[:, 0], rx[:, 1]
    c = num_taps // 2
    w = {k: np.zeros(num_taps, complex) for k in ("xx", "xy", "yx", "yy")}
    w["xx"][c] = 1
    w["yy"][c] = 1
    out_x = np.zeros(len(xin), complex)
    out_y = np.zeros(len(yin), complex)

    rec = {k: [] for k in ("y", "mag2", "e", "ey", "g", "dw", "w")}
    for n in range(c, len(xin) - c):
        xw = xin[n - c:n + c + 1]
        yw = yin[n - c:n + c + 1]
        ox = np.vdot(w["xx"], xw) + np.vdot(w["yx"], yw)
        oy = np.vdot(w["xy"], xw) + np.vdot(w["yy"], yw)
        out_x[n], out_y[n] = ox, oy

        ex, ey = R - abs(ox) ** 2, R - abs(oy) ** 2
        gx, gy = mu * ex * np.conj(ox), mu * ey * np.conj(oy)
        dw = {"xx": gx * xw, "yx": gx * yw, "xy": gy * xw, "yy": gy * yw}
        for k in w:
            w[k] = w[k] + dw[k]

        rec["y"] += [ox, oy]
        rec["mag2"] += [abs(ox) ** 2, abs(oy) ** 2]
        rec["e"] += [ex, ey]
        rec["ey"] += [ex * np.conj(ox), ey * np.conj(oy)]
        rec["g"] += [gx, gy]
        rec["dw"].append(np.concatenate(list(dw.values())))
        rec["w"].append(np.concatenate(list(w.values())))
    for k in rec:
        rec[k] = np.concatenate(rec[k]) if k in ("dw", "w") else np.array(rec[k])
    return out_x, out_y, rec


def comp_max(z):
    """Largest real or imaginary component (what a fixed-point word must hold)."""
    z = np.asarray(z)
    return max(np.max(np.abs(z.real)), np.max(np.abs(z.imag)))


def bits_for(v):
    """Integer bits (incl. sign) needed to hold +/-v."""
    return int(np.floor(np.log2(v))) + 2 if v >= 1 else 1


if __name__ == "__main__":
    rx, tx_h, tx_v = chain.make_rx(seed=2, osnr_db=20)

    # 1. fidelity check against the golden-model function
    for n_taps in (5, 21):
        ox, oy, _ = equalise_traced(rx, n_taps, chain.MU, chain.R)
        rx_, ry_ = ae.adaptive_equalizer(rx, n_taps, chain.MU, chain.R)
        assert np.allclose(ox, rx_) and np.allclose(oy, ry_)
    print("instrumented model == adaptive_equalizer(): OK\n")

    # 2. mu = 1e-3 vs 2^-10, two OSNRs, N = 5 and 21
    print(f"{'OSNR':>4} {'N':>3} {'mu':>10} {'SER':>10} {'BER':>10}")
    for osnr in (20, 14, 12):
        rx_o, th, tv = chain.make_rx(seed=2, osnr_db=osnr)
        for n_taps in (5, 21):
            for mu in (1e-3, 2.0 ** -10):
                ox, oy, _ = equalise_traced(rx_o, n_taps, mu, chain.R)
                ser, ber = chain.score(ox, oy, th, tv)
                print(f"{osnr:>4} {n_taps:>3} {mu:>10.3e} {ser:>10.2e} {ber:>10.2e}")
    print()

    # 3. ranges, OSNR 20, both tap counts
    for n_taps in (5, 21):
        _, _, r = equalise_traced(rx, n_taps, 2.0 ** -10, chain.R)
        dwmag = np.abs(np.concatenate((r["dw"].real, r["dw"].imag)))
        dwmag = dwmag[dwmag > 0]
        print(f"--- N = {n_taps} ---")
        rows = [
            ("input x (rx)", comp_max(rx)),
            ("y", comp_max(r["y"])),
            ("|y|^2", np.max(r["mag2"])),
            ("e = R-|y|^2", np.max(np.abs(r["e"]))),
            ("e*conj(y)", comp_max(r["ey"])),
            ("g = mu*e*conj(y)", comp_max(r["g"])),
            ("dw = g*x", comp_max(r["dw"])),
            ("taps w", comp_max(r["w"])),
        ]
        for name, v in rows:
            print(f"{name:<18} max {v:10.5f}   int bits {bits_for(v)}")
        print(f"{'|dw| percentiles':<18} 50%: {np.percentile(dwmag, 50):.2e}  "
              f"10%: {np.percentile(dwmag, 10):.2e}  1%: {np.percentile(dwmag, 1):.2e}")
        print(f"{'|y| after conv.':<18} mean {np.mean(np.sqrt(r['mag2'][2 * 1500:])):.4f}  "
              f"rms of e {np.sqrt(np.mean(r['e'][2 * 1500:] ** 2)):.4f}")
        print(f"{'rx rms':<18} {np.sqrt(np.mean(np.abs(rx) ** 2) / 2):.4f} per component\n")
