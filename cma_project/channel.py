import numpy as np
from math import pi
import matplotlib.pyplot as plt


def PMDInsertion(Einput, DGDSpec, N, L, Rs, SpS):
    
    plt.figure()
    plt.plot(np.real(Einput[:,0]))
    plt.title("Horizontal Polarization - Before PMD")
    plt.grid()
    # calculate tau - differential group delay - mutual delay experienced 
    SD_tau = np.sqrt((3 * pi) / 8) * DGDSpec
    tau = (SD_tau * np.sqrt(L * 1e-3) / np.sqrt(N)) * 1e-12

    N_samples = len(Einput)

    f = np.arange(-N_samples / 2, N_samples / 2) / N_samples
    fs = Rs * SpS
    f = f * fs
    w = 2 * np.pi * np.fft.fftshift(f)

    U = np.zeros((N, 2, 2), dtype=complex)
    V = np.zeros((N, 2, 2), dtype=complex)

    for i in range(N):

        A = np.random.randn(2, 2) + 1j * np.random.randn(2, 2)

        U_i, _, Vh_i = np.linalg.svd(A)

        U[i] = U_i
        V[i] = Vh_i.conj().T

    freq_EH = np.fft.fft(Einput[:, 0])
    freq_EV = np.fft.fft(Einput[:, 1])

    for i in range(N):

        U_hermitian = U[i].conj().T

        E_1 = (
            U_hermitian[0, 0] * freq_EV
            + U_hermitian[0, 1] * freq_EH
        )

        E_2 = (
            U_hermitian[1, 0] * freq_EV
            + U_hermitian[1, 1] * freq_EH
        )

        E_1 = np.exp(1j * w * tau / 2) * E_1
        E_2 = np.exp(-1j * w * tau / 2) * E_2

        freq_EV = (
            V[i, 0, 0] * E_1
            + V[i, 0, 1] * E_2
        )

        freq_EH = (
            V[i, 1, 0] * E_1
            + V[i, 1, 1] * E_2
        )

    EOutput = np.zeros_like(Einput, dtype=complex)

    EOutput[:, 0] = np.fft.ifft(freq_EH)
    EOutput[:, 1] = np.fft.ifft(freq_EV)
    plt.figure()
    plt.plot(np.real(EOutput[:,0]))
    plt.title("Horizontal Polarization - After PMD")
    plt.grid()
    plt.show()

    return EOutput

import numpy as np

def noise_insertion_osnr(signal, OSNR_dB, sps, num_polarisations, Rs, B_ref):
    """
    Add complex AWGN to the transmitted signal to achieve a target OSNR.

    Parameters
    signal : ndarray
        Input signal. Shape (N,) for one polarisation or (N,2) for dual
        polarisation.
    OSNR_dB : float
        Target OSNR in dB.
    sps : int
        Samples per symbol.
    num_polarisations : int
        Number of transmitted polarisations (1 or 2).
    Rs : float
        Symbol rate (symbols/s).
    B_ref : float
        Reference bandwidth for the OSNR measurement (Hz).

    Returns:
    received_signal : ndarray
        Signal after AWGN has been added.
    """

    # convert OSNR from dB to linear
    OSNR_linear = 10 ** (OSNR_dB / 10)

    # convert optical OSNR into the equivalent electrical SNR
    SNR_linear = ((2 * B_ref) / (num_polarisations * Rs)) * OSNR_linear

    # copy the signal so we don't overwrite the original
    received_signal = signal.copy()

    # work on one or two polarisations
    for pol in range(num_polarisations):

        # average signal power
        signal_power = np.mean(np.abs(signal[:, pol]) ** 2)

        # standard deviation of the AWGN
        std_dev = np.sqrt(signal_power * sps / (2 * SNR_linear))

        # generate complex Gaussian noise
        noise = (
            std_dev * np.random.randn(len(signal))
            + 1j * std_dev * np.random.randn(len(signal))
        )

        # add the noise
        received_signal[:, pol] += noise

    return received_signal