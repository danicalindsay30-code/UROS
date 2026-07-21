import os, sys
import numpy as np
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'cma_project'))
import adaptive_algorithim as alg
import quantisie as q


def adaptive_equalizer_quantized(input_signal, num_taps, mu, R, total_bits, frac_bits):
    if num_taps % 2 == 0:
        raise ValueError("num_taps must be odd")

    input_x = input_signal[:, 0]
    input_y = input_signal[:, 1]

    w_xx = np.zeros(num_taps, dtype=complex)
    w_xy = np.zeros(num_taps, dtype=complex)
    w_yx = np.zeros(num_taps, dtype=complex)
    w_yy = np.zeros(num_taps, dtype=complex)

    centre = num_taps // 2
    w_xx[centre] = 1
    w_yy[centre] = 1

    output_x = np.zeros(len(input_x), dtype=complex)
    output_y = np.zeros(len(input_y), dtype=complex)

    coeff_max_mag = 0.0  # for Section 4.2 later

    for n in range(centre, len(input_x) - centre):
        x_window = input_x[n - centre: n + centre + 1]
        y_window = input_y[n - centre: n + centre + 1]

        equalised_xx = np.vdot(w_xx, x_window)
        equalised_xy = np.vdot(w_xy, x_window)
        equalised_yx = np.vdot(w_yx, y_window)
        equalised_yy = np.vdot(w_yy, y_window)

        out_x = equalised_xx + equalised_yx
        out_y = equalised_xy + equalised_yy

        out_x = q.quantize(out_x, total_bits, frac_bits)
        out_y = q.quantize(out_y, total_bits, frac_bits)
        output_x[n] = out_x
        output_y[n] = out_y

        w_xx, w_xy, w_yx, w_yy = alg.cma(
            x_window, y_window, out_x, out_y, w_xx, w_xy, w_yx, w_yy, mu, R
        )

        w_xx = q.quantize(w_xx, total_bits, frac_bits)
        w_xy = q.quantize(w_xy, total_bits, frac_bits)
        w_yx = q.quantize(w_yx, total_bits, frac_bits)
        w_yy = q.quantize(w_yy, total_bits, frac_bits)

        current_max = max(np.max(np.abs(w_xx)), np.max(np.abs(w_xy)),
                           np.max(np.abs(w_yx)), np.max(np.abs(w_yy)))
        coeff_max_mag = max(coeff_max_mag, current_max)

    return output_x, output_y, coeff_max_mag