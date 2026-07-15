import generate_qpsk as qk
import pulse_shaping as ps
import matplotlib.pyplot as plt
import numpy as np 
import channel
import adaptive_equaliser as ae
import receiver_rrc as recieve
import decider

#Transmitter/modulation parameters

num_symbols = 10000 #number of transmitted QPSK symbols 
span = 8 #root rasied cosine filter span(symbols )
sps = 2 # samples per symbol (oversampling factor)
rolloff = 0.35 #RRC roll-off factor
R = 1 # constant modulous radiys for QPSK(CMA refrence)

#Optical channel parameters 

Rs = 32e9          # Symbol rate
OSNR_dB = 20       # Optical signal-to-noise Rato (dB)
B_ref = 12.5e9     # reference bandwidth used for OSNR calculation

DGD_spec = 0.1    # differential group delay [ps/sqrt(km)]
num_sections = 20 # Number of PMD fibre sections
fiber_length = 80e3    # Fibre length (m)

#adaptive equaliser parameters

num_taps = 21 # number of FIR taps in each butterfly filter 
mu = 100e-5 # CMA adaptation step sixe (learning rate )
convergence_symbols = 1500 #Number of symbols discarded while the CMA converges 
#is dependent on the learnimg rate mu 


#constellation 
constellation = np.array([
    (1 + 1j),
    (-1 + 1j),
    (-1 - 1j),
    (1 - 1j)
]) / np.sqrt(2)



tx_bits_H, symbolsH = qk.generate_qpsk(num_symbols)
tx_bits_V, symbolsV = qk.generate_qpsk(num_symbols)

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


# Downsample to one sample per symbol chnaged this 
rx = E_matched[::sps]



equalised_x,equalised_y = ae.adaptive_equalizer( rx, num_taps, mu , R)
equalised_x = equalised_x[convergence_symbols:]
equalised_y = equalised_y[convergence_symbols:]

#equalised is outputting symbols using two arrays representing the vertical and horizontal



# Decision device for each polarisation 
decided_symbolsX, decision_indexX = decider.symbol_decision(
    equalised_x,
    constellation
)
decided_symbolsY, decision_indexY = decider.symbol_decision(
    equalised_y,
    constellation
)


# Demapper
rx_bits_H = decider.qpsk_demapper(decision_indexX)
rx_bits_V = decider.qpsk_demapper(decision_indexY)


tx_bits = np.concatenate((tx_bits_H[convergence_symbols*2:], tx_bits_V[convergence_symbols*2:]))
rx_bits = np.concatenate((rx_bits_H, rx_bits_V ))


ber = decider.bit_error_rate(tx_bits,rx_bits)
print(ber)



# plt.figure()
# plt.plot(np.abs(equalised_x))
# plt.xlabel("sample")
# plt.ylabel("Magnitude")
# plt.title("Magnitude of Equalised X Signal")
# plt.grid(True)
# plt.show()

# plt.figure(figsize=(15,5))

# plt.subplot(141)
# plt.scatter(symbolsH.real, symbolsH.imag)
# plt.title("Original")


# plt.subplot(142)
# plt.scatter(rx[:,0].real, rx[:,0].imag)
# plt.title("Received")

# plt.subplot(143)
# plt.scatter(equalised_x.real, equalised_x.imag)
# plt.title("Equalized")


# plt.axis("equal")
# plt.show()
# plt.figure(figsize=(10,4))

# plt.subplot(121)
# plt.scatter(Einput[:,0].real, Einput[:,0].imag, s=2)
# plt.title("Input to PMD")

# plt.subplot(122)
# plt.scatter(E_pmd[:,0].real, E_pmd[:,0].imag, s=2)
# plt.title("Output of PMD")

# plt.axis("equal")
# plt.show()

# print(Einput[:5])
# print(E_pmd[:5])


