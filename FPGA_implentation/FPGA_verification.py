import numpy as np

input_sequence = np.array([1,2,3,4,5,6,7,8,9,10],dtype=int )
np.savetxt("input_samples.txt", input_sequence, fmt="%d")
coeff = np.array([0,1,-2,2,5,-12,-8,55,99,55,-8,-12,5,2,-2,1,0])

expected = np.convolve(input_sequence, coeff)

print(expected)