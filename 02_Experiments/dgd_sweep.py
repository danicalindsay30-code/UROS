import numpy as np
import pandas as pd
from pipeline import run_pipeline

DGD_values = np.linspace(0.01, 1.0, 15)   # sweep range, adjust as needed
seeds = [1, 2, 3, 4, 5]                    # multiple seeds per point to average out convergence variance

results = []

for dgd in DGD_values:
    for seed in seeds:
        res = run_pipeline(DGD_spec=dgd, seed=seed)
        results.append(res)
        print(f"DGD={dgd:.3f}  seed={seed}  BER={res['ber']:.2e}  swapped={res['swapped']}")

df = pd.DataFrame(results)
df.to_csv("results/dgd_sweep.csv", index=False)

# Aggregate: mean/std BER per DGD value across seeds
summary = df.groupby("DGD_spec")["ber"].agg(["mean", "std", "min", "max"]).reset_index()
print(summary)

import matplotlib.pyplot as plt
plt.figure()
plt.errorbar(summary["DGD_spec"], summary["mean"], yerr=summary["std"], marker='o', capsize=3)
plt.yscale("log")
plt.xlabel("DGD (ps/√km)")
plt.ylabel("BER")
plt.title("BER vs DGD")
plt.grid(True, which="both")
plt.savefig("results/dgd_sweep.png")
plt.show()