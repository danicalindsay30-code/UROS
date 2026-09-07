import numpy as np 
imag_array = np.array([
        (1 + 1j), (-1 + 1j), (-1 - 1j), (1 - 1j)
    ])

print(np.real(imag_array))
for i in imag_array:
    print(np.real(i),np.imag(i))
