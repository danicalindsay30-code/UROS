import numpy as np 
import adaptive_algorithim as alg

def adaptive_equalizer(input_signal, num_taps, mu,R):

    """purpose: peform symbol equalisation 
    
    parameters: 
    input signal: nd array
    complex recieves signal with shape (N,2)
    coloumn 0 is one polarisation, coloumn 1 is the other

    num_taps: int 
    number of samples per symbol 
    must be odd 
    
    mu : float 
     learning rate controlling coefficient updates
      
    return:
      """
    
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

   
    #main processing loop 
    #ignore the edges of the input untill a complete window is seen 


    for n in range(centre, len(input_x)-centre) :
         # Extract windows
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

        



        w_xx, w_xy, w_yx, w_yy = alg.cma(x_window,y_window,output_x[n],output_y[n],w_xx,w_xy,w_yx,w_yy,mu,R)
    
 

    return output_x, output_y



   
    
     
    

