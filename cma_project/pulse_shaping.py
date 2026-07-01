import numpy as np 
from scipy import signal 

def RRC_filter(sps,Ts, beta,num_taps,symbol_stream ):
    """
    Purpose:

    parameters:
    sps: samples per symbol 
    Ts: Symbol period 
    beta: roll-of factor 
    num_taps: coefficient describing the pulse shape 
    symbol_stream

    Return: 
    """
    #sps - number of samples per symbol
    # generating the impulse response - through upsampling
    #upsampling - creates a sequence of impulses for the RRC filter 

    upsampled_signal = np.zeros((len(symbol_stream)*sps),dtype = complex)
    upsampled_signal[::sps] = symbol_stream
        
    #create the RRC filter
    t = np.arange(num_taps) - (num_taps-1)//2
    rrc_signal = np.sinc(t/Ts) * np.cos(np.pi*beta*t/Ts) / (1 - (2*beta*t/Ts)**2)
    # convolution of the RRC signal with the impulse signal produces the final signal 
    Filtered_signal = np.convolve(upsampled_signal,rrc_signal,mode= "same")
    


    return Filtered_signal,t