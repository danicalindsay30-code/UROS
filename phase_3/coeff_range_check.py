import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'experiments'))
from pipeline import run_pipeline

sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'cma_project'))
import numpy as np 
from transmit_rrc import RRC_filter


max_seen = 0.0
worst_seed = None 
worst_mu = None 
dgd = 1 

for seed in [1, 2, 3]:
    for mu_test in [50e-5, 100e-5, 300e-5, 500e-5]:  # include larger mu to stress overshoot
        r = run_pipeline(seed=seed, DGD_spec=dgd, mu=mu_test, total_bits=32, frac_bits=24)
        if r["coeff_max_mag"] > max_seen:
            max_seen = r["coeff_max_mag"]
            worst_seed = seed
            worst_mu = mu_test

print(f"Worst-case CMA tap magnitude observed: {max_seen:.4f}")
print(f"Occurred for seed={worst_seed}, mu={worst_mu}")

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