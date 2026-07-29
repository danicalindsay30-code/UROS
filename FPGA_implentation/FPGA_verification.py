import numpy as np

import numpy as np
import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'cma_project'))


import generate_qpsk as qk
import pulse_shaping as ps
import channel
import adaptive_equaliser as ae
import receiver_rrc as recieve


num_symbols=10000,
span=8,
sps=2,
rolloff=0.35,
R=1,
Rs=32e9,
OSNR_dB=20,
B_ref=12.5e9,
DGD_spec=0.1,
num_sections=20,
fiber_length=80e3,

np.random.seed(1)

tx_bits_H, symbolsH = qk.generate_qpsk(num_symbols)
tx_bits_V, symbolsV = qk.generate_qpsk(num_symbols)

txH = ps.pulse_shaping(symbolsH, sps, span, rolloff)
txV = ps.pulse_shaping(symbolsV, sps, span, rolloff)
Einput = np.column_stack((txH, txV))

E_pmd = channel.PMDInsertion(Einput, DGD_spec, num_sections, fiber_length, Rs, sps)
E_noise = channel.noise_insertion_osnr(E_pmd, OSNR_dB, sps, 2, Rs, B_ref)

np.savetxt("input_samples.txt", E_noise, fmt="%d")
