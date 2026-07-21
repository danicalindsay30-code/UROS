import numpy as np
import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'cma_project'))


import generate_qpsk as qk
import pulse_shaping as ps
import channel
import adaptive_equaliser as ae
import receiver_rrc as recieve
import decider
import phase_recovery

sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'phase_3'))
#from phase 3 
import modified_equaliser as m_ae


def run_pipeline(
    num_symbols=50000,
    span=8,
    sps=2,
    rolloff=0.35,
    R=1,
    Rs=32e9,
    OSNR_dB=20,
    B_ref=12.5e9,
    DGD_spec=0.1,
    num_sections=20,
    fiber_length=80e3,
    num_taps=21,
    mu=100e-5,
    convergence_symbols=1500,
    bps_N=25,
    bps_B=64,
    seed=None,
    return_convergence_trace = False,
    total_bits = None,
    frac_bits = None
):
    """Runs the full tx->channel->rx->equalizer->phase recovery->BER pipeline once.
    Returns a dict of results, including BER, SER, and diagnostics."""

    if seed is not None:
        np.random.seed(seed)

    constellation = np.array([
        (1 + 1j), (-1 + 1j), (-1 - 1j), (1 - 1j)
    ]) / np.sqrt(2)

    tx_bits_H, symbolsH = qk.generate_qpsk(num_symbols)
    tx_bits_V, symbolsV = qk.generate_qpsk(num_symbols)

    txH = ps.pulse_shaping(symbolsH, sps, span, rolloff)
    txV = ps.pulse_shaping(symbolsV, sps, span, rolloff)
    Einput = np.column_stack((txH, txV))

    E_pmd = channel.PMDInsertion(Einput, DGD_spec, num_sections, fiber_length, Rs, sps)
    E_noise = channel.noise_insertion_osnr(E_pmd, OSNR_dB, sps, 2, Rs, B_ref)
    E_matched = recieve.matched_filter(E_noise, span, sps, rolloff)
    rx = E_matched[::sps]

    #quantisesed equaliser test 
    if total_bits is not None:
        equalised_x, equalised_y, coeff_max_mag = m_ae.adaptive_equalizer_quantized(
            rx, num_taps, mu, R, total_bits, frac_bits
        )
    else:
        equalised_x, equalised_y = ae.adaptive_equalizer(rx, num_taps, mu, R)
        coeff_max_mag = None
    if return_convergence_trace:
        # keep the raw, pre-truncation output for convergence analysis
        raw_x, raw_y = equalised_x.copy(), equalised_y.copy()

    equalised_x = equalised_x[convergence_symbols:]
    equalised_y = equalised_y[convergence_symbols:]

    ref_H = symbolsH[convergence_symbols:convergence_symbols + len(equalised_x)]
    ref_V = symbolsV[convergence_symbols:convergence_symbols + len(equalised_y)]

    # Polarization swap check
    corr_x_H = np.abs(np.vdot(equalised_x, ref_H))
    corr_x_V = np.abs(np.vdot(equalised_x, ref_V))
    swapped = corr_x_V > corr_x_H
    if swapped:
        equalised_x, equalised_y = equalised_y, equalised_x

    # Phase recovery
    equalised_x, theta_x = phase_recovery.bps_phase_recovery(equalised_x, constellation, N=bps_N, B=bps_B)
    equalised_y, theta_y = phase_recovery.bps_phase_recovery(equalised_y, constellation, N=bps_N, B=bps_B)

    equalised_x, rot_x, _ = phase_recovery.resolve_residual_ambiguity(equalised_x, constellation, ref_H)
    equalised_y, rot_y, _ = phase_recovery.resolve_residual_ambiguity(equalised_y, constellation, ref_V)

    decided_x, decision_index_x = decider.symbol_decision(equalised_x, constellation)
    decided_y, decision_index_y = decider.symbol_decision(equalised_y, constellation)

    ser_x = decider.symbol_error_rate(ref_H, decided_x)
    ser_y = decider.symbol_error_rate(ref_V, decided_y)

    rx_bits_H = decider.qpsk_demapper(decision_index_x)
    rx_bits_V = decider.qpsk_demapper(decision_index_y)

    tx_bits = np.concatenate((tx_bits_H[convergence_symbols*2:], tx_bits_V[convergence_symbols*2:]))
    rx_bits = np.concatenate((rx_bits_H, rx_bits_V))
    ber = decider.bit_error_rate(tx_bits, rx_bits)

    result = {
        "DGD_spec": DGD_spec, "mu": mu, "OSNR_dB": OSNR_dB, "num_taps": num_taps,
        "seed": seed, "swapped": swapped, "rot_x": rot_x, "rot_y": rot_y,
        "ser_x": ser_x, "ser_y": ser_y, "ber": ber,"coeff_max_mag":coeff_max_mag
    }

    if return_convergence_trace:
        result["raw_x"] = raw_x
        result["raw_y"] = raw_y

    return result

run_pipeline()