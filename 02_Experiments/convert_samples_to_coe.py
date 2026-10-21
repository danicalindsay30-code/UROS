INPUT_FILE = r"C:\dev\UROS\03_Data\MF_input_samples.txt"
OUTPUT_FILE = r"C:\dev\UROS\03_Data\MF_input_samples.mem"


def to_uint8(value):
    """
    Convert a signed integer into its 8-bit two's complement
    representation.
    """
    return value & 0xFF


with open(INPUT_FILE, "r") as infile, open(OUTPUT_FILE, "w") as outfile:

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

        # Pack as Qy, Iy, Qx, Ix from most significant to least significant byte
        word = (
            (Qy_8 << 24)
            | (Iy_8 << 16)
            | (Qx_8 << 8)
            | Ix_8
        )

        words.append(f"{word:08X}")

    # Pad with zero words until there are exactly 128 lines
    while len(words) < 128:
        words.append("00000000")

    if len(words) > 128:
        raise ValueError(
            f"Input contains {len(words)} samples, which exceeds 128 lines."
        )

    # Write one hex value per line
    for word in words:
        outfile.write(f"{word}\n")


print(f"Successfully converted and padded {len(words)} samples.")
print(f"Output written to: {OUTPUT_FILE}")