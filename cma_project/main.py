import generate_qpsk as qk
import pulse_shaping as ps
import matplotlib.pyplot as plt
import numpy as np 
import channel

num_symbols = 2

span = 8
sps = 8
rolloff = 0.35

Rs = 32e9          # 32 GBaud
OSNR_dB = 20       # fairly clean signal
B_ref = 12.5e9     # standard OSNR reference bandwidth

DGD_spec = 0.1    # ps/sqrt(km)
num_sections = 20
fiber_length = 80e3    # 80 km
bitsH, symbolsH = qk.generate_qpsk(num_symbols)
bitsV, symbolsV = qk.generate_qpsk(num_symbols)

txH = ps.pulse_shaping(symbolsH, sps, span, rolloff)
txV = ps.pulse_shaping(symbolsV, sps, span, rolloff)

Einput = np.column_stack((txH, txV))

E_pmd = channel.PMDInsertion(
    Einput,
    DGD_spec,
    num_sections,
    fiber_length,
    Rs,
    sps
)

E_noise = channel.noise_insertion_osnr(
    E_pmd,
    OSNR_dB,
    sps,
    2,
    Rs,
    B_ref
)
plt.figure(figsize=(10,4))

plt.subplot(1,2,1)
plt.plot(np.real(E_pmd[:,0]))
plt.title("Before AWGN")

plt.subplot(1,2,2)
plt.plot(np.real(E_noise[:,0]))
plt.title("After AWGN")
plt.show()

plt.figure(figsize=(6,6))

plt.scatter(
    np.real(E_noise[::sps, 0]),
    np.imag(E_noise[::sps, 0]),
    s=20
)

plt.xlabel("In-phase")
plt.ylabel("Quadrature")
plt.title("Horizontal Polarisation Constellation")
plt.grid()
plt.axis("equal")


plt.figure(figsize=(6,6))

plt.scatter(
    np.real(E_noise[::sps, 1]),
    np.imag(E_noise[::sps, 1]),
    s=20
)

plt.xlabel("In-phase")
plt.ylabel("Quadrature")
plt.title("Vertical Polarisation Constellation")
plt.grid()
plt.axis("equal")
plt.show()