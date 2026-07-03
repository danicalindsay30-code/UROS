def adaptive_equalizer(input_signal, SpS, ParamDE):

    """purpose: peform symbol equalisation 
    
    parameters: 
    input signal 
    SpS -  number of samples per symbol 
    ParamDe - structure that spe"""

    #initalise the filters 
    w1V = 0 
    w1H = 0 
    w2V = 0 
    w2H = 0 

    # fir input vectors
    inputV = input_signal[:,0]
    inputH = input_signal[:,1]

    #compute equalizer outputs 
    
     
    


