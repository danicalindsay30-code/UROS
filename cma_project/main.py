import generate_qpsk as qk
import pulse_shaping as ps
import matplotlib.pyplot as plt
import numpy as np 
import channel

#singular-polarisation single 
bitsH, symbolsH = qk.generate_qpsk(100)
bitsV, symbolsV = qk.generate_qpsk(100)

# RRC parameters
span = 8
sps = 8
rolloff = 0.35


rrc = ps.RRC_filter(span, sps, rolloff)


tx_signalH = ps.pulse_shaping(symbolsH, sps, span, rolloff)
tx_signalV = ps.pulse_shaping(symbolsV, sps, span, rolloff)
tx_signal = np.column_stack((tx_signalH, tx_signalV))

pmd_signal = channel.PMDInsertion(tx_signal,0,10, 80e3,32e9,8)




# plt.figure()
# plt.title("Root Raised Cosine Filter")
# plt.plot(rrc)
# plt.grid()

# plt.figure()
# plt.title("Pulse Shaped Signal")
# plt.plot(tx_signal.real)
# plt.grid()

# plt.show()