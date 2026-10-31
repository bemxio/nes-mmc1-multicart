import os
from itertools import zip_longest

# constants
ROMS_DIR = "roms"
ENTRIES_PATH = "src/entries.asm"
DATA_PATH = "src/data.asm"

# functions
def text_to_tiles(text: str) -> list[int]:
    return [(ord(character) - 32) * 2 for character in text]

# parse ROMs inside directory
entries = {}

for filename in sorted(os.listdir(ROMS_DIR)):
    if not filename.endswith(".nes"):
        continue

    path = f"{ROMS_DIR}/{filename}"

    with open(path, "rb") as file:
        header = file.read(16)

    if header[:4] != b"NES\x1a":
        print(f"Warning: \"{filename}\" is not a valid NES ROM. Skipping.")
        continue

    if (header[7] & 0xf0) | (header[6] >> 4) != 0:
        print(f"Warning: \"{filename}\" uses a mapper other than NROM. Skipping.")
        continue

    try:
        title = filename[:filename.index("(") - 1]
    except ValueError:
        print(f"Warning: \"{filename}\" doesn't follow the No-Intro naming convention. Using filename as title instead.")
        title = filename.removesuffix(".nes")

    label = "".join(filter(lambda c: c.isalnum() or c in "_", title.lower().replace(" ", "_")))
    flags = (1 << 3) | (header[6] ^ 0x01) + 2 # switchable lower 16 KiB bank and nametable arrangement

    entries[label] = {
        "title": title,
        "path": path,
        "flags": flags
    }

    #print(title, path, bin(flags))

# write entry titles to source file
with open(ENTRIES_PATH, "w") as file:
    file.write("entry_titles:")
    file.write("\n    ; lookup table\n")

    for label in entries.keys():
        file.write(f"    .word {label}_title\n")

    file.write("\n    ; string lengths\n")
    file.write("    title_lengths:\n")

    for previous, current in zip_longest(entries.keys(), list(entries.keys())[1:]):
        if current is None:
            file.write(f"        .byte entry_flags - {previous}_title\n")
        else:
            file.write(f"        .byte {current}_title - {previous}_title\n")

    file.write("\n    ; string data\n")

    for label, entry in entries.items():
        file.write(f"    {label}_title:\n")
        file.write(f"        .byte {", ".join(f"${value:02x}" for value in text_to_tiles(entry["title"]))} ; \"{entry["title"]}\"\n")

    file.write("\n; MMC1 control flags\n")
    file.write("entry_flags:\n")
    file.write(f"    .byte {", ".join(f"%{entry["flags"]:05b}" for entry in entries.values())}\n")

# write entry data to source file
with open(DATA_PATH, "w") as file:
    file.write("; PRG-ROM\n")

    for index, entry in enumerate(entries.values()):
        file.write(f".segment \"BANK{index}\"\n")
        file.write(f"    .incbin \"{entry["path"]}\", $10, $4000\n")

    file.write("\n; CHR-ROM\n")

    for index, (lower, upper) in enumerate(zip(list(entries.values())[::2], list(entries.values())[1::2])):
        file.write(f".segment \"BANK{index + len(entries)}\"\n")
        file.write(f"    .incbin \"{lower["path"]}\", $4010, $2000\n")
        file.write(f"    .incbin \"{upper["path"]}\", $4010, $2000\n")
