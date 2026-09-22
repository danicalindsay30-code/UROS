INPUT_FILE = "MF_input_samples.txt"
OUTPUT_FILE = "MF_input_samples.coe"


def to_uint8(value):
    """
    Convert a signed integer into its 8-bit two's complement
    representation.
    """
    return value & 0xFF


with open(INPUT_FILE, "r") as infile, open(OUTPUT_FILE, "w") as outfile:

    # COE header
    outfile.write("memory_initialization_radix=16;\n")
    outfile.write("memory_initialization_vector=\n")

    words = []

    for line_number, line in enumerate(infile, start=1):

    
        if not line.strip():
            continue

        
        values = line.split()

        if len(values) != 4:
            raise ValueError(
                f"Line {line_number} does not contain exactly four values."
            )

        Ix, Qx, Iy, Qy = map(int, values)

      
        Ix_8 = to_uint8(Ix)
        Qx_8 = to_uint8(Qx)
        Iy_8 = to_uint8(Iy)
        Qy_8 = to_uint8(Qy)

        word = (
            (Qy_8 << 24)
            | (Iy_8 << 16)
            | (Qx_8 << 8)
            | Ix_8
        )

  
        words.append(f"{word:08X}")


    for index, word in enumerate(words):

        if index == len(words) - 1:
            outfile.write(f"{word};\n")
        else:
            outfile.write(f"{word},\n")


print(f"Successfully converted {len(words)} samples.")
print(f"Output written to: {OUTPUT_FILE}")