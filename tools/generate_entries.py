import os
from itertools import zip_longest

# constants
ROMS_DIR = "roms"
TITLES_PATH = "src/titles.asm"
DATA_PATH = "src/data.asm"

# functions
def text_to_tiles(text: str) -> list[int]:
    return [(ord(character) - 32) * 2 for character in text]

# parse ROMs inside directory
entries = {}

for filename in sorted(os.listdir(ROMS_DIR)):
    if not filename.endswith(".nes"):
        continue

    title = filename[:filename.find("(") - 1]
    label = "".join(filter(lambda c: c.isalnum() or c in "_", title.lower().replace(" ", "_")))

    entries[label] = {"title": title, "path": f"{ROMS_DIR}/{filename}"}

print(entries)

# write entry titles to source file
with open(TITLES_PATH, "w") as file:
    file.write("entry_titles:")
    file.write("\n    ; lookup table\n")

    for label in entries.keys():
        file.write(f"    .word {label}_title\n")

    file.write("\n    ; string lengths\n")
    file.write("    title_lengths:\n")

    for previous, current in zip_longest(entries.keys(), list(entries.keys())[1:]):
        if current is None:
            file.write(f"        .byte entry_titles_end - {previous}_title\n")
        else:
            file.write(f"        .byte {current}_title - {previous}_title\n")

    file.write("\n    ; string data\n")

    for label, entry in entries.items():
        file.write(f"    {label}_title:\n")
        file.write(f"        .byte {", ".join(f"${value:02x}" for value in text_to_tiles(entry["title"]))} ; \"{entry["title"]}\"\n")

    file.write("entry_titles_end:\n")

# write entry data to source file
with open(DATA_PATH, "w") as file:
    file.write("; PRG-ROM\n")

    for index, entry in enumerate(entries.values()):
        file.write(f".segment \"BANK{index}\"\n")
        file.write(f"    .incbin \"{entry["path"]}\", $10, $4000\n")

    file.write("\n; CHR-ROM\n")

    for index, (lower, upper) in enumerate(zip(list(entries.values())[::2], list(entries.values())[1::2])):
        print(index, lower, upper)

        file.write(f".segment \"BANK{index + len(entries)}\"\n")
        file.write(f"    .incbin \"{lower["path"]}\", $4010, $2000\n")
        file.write(f"    .incbin \"{upper["path"]}\", $4010, $2000\n")
