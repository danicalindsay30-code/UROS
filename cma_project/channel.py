import numpy as np
from math import pi
import matplotlib.pyplot as plt


def PMDInsertion(Einput, DGDSpec, N, L, Rs, SpS):
    
    plt.figure()
    plt.plot(np.real(Einput[:,0]))
    plt.title("Horizontal Polarization - Before PMD")
    plt.grid()
  

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