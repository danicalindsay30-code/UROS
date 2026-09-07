import numpy as np

data = np.loadtxt("input_samples.txt", dtype=np.int16)

x_real = data[:, 0]
x_imag = data[:, 1]
y_real = data[:, 2]
y_imag = data[:, 3]

taps = np.array([
    0, 1, -2, 2, 5, -12, -8, 55, 99,
    55, -8, -12, 5, 2, -2, 1, 0
], dtype=np.int16)


def fir_reference(signal):
    accumulator = np.convolve(
        signal.astype(np.int64),
        taps.astype(np.int64),
        mode="full"
    )

    # Same operation as:
    # sample_out = accumulator >>> 7;
    return accumulator >> 7


python_x_real = fir_reference(x_real)
python_x_imag = fir_reference(x_imag)
python_y_real = fir_reference(y_real)
python_y_imag = fir_reference(y_imag)

print("First 20 Python outputs:")
print("X real:", python_x_real[:20])
print("X imag:", python_x_imag[:20])
print("Y real:", python_y_real[:20])
print("Y imag:", python_y_imag[:20])