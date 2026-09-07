import numpy as np
import matplotlib.pyplot as plt
from pipeline import run_pipeline

taps_values = [7, 11, 15, 21, 27, 33, 41]

# use the highest DGD_spec value from your DGD sweep here
high_dgd = 1.0   # <-- replace with your actual highest tested value

ber_default_dgd = []
ber_high_dgd = []

for taps in taps_values:
    r_default = run_pipeline(num_taps=taps, seed=0)                 # DGD_spec=0.1 (default)
    r_high    = run_pipeline(num_taps=taps, DGD_spec=high_dgd, seed=0)

    print(f"taps={taps}  BER(default DGD)={r_default['ber']:.5e}  "
          f"BER(DGD={high_dgd})={r_high['ber']:.5e}")

    ber_default_dgd.append(r_default['ber'])
    ber_high_dgd.append(r_high['ber'])

plt.figure(figsize=(7,5))
plt.semilogy(taps_values, ber_default_dgd, marker='o', label=f'DGD_spec=0.1 (default)')
plt.semilogy(taps_values, ber_high_dgd, marker='s', label=f'DGD_spec={high_dgd} (high)')
plt.xlabel("Number of equalizer taps")
plt.ylabel("BER")
plt.title("BER vs. Tap Count at Two DGD Conditions")
plt.legend()
plt.grid(True, which='both')
plt.savefig("ber_vs_taps_dgd_comparison.png", dpi=150)
plt.show()