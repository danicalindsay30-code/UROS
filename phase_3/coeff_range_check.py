import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'experiments'))
from pipeline import run_pipeline

sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'cma_project'))
import numpy as np 
from transmit_rrc import RRC_filter


max_seen = 0.0
for seed in [1, 2, 3, 4, 5]:
    for dgd in [0.1, 0.5, 1.0]:
        for mu_test in [50e-5, 100e-5, 300e-5, 500e-5]:  # include larger mu to stress overshoot
            r = run_pipeline(seed=seed, DGD_spec=dgd, mu=mu_test, total_bits=32, frac_bits=24)
            max_seen = max(max_seen, r["coeff_max_mag"])

for mu_test in [50e-5, 100e-5, 300e-5, 500e-5, 1000e-5, 5000e-5]:
    mu_max = 0.0
    for seed in [1, 2, 3]:
        r = run_pipeline(seed=seed, DGD_spec=0.5, mu=mu_test, total_bits=32, frac_bits=24)
        mu_max = max(mu_max, r["coeff_max_mag"])
    print(f"mu={mu_test:.0e}  max tap magnitude = {mu_max:.4f}")

print("Worst-case CMA tap magnitude observed:", max_seen)

span = 8
sps = 2
rolloff = 0.35

g = RRC_filter(span, sps, rolloff)

print("Number of taps:", len(g))
print("Min coefficient:", np.min(g))
print("Max coefficient:", np.max(g))
print("Max absolute value:", np.max(np.abs(g)))

if np.any(np.isnan(r["coeff_max_mag"])) or np.any(np.isinf(r["coeff_max_mag"])):
    print(f"mu={mu_test}: DIVERGED (nan/inf)")