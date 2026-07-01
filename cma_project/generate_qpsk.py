import numpy as np

def generate_qpsk(num_symbols):
    """ Purpose: Generate a sequence of bits with uniform distribution,
    and generates a sequence of symbols based on the modulation format. 
    
    parameter: number of sympols 
    return: sequence of bits and a sequence of symbols"""

    bit_stream = np.random.randint(0, 2, size = (num_symbols*2))

    # Each point is normalised to ensure the magnitude of each constellation is the same
    qpsk_mapper = {(0,0): 1/np.sqrt(2)*(1 + 1j),
                     (0,1):1/np.sqrt(2)*(-1 + 1j),
                     (1,1):1/np.sqrt(2)*(-1-1J), 
                     (1,0): 1/np.sqrt(2)*(1 - 1j)}
    
    symbol_stream = []
    
    for i in range(0, len(bit_stream),2):
        bit_pair = (bit_stream[i],bit_stream[i+1])
        symbol = qpsk_mapper[bit_pair]
        symbol_stream.append(symbol)
    
    symbol_stream = np.array(symbol_stream)
  
    return bit_stream, symbol_stream


