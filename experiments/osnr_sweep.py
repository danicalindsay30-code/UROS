import numpy as np
from scipy.special import erfc
import matplotlib.pyplot as plt

Rs = 32e9
B_ref = 12.5e9
bits_per_symbol = 2      # QPSK
num_polarisations = 2    # matches your pipeline default

osnr_values = np.array([8, 10, 12, 14, 16, 18, 20, 22, 25])
ber_measured = np.array([4.05098e-01, 7.80825e-02, 1.01392e-02, 1.57216e-03,
                          1.95876e-04, 1.08247e-04, 9.79381e-05, 9.79381e-05, 9.79381e-05])

osnr_linear = 10**(osnr_values / 10)

# reproduce the function's own SNR_linear exactly
SNR_linear = ((2 * B_ref) / (num_polarisations * Rs)) * osnr_linear   # = Es/N0 per pol
EbN0_linear = SNR_linear / bits_per_symbol

ber_theory = 0.5 * erfc(np.sqrt(EbN0_linear))

plt.figure(figsize=(7,5))
plt.semilogy(osnr_values, ber_measured, marker='o', label='Simulated')
plt.semilogy(osnr_values, ber_theory, linestyle='--', marker='s', label='Theoretical QPSK bound')
plt.axhline(1e-3, linestyle=':', color='gray', label='BER = 1e-3 reference')
plt.xlabel("OSNR (dB)")
plt.ylabel("BER")
plt.title("BER vs. OSNR — Simulated vs. Theoretical")
plt.legend()
plt.grid(True, which='both')
plt.ylim(1e-6, 1)
plt.savefig("ber_vs_osnr_theory.png", dpi=150)
plt.show()

def osnr_at_ber(osnr_arr, ber_arr, target_ber):
    log_ber = np.log10(ber_arr)
    return np.interp(np.log10(target_ber), log_ber[::-1], osnr_arr[::-1])

osnr_sim_at_1e3 = osnr_at_ber(osnr_values, ber_measured, 1e-3)
osnr_theory_at_1e3 = osnr_at_ber(osnr_values, ber_theory, 1e-3)
penalty_dB = osnr_sim_at_1e3 - osnr_theory_at_1e3

print(f"OSNR at BER=1e-3 (simulated):   {osnr_sim_at_1e3:.2f} dB")
print(f"OSNR at BER=1e-3 (theoretical): {osnr_theory_at_1e3:.2f} dB")
print(f"Implementation penalty:         {penalty_dB:.2f} dB")