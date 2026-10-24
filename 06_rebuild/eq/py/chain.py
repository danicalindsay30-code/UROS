"""
chain.py
========
Shared front end and back end for the equaliser work, copied step for step
from 01_Python/Golden_model/main.py so every model in 06_rebuild/eq is fed
exactly the same signal and scored exactly the same way.

    make_rx(...)      -> T-spaced matched-filter output, the equaliser input
    score(...)        -> swap check, BPS, ambiguity, decision, SER/BER
"""

import os
import sys

import numpy as np

GOLDEN = os.path.join(os.path.dirname(__file__), "..", "..", "..", "01_Python", "Golden_model")
sys.path.insert(0, os.path.abspath(GOLDEN))

import generate_qpsk as qk          # noqa: E402
import pulse_shaping as ps          # noqa: E402
import channel                      # noqa: E402
import receiver_rrc as recieve      # noqa: E402
import decider                      # noqa: E402
import phase_recovery               # noqa: E402

# main.py parameters
NUM_SYMBOLS = 10000
SPAN, SPS, ROLLOFF = 8, 2, 0.35
R = 1
RS, B_REF = 32e9, 12.5e9
DGD_SPEC, NUM_SECTIONS, FIBER_LENGTH = 0.1, 20, 80e3
MU = 100e-5
CONVERGENCE_SYMBOLS = 1500

CONSTELLATION = np.array([(1 + 1j), (-1 + 1j), (-1 - 1j), (1 - 1j)]) / np.sqrt(2)


def make_rx(seed=2, osnr_db=20, num_symbols=NUM_SYMBOLS):
    """Transmitter, PMD, noise, matched filter, downsample: main.py order."""
    np.random.seed(seed)
    bits_h, sym_h = qk.generate_qpsk(num_symbols)
    bits_v, sym_v = qk.generate_qpsk(num_symbols)

    tx_h = ps.pulse_shaping(sym_h, SPS, SPAN, ROLLOFF)
    tx_v = ps.pulse_shaping(sym_v, SPS, SPAN, ROLLOFF)
    e_in = np.column_stack((tx_h, tx_v))

    e_pmd = channel.PMDInsertion(e_in, DGD_SPEC, NUM_SECTIONS, FIBER_LENGTH, RS, SPS)
    e_noise = channel.noise_insertion_osnr(e_pmd, osnr_db, SPS, 2, RS, B_REF)
    e_matched = recieve.matched_filter(e_noise, SPAN, SPS, ROLLOFF)

    rx = e_matched[::SPS]
    return rx, (bits_h, sym_h), (bits_v, sym_v)


def best_lag(eq, ref, conv, length, max_lag=24):
    """Delay d (symbols) that best lines eq[conv+d:] up with ref[conv:]."""
    scores = [np.abs(np.vdot(eq[conv + d:conv + d + length], ref[conv:conv + length]))
              for d in range(max_lag + 1)]
    return int(np.argmax(scores)), max(scores)


def score(eq_x, eq_y, tx_h, tx_v, conv=CONVERGENCE_SYMBOLS, verbose=False):
    """
    Everything main.py does after the equaliser. Returns (ser, ber).

    One change from main.py: since pulse_shaping moved to mode="full", the
    stream is 8 symbols longer and the symbol-to-output delay is no longer 0,
    so main.py's vdot raised a shape error. Here the delay is found by
    correlation against the known symbols (simulation only, like main.py's
    swap check) and both outputs are trimmed to the same length.
    """
    bits_h, sym_h = tx_h
    bits_v, sym_v = tx_v
    max_lag = 24
    length = len(sym_h) - conv - max_lag

    lag_xh, s_xh = best_lag(eq_x, sym_h, conv, length, max_lag)
    lag_xv, s_xv = best_lag(eq_x, sym_v, conv, length, max_lag)
    if s_xv > s_xh:
        eq_x, eq_y = eq_y, eq_x
        if verbose:
            print("polarisation swap corrected")
    lag_x, _ = best_lag(eq_x, sym_h, conv, length, max_lag)
    lag_y, _ = best_lag(eq_y, sym_v, conv, length, max_lag)
    if verbose:
        print(f"delay: x {lag_x}, y {lag_y} symbols")

    eq_x = eq_x[conv + lag_x:conv + lag_x + length]
    eq_y = eq_y[conv + lag_y:conv + lag_y + length]
    ref_h = sym_h[conv:conv + length]
    ref_v = sym_v[conv:conv + length]

    eq_x, _ = phase_recovery.bps_phase_recovery(eq_x, CONSTELLATION, N=25, B=64)
    eq_y, _ = phase_recovery.bps_phase_recovery(eq_y, CONSTELLATION, N=25, B=64)
    eq_x, _, _ = phase_recovery.resolve_residual_ambiguity(eq_x, CONSTELLATION, ref_h)
    eq_y, _, _ = phase_recovery.resolve_residual_ambiguity(eq_y, CONSTELLATION, ref_v)

    dec_x, idx_x = decider.symbol_decision(eq_x, CONSTELLATION)
    dec_y, idx_y = decider.symbol_decision(eq_y, CONSTELLATION)
    ser = (decider.symbol_error_rate(ref_h, dec_x) + decider.symbol_error_rate(ref_v, dec_y)) / 2

    rx_bits = np.concatenate((decider.qpsk_demapper(idx_x), decider.qpsk_demapper(idx_y)))
    tx_bits = np.concatenate((bits_h[conv * 2:(conv + length) * 2],
                              bits_v[conv * 2:(conv + length) * 2]))
    ber = decider.bit_error_rate(tx_bits, rx_bits)
    return ser, ber
