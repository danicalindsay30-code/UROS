import numpy as np
from transmit_rrc import RRC_filter
import matplotlib.pyplot as plt

def pulse_shaping(symbol_stream, sps, span, rolloff):
    """
    Pulse shape a symbol sequence using a Root Raised Cosine filter.
    creates the impulse response 
    convolution then adds these impulse response to form the transmitted wave 

    Parameters
    ----------
    symbol_stream : ndarray
        Complex QPSK symbols.
    sps : int
        Samples per symbol.
    span : int
        Filter span in symbols.
    rolloff : float
        RRC roll-off factor.

    Returns
    -------
    pulse_shaped_signal : ndarray
        Pulse-shaped transmitted waveform.
    """

    # Obtain the RRC filter coefficients (impulse response)
    
    g = RRC_filter(span, sps, rolloff)


    # Upsample the symbols (insert sps-1 zeros between symbols)
    upsampled_signal = np.zeros(len(symbol_stream) * sps, dtype=complex)
    upsampled_signal[::sps] = symbol_stream


    # Apply the transmit filter
    pulse_shaped_signal = np.convolve(
        upsampled_signal,
        g,
        mode="same"
    )

    # Normalise to unit average power
    pulse_shaped_signal = (
        pulse_shaped_signal
        / np.sqrt(np.mean(np.abs(pulse_shaped_signal) ** 2))
    )

    return pulse_shaped_signal