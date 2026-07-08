import generate_qpsk as qk
import pulse_shaping as ps
import matplotlib.pyplot as plt
import numpy as np 
import channel
import adaptive_equaliser as ae
import receiver_rrc as recieve

#Transmitter/modulation parameters

num_symbols = 5000 #number of transmitted QPSK symbols 
span = 8 #root rasied cosine filter span(symbols )
sps = 2 # samples per symbol (oversampling factor)
rolloff = 0.35 #RRC roll-off factor
R = 1 # constant modulous radiys for QPSK(CMA refrence)

#Optical channel parameters 

Rs = 32e9          # Symbol rate
OSNR_dB = 20       # Optical signal-to-noise Rato (dB)
B_ref = 12.5e9     # reference bandwidth used for OSNR calculation

DGD_spec = 1    # differential group delay [ps/sqrt(km)]
num_sections = 20 # Number of PMD fibre sections
fiber_length = 80e3    # Fibre length (m)

#adaptive equaliser parameters

num_taps = 21 # number of FIR taps in each butterfly filter 
mu = 100e-5 # CMA adaptation step sixe (learning rate )




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


equalised_x,equalised_y = ae.adaptive_equalizer( rx, num_taps, mu , R)

print(equalised_x.shape)

fina_equ = equalised_x[::2]


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
