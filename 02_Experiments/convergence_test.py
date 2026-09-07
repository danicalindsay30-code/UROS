import numpy as np
import matplotlib.pyplot as plt
from pipeline import run_pipeline

# representative operating point — state these explicitly in the report
mu = 1e-3
DGD_spec = 0.1
OSNR_dB = 20
num_taps = 21
R = 1

result = run_pipeline(
    mu=mu, DGD_spec=DGD_spec, OSNR_dB=OSNR_dB, num_taps=num_taps, R=R,
    seed=0, return_convergence_trace=True
)

raw_x = result["raw_x"]
raw_y = result["raw_y"]

# CMA error signal per iteration
error_x = (R - np.abs(raw_x)**2)**2
error_y = (R - np.abs(raw_y)**2)**2
error_avg = (error_x + error_y) / 2

# smooth for readability (moving average over a symbol window)
window = 50
error_smooth = np.convolve(error_avg, np.ones(window)/window, mode='valid')

plt.figure(figsize=(8,5))
plt.semilogy(error_smooth)
plt.axvline(1500, linestyle='--', color='gray', label='convergence_symbols cutoff (1500)')
plt.xlabel("Iteration index (symbols)")
plt.ylabel(r"$|e[n]|^2$ (smoothed, moving avg)")
plt.title(f"CMA Convergence — µ={mu}, DGD={DGD_spec}, OSNR={OSNR_dB}dB, taps={num_taps}")
plt.legend()
plt.grid(True, which='both')
plt.savefig("cma_convergence.png", dpi=150)
plt.show()

# quantify: find where error first drops within e.g. 10% of its final steady-state value
steady_state = np.median(error_smooth[-2000:])
threshold = steady_state * 1.1
converged_idx = np.argmax(error_smooth < threshold)
print(f"Steady-state error level: {steady_state:.3e}")
print(f"Estimated convergence point: symbol {converged_idx}")