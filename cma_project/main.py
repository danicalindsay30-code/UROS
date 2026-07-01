import generate_qpsk as qk
import pulse_shaping as ps
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal 


bitsH, symbolsH = qk.generate_qpsk(100)
bitsV, symbolsV = qk.generate_qpsk(100)

# dual-polarization transmitted signal.
# column 0 = horizontal polarization
# column 1 = vertical polarization

dual_signal = np.column_stack((symbolsH, symbolsV)) 
one_signal,t = ps.RRC_filter(8, 8, 0.35,101,symbolsH)

plt.figure()
plt.plot(t,one_signal,'.')
plt.grid()
plt.show()








