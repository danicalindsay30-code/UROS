import matplotlib.pyplot as plt

def plot(symbols, title):

    plt.figure(figsize=(6,6))
    plt.scatter(symbols.real, symbols.imag, s=10)

    plt.xlabel("In-Phase (I)")
    plt.ylabel("Quadrature (Q)")
    plt.title(title)

    plt.grid(True)
    plt.axis("equal")

    plt.show()