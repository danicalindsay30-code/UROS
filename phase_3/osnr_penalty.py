import sys, os
import numpy as np 
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'experiments'))
from pipeline import run_pipeline


TARGET_BER = 1e-3
OSNR_range = np.arange(8, 22, 1)  # adjust range so target BER falls inside it

def find_osnr_at_target(total_bits=None, frac_bits=None, seed=1):
    bers = []
    for osnr in OSNR_range:
        kwargs = {"OSNR_dB": osnr, "seed": seed}
        if total_bits is not None:
            kwargs["total_bits"] = total_bits
            kwargs["frac_bits"] = frac_bits
        r = run_pipeline(**kwargs)
        bers.append(r["ber"])
    bers = np.array(bers)
    # interpolate OSNR where BER crosses target (log-scale BER vs linear OSNR)
    log_ber = np.log10(bers + 1e-12)
    osnr_at_target = np.interp(np.log10(TARGET_BER), log_ber[::-1], OSNR_range[::-1])
    return osnr_at_target, bers

osnr_float, _ = find_osnr_at_target()
print(f"Floating point: OSNR @ BER=1e-3 = {osnr_float:.2f} dB")

for bits in [16, 12, 10, 8]:
    frac = bits - 2
    osnr_fixed, _ = find_osnr_at_target(total_bits=bits, frac_bits=frac)
    penalty = osnr_fixed - osnr_float
    print(f"{bits}-bit: OSNR @ BER=1e-3 = {osnr_fixed:.2f} dB, penalty = {penalty:.2f} dB")