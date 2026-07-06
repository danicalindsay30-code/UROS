import generate_qpsk as qk
import pulse_shaping as ps
import matplotlib.pyplot as plt
import numpy as np 
import channel
import adaptive_equaliser as ae
import receiver_rrc as recieve

num_symbols = 10000

span = 8
sps = 2
rolloff = 0.35
R = 1

Rs = 32e9          # 32 GBaud
OSNR_dB = 20       # fairly clean signal
B_ref = 12.5e9     # standard OSNR reference bandwidth

DGD_spec = 10    # ps/sqrt(km)
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



# Matched filter
E_matched = recieve.matched_filter(
    E_noise,
    span,
    sps,
    rolloff
)

# Downsample to one sample per symbol
rx = E_matched[::sps]


equalised_x,equalised_y = ae.adaptive_equalizer(rx,21,1e-5,1)
print(equalised_x.shape)

fina_equ = equalised_x[::2]
print(fina_equ[20:30])
print(fina_equ.shape)

plt.figure()
plt.plot(np.abs(fina_equ))
plt.xlabel("sample")
plt.ylabel("Magnitude")
plt.title("Magnitude of Equalised X Signal")
plt.grid(True)
plt.show()



plt.figure(figsize=(15,5))

plt.subplot(131)
plt.scatter(symbolsH.real, symbolsH.imag)
plt.title("Original")


plt.subplot(132)
plt.scatter(rx[:,0].real, rx[:,0].imag)
plt.title("Received")

plt.subplot(133)
plt.scatter(equalised_x.real, equalised_x.imag)
plt.title("Equalized")

plt.axis("equal")
plt.show()
