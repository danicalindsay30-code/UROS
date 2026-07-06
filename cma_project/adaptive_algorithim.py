import numpy as np
def cma(x_window, y_window, output_x, output_y, w_xx, w_xy, w_yx, w_yy, mu, R):

    """
    This function performs the update of the filters of the MIMO butterfly 
    equalizer using the CMA algorithim 
    """

    # CMA error terms
    error_x = R - np.abs(output_x)**2
    error_y = R - np.abs(output_y)**2

    # Update filters contributing to Output X
    w_xx = w_xx + mu * x_window * error_x * np.conj(output_x)
    w_yx = w_yx + mu * y_window * error_x * np.conj(output_x)

    # Update filters contributing to Output Y
    w_xy = w_xy + mu * x_window * error_y * np.conj(output_y)
    w_yy = w_yy + mu * y_window * error_y * np.conj(output_y)

    return w_xx, w_xy, w_yx, w_yy

