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
    flags = (header[6] ^ 0x01) + 2 # nametable arrangement

    if header[4] == 1: # 16 KiB PRG-ROM
        flags |= 0x8 # fix lower bank, switch upper bank

    #print("Title:", title)
    #print("Path:", path)
    #print("Flags:", f"%{flags:05b}\n")

    entries[label] = {
        "title": title,
        "path": path,
        "flags": flags
    }

# sort entries by PRG-ROM size (16 KiB first, then 32 KiB)
sorted_entries = []

for index, entry in enumerate(sorted(entries.values(), key=lambda entry: not entry["flags"] & 0x8)):
    if not entry["flags"] & 0x8 and index % 2 != 0:
        sorted_entries.append({})

    sorted_entries.append(entry)

# write entry titles to source file
with open(ENTRIES_PATH, "w") as file:
    file.write("; menu entry titles\n")
    file.write("entry_titles:")
    file.write("\n    ; lookup table\n")

    for label in entries.keys():
        file.write(f"    .word {label}_title\n")

    file.write("\n    ; string lengths\n")
    file.write("    title_lengths:\n")

    for previous, current in zip_longest(entries.keys(), list(entries.keys())[1:]):
        if current is None:
            file.write(f"        .byte entry_banks - {previous}_title\n")
        else:
            file.write(f"        .byte {current}_title - {previous}_title\n")

    file.write("\n    ; string data\n")

    for label, entry in entries.items():
        file.write(f"    {label}_title:\n")
        file.write(f"        .byte {", ".join(f"${value:02x}" for value in text_to_tiles(entry["title"]))} ; \"{entry["title"]}\"\n")

    file.write("\n; entry bank numbers\n")
    file.write("entry_banks:\n")
    file.write(f"    .byte {", ".join(str(sorted_entries.index(entry)) for entry in entries.values())}\n")

    file.write("\n; MMC1 control flags\n")
    file.write("entry_flags:\n")
    file.write(f"    .byte {", ".join(f"%{entry["flags"]:05b}" for entry in entries.values())}\n")

# write entry data to source file
bank_index = 0

with open(DATA_PATH, "w") as file:
    file.write("; PRG-ROM\n")

    for entry in sorted_entries:
        file.write(f".segment \"BANK{bank_index}\"\n")

        if not entry:
            bank_index += 1
            continue

        file.write(f"    .incbin \"{entry["path"]}\", $10, $4000\n")

        if not entry["flags"] & 0x8: # 32 KiB PRG-ROM
            bank_index += 1

            file.write(f".segment \"BANK{bank_index}\"\n")
            file.write(f"    .incbin \"{entry["path"]}\", $4010, $4000\n")

        bank_index += 1

    file.write("\n; CHR-ROM\n")

    for lower, upper in zip_longest(list(entries.values())[::2], list(entries.values())[1::2]):
        file.write(f".segment \"BANK{bank_index}\"\n")
        file.write(f"    .incbin \"{lower["path"]}\", ${4010 if lower["flags"] & 0x8 else 8010}, $2000\n")

        if upper is not None:
            file.write(f"    .incbin \"{upper["path"]}\", ${4010 if upper["flags"] & 0x8 else 8010}, $2000\n")

        bank_index += 1