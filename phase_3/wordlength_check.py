import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'experiments'))
from pipeline import run_pipeline

OSNR_TEST = 15  # pick a value where float BER is near 1e-3

float_result = run_pipeline(OSNR_dB=OSNR_TEST, seed=1)
print(f"Floating point   BER = {float_result['ber']:.2e}")

for bits in [16, 12, 10, 8]:
    frac = bits - 2
    r = run_pipeline(OSNR_dB=OSNR_TEST, seed=1, total_bits=bits, frac_bits=frac)
    print(f"{bits}-bit (frac={frac})  BER = {r['ber']:.2e}")