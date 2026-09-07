import numpy as np 

def symbol_decision(equalised_symbols, constellation):
    """
    Maps each equalised symbol to the nearest QPSK constellation point.

    Parameters
    ----------
    equalised_symbols : ndarray
        Complex equaliser output.

    constellation : ndarray
        Ideal QPSK constellation.

    Returns
    -------
    decided_symbols : ndarray
        Nearest constellation symbols.

    decision_index : ndarray
        Index of the chosen constellation point.
    """

    decided_symbols = np.zeros_like(equalised_symbols, dtype=complex)
    decision_index = np.zeros(len(equalised_symbols), dtype=int)

    for i, symbol in enumerate(equalised_symbols):

        # Euclidean distance to every constellation point
        distances = np.abs(symbol - constellation)

        # Closest constellation point
        index = np.argmin(distances)

        decided_symbols[i] = constellation[index]
        decision_index[i] = index

    return decided_symbols, decision_index

def qpsk_demapper(decision_index):
    """
    Converts QPSK symbol decisions back into bits.
    """

    bit_map = {
        0: [0, 0],
        1: [0, 1],
        2: [1, 1],
        3: [1, 0]
    }

    bits = []

    for index in decision_index:
        bits.extend(bit_map[index])

    return np.array(bits)

def bit_error_rate(tx_bits, rx_bits):
    """
    Calculates the bit error rate.
    """

    errors = np.sum(tx_bits != rx_bits)

    ber = errors / len(tx_bits)

    return ber

def symbol_error_rate(tx_symbols, decided_symbols):
    """
    tx_symbols, decided_symbols : complex arrays, same length,
    already aligned (same indexing convention as your BER call).
    """
    if len(tx_symbols) != len(decided_symbols):
        raise ValueError(f"Length mismatch: {len(tx_symbols)} vs {len(decided_symbols)}")
    errors = np.sum(tx_symbols != decided_symbols)
    
    return errors / len(tx_symbols)