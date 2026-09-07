import numpy as np

def quantize(x, total_bits, frac_bits, signed=True):
    """
    Simulates fixed-point quantization (Q-format) of a real or complex array.
    total_bits: total word length (e.g. 16, 12, 10, 8)
    frac_bits: number of fractional bits (integer bits = total_bits - frac_bits [- 1 if signed])
    """
    scale = 2 ** frac_bits

    if signed:
        qmin = -(2 ** (total_bits - 1))
        qmax = (2 ** (total_bits - 1)) - 1
    else:
        qmin = 0
        qmax = (2 ** total_bits) - 1

    def quantize_real(arr):
        scaled = np.round(arr * scale)          # round to nearest quantization step
        clipped = np.clip(scaled, qmin, qmax)     # saturate on overflow
        return clipped / scale

    if np.iscomplexobj(x):
        return quantize_real(x.real) + 1j * quantize_real(x.imag)
    else:
        return quantize_real(x)
    
    
x = np.array([0.73246198, -1.9, 2.5, 0.001])
print(quantize(x, total_bits=8, frac_bits=6))
# should show rounding to nearest 1/64 = 0.015625, and clipping the values that don't fit