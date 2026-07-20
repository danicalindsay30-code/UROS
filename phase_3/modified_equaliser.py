import os
import sys
import numpy as np
import quantisie as q
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'cma_project'))

import adaptive_equaliser as ae

def adaptive_equalizer_quantized(input_signal, num_taps, mu, R, total_bits, frac_bits, SpS=1, N1=500):
    if num_taps %2 ==0:
        raise ValueError("num_taps must be odd ")

    # fir input vectors, seperating the polarisations
    input_x = input_signal[:,0]
    input_y = input_signal[:,1]

    #initalise the filters 
    w_xx = np.zeros(num_taps,dtype= complex) #recievedx, outputx  
    w_xy = np.zeros(num_taps,dtype= complex) #recieved x at output y 
    w_yx = np.zeros(num_taps,dtype= complex) # recieved y at output x 
    w_yy = np.zeros(num_taps,dtype= complex)#recieved x at output x 

    #initialise the centre taps 
    #only straight through filters should start at 1 
    centre = num_taps // 2
    w_xx[centre] = 1
    w_yy[centre]=1


    #initialise the outouts 
    output_x = np.zeros(len(input_x), dtype=complex)
    output_y = np.zeros(len(input_y), dtype=complex)

    for n in range(centre, len(input_x)-centre):
        # ... compute windows, outputs as normal ...
        x_window = input_x[n-centre : n+centre+1]
        y_window = input_y[n-centre : n+centre+1]


        # Four FIR filters

        # Received X -> Output X
        equalised_xx = np.vdot( w_xx, x_window)
        # Received X -> Output Y
        equalised_xy = np.vdot(w_xy, x_window )

        # Received Y -> Output X
        equalised_yx = np.vdot( w_yx, y_window )

        # Received Y -> Output Y
        equalised_yy = np.vdot( w_yy, y_window )

        # Combine contributions
        output_x[n] = equalised_xx + equalised_yx
        output_y[n] = equalised_xy + equalised_yy

        output_x[n] = q.quantize(output_x[n], total_bits, frac_bits)
        output_y[n] = q.quantize(output_y[n], total_bits, frac_bits)

        w_xx, w_xy, w_yx, w_yy = ae.cma(x_window, y_window, output_x, output_y, w_xx, w_xy, w_yx, w_yy, mu, R)

        # quantize taps after every update — this is the key step
        w_xx = q.quantize(w_xx, total_bits, frac_bits)
        w_xy = q.quantize(w_xy, total_bits, frac_bits)
        w_yx = q.quantize(w_yx, total_bits, frac_bits)
        w_yy = q.quantize(w_yy, total_bits, frac_bits)

        if n == N1:
            w_yx = np.conj(w_xy[::-1])
            w_yy = -np.conj(w_xx[::-1])

    return output_x, output_y