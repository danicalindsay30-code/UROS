import numpy as np
import matplotlib.pyplot as plt
from pipeline import run_pipeline   # adjust import to match your actual filename

# timing_check.py
import time
from pipeline import run_pipeline

t0 = time.time()
run_pipeline(mu=1e-3, seed=0)
print("single run took", time.time() - t0, "s")

mu_values = [5e-5, 1e-4, 5e-4, 1e-3, 3e-3, 5e-3, 8e-3, 1e-2]
ber_results = []

for mu in mu_values:
    result = run_pipeline(mu=mu, seed=0)   # fixed seed = fair comparison across mu
    print(f"mu={mu:.1e}  BER={result['ber']:.5e}  swapped={result['swapped']}")
    ber_results.append(result['ber'])

plt.figure(figsize=(7,5))
plt.semilogy(mu_values, ber_results, marker='o')
plt.xscale('log')
plt.xlabel("CMA step size (µ)")
plt.ylabel("BER")
plt.title("BER vs. CMA Step Size")
plt.grid(True, which='both')
plt.savefig("ber_vs_mu.png", dpi=150)
plt.show()