import numpy as np
import decider 

def bps_phase_recovery(z, constellation, N=25, B=64):
    """
    Blind Phase Search (BPS) phase recovery for QPSK, single polarization.
    Direct translation of MATLAB Code 6.7 (Mello & Barbosa).

    Parameters:
    z : 1D complex ndarray
        Equalized signal, 1 sample/symbol, normalized to unit power.
    constellation : 1D complex ndarray
        Reference constellation points (your existing `constellation` array).
    N : int
        Number of past/future symbols used per phase estimate.
        Block length L = 2N+1. Larger N -> smoother estimate but slower
        to track fast phase changes. N=25 is a reasonable starting point.
    B : int
        Number of test rotation angles. Larger B -> finer phase resolution
        but more computation. B=64 is a common textbook default.

    Returns:
    v : 1D complex ndarray, same length as z
        Phase-corrected signal.
    theta_unwrapped : 1D float ndarray
        Estimated phase noise per symbol (for diagnostics/plotting).
    """
    L = 2 * N + 1
    p = np.pi / 2  # QPSK ambiguity period (90 degrees)

    b = np.arange(-B / 2, B / 2)
    theta_test = p * b / B  # shape (B,)

    num_symbols = len(z)
    z_padded = np.concatenate([np.zeros(N, dtype=complex), z, np.zeros(N, dtype=complex)])

    theta_unwrapped = np.zeros(num_symbols)
    theta_prev = 0.0

    rot_factors = np.exp(-1j * theta_test)  # shape (B,)

    for i in range(num_symbols):
        window = z_padded[i : i + L]                     # shape (L,)
        z_rot = np.outer(window, rot_factors)              # shape (L, B)

        # nearest-constellation-point decision for every rotated sample
        dists = np.abs(z_rot[:, :, None] - constellation[None, None, :]) ** 2
        decided = constellation[np.argmin(dists, axis=2)]  # shape (L, B)

        m = np.sum(np.abs(z_rot - decided) ** 2, axis=0)   # shape (B,)
        theta = theta_test[np.argmin(m)]

        # phase unwrapping across symbols (avoids +-90 deg cycle slips)
        theta = theta + np.floor(0.5 - (theta - theta_prev) / p) * p
        theta_unwrapped[i] = theta
        theta_prev = theta

    v = z * np.exp(-1j * theta_unwrapped)
    return v, theta_unwrapped

def resolve_residual_ambiguity(symbols, constellation, reference_symbols):
    """Simulation-only: finds the single best-fit 90-deg-multiple rotation
    remaining after BPS, using known tx symbols. Not usable on real hardware."""
    best_acc, best_rot = -1, 1
    for rot in [1, 1j, -1, -1j]:
        decided, _ = decider.symbol_decision(symbols * rot, constellation)
        acc = np.mean(decided == reference_symbols)
        if acc > best_acc:
            best_acc, best_rot = acc, rot
    return symbols * best_rot, best_rot, best_acc