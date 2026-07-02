import numpy as np 

import numpy as np

def RRC_filter(span, sps, rolloff):
    """
    Generate the impulse response (FIR coefficients) of a
    Root Raised Cosine (RRC) filter.

    Parameters
    ----------
    span : int
        Filter span in symbols.
    sps : int
        Samples per symbol.
    rolloff : float
        Roll-off factor (0 <= rolloff <= 1).

    Returns
    -------
    g : ndarray
        Impulse response (filter coefficients).
    """

    # Number of taps
    num_taps = span * sps + 1

    # Time vector (measured in symbol periods)
    k = np.arange(-span * sps / 2,
                  span * sps / 2 + 1) / sps

    # Allocate coefficient array
    g = np.zeros_like(k)

    #  Find singularities 

    # k = 0
    i1 = np.isclose(k, 0)

    # k = ±1/(4β)
    i2 = np.isclose(np.abs(4 * rolloff * k), 1)

    # Everything else
    i3 = ~(i1 | i2)

    #  Centre coefficient 

    g[i1] = 1 - rolloff + (4 * rolloff / np.pi)

    #  Second singularity 

    g[i2] = (
        rolloff / np.sqrt(2)
        * (
            (1 + 2 / np.pi)
            * np.sin(np.pi / (4 * rolloff))
            + (1 - 2 / np.pi)
            * np.cos(np.pi / (4 * rolloff))
        )
    )

    # Normal equation 

    g[i3] = (
        np.sin(np.pi * k[i3] * (1 - rolloff))
        + 4 * rolloff * k[i3]
        * np.cos(np.pi * k[i3] * (1 + rolloff))
    ) / (
        np.pi
        * k[i3]
        * (1 - (4 * rolloff * k[i3]) ** 2)
    )

    # Normalise 

    g = g / np.max(np.abs(g))

    return g