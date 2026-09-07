import numpy as np
from pulse_shaping import RRC_filter

def matched_filter(received_signal, span, sps, rolloff):
    """
    Apply the receive Root Raised Cosine (RRC) matched filter.

    Parameters
    ----------
    received_signal : ndarray
        Received waveform.
        Shape (N,) for one polarization or (N,2) for dual polarization.

    span : int
        Filter span in symbols.

    sps : int
        Samples per symbol.

    rolloff : float
        RRC roll-off factor.

    Returns
    -------
    filtered_signal : ndarray
        Matched-filtered waveform.
    """

    # Generate the same RRC impulse response used at the transmitter
    h = RRC_filter(span, sps, rolloff)

   

    # Dual polarization
    filtered_x = np.convolve(received_signal[:, 0], h, mode="same")
    filtered_y = np.convolve(received_signal[:, 1], h, mode="same")

    return np.column_stack((filtered_x, filtered_y))


