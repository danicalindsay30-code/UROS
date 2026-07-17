import generate_qpsk as qk
import pulse_shaping as ps
import matplotlib.pyplot as plt
import numpy as np 
import channel
import adaptive_equaliser as ae
import receiver_rrc as recieve
import decider
import phase_recovery

np.random.seed(2)

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

# Detect polarization swap using correlation with known symbols (simulation-only diagnostic)
ref_H = symbolsH[convergence_symbols:convergence_symbols+len(equalised_x)]
ref_V = symbolsV[convergence_symbols:convergence_symbols+len(equalised_y)]

corr_x_H = np.abs(np.vdot(equalised_x, ref_H))
corr_x_V = np.abs(np.vdot(equalised_x, ref_V))

if corr_x_V > corr_x_H:
    # output_x is actually V and output_y is actually H -> swap them
    equalised_x, equalised_y = equalised_y, equalised_x
    print("Polarization swap detected and corrected")
else:
    print("No swap detected")

# Diagnostic: check if CMA has actually separated the two polarizations
corr_x_H = np.abs(np.vdot(equalised_x, symbolsH[convergence_symbols:convergence_symbols+len(equalised_x)]))
corr_x_V = np.abs(np.vdot(equalised_x, symbolsV[convergence_symbols:convergence_symbols+len(equalised_x)]))
corr_y_H = np.abs(np.vdot(equalised_y, symbolsH[convergence_symbols:convergence_symbols+len(equalised_y)]))
corr_y_V = np.abs(np.vdot(equalised_y, symbolsV[convergence_symbols:convergence_symbols+len(equalised_y)]))

print("output_x correlation -> H:", corr_x_H, " V:", corr_x_V)
print("output_y correlation -> H:", corr_y_H, " V:", corr_y_V)

equalised_x, theta_x = phase_recovery.bps_phase_recovery(equalised_x, constellation, N=25, B=64)
equalised_y, theta_y = phase_recovery.bps_phase_recovery(equalised_y, constellation, N=25, B=64)

# Reference symbols, no shift (confirmed correct alignment for this architecture)
txH_ref = symbolsH[convergence_symbols : convergence_symbols + len(equalised_x)]
txV_ref = symbolsV[convergence_symbols : convergence_symbols + len(equalised_y)]

# Resolve residual 90-deg-multiple ambiguity left over after BPS (simulation-only)
equalised_x, rot_x, ser_acc_x = phase_recovery.resolve_residual_ambiguity(equalised_x, constellation, txH_ref)
equalised_y, rot_y, ser_acc_y = phase_recovery.resolve_residual_ambiguity(equalised_y, constellation, txV_ref)
print("Residual rotation applied (X, Y):", rot_x, rot_y)

# Decision device
decided_symbolsX, decision_indexX = decider.symbol_decision(equalised_x, constellation)
decided_symbolsY, decision_indexY = decider.symbol_decision(equalised_y, constellation)

# SER check (symbol-level correctness, isolates equalizer+phase-recovery from demapper)
ser_x = decider.symbol_error_rate(txH_ref, decided_symbolsX)
ser_y = decider.symbol_error_rate(txV_ref, decided_symbolsY)
print("SER X:", ser_x, " SER Y:", ser_y)

# Demapper + BER (unchanged)
rx_bits_H = decider.qpsk_demapper(decision_indexX)
rx_bits_V = decider.qpsk_demapper(decision_indexY)

tx_bits = np.concatenate((tx_bits_H[convergence_symbols*2:], tx_bits_V[convergence_symbols*2:]))
rx_bits = np.concatenate((rx_bits_H, rx_bits_V))

ber = decider.bit_error_rate(tx_bits, rx_bits)
print("BER:", ber)



# # Version A: no shift
# txH_ref_noshift = symbolsH[convergence_symbols : convergence_symbols + len(equalised_x)]


# for rot in [1, 1j, -1, -1j]:
#     acc = np.mean(decider.symbol_decision(equalised_x * rot, constellation)[0] == txH_ref_noshift)
#     print("without shift ",rot, acc)


# plt.figure()
# plt.plot(np.degrees(phase_trend), marker='o')
# plt.xlabel("Block index")
# plt.ylabel("Mean phase error (deg)")
# plt.title("Phase drift across equalized signal")
# plt.grid(True)
# plt.show()

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

# plt.show()


