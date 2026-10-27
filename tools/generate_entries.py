import json

def text_to_tiles(text: str) -> list[int]:
    return [(ord(character) - 32) * 2 for character in text]

with open("roms/entries.json", "r") as file:
    entries = json.load(file)

with open("roms/titles.asm", "w") as file:
    file.write("entry_titles:")
    file.write("\n    ; lookup table\n")

    for entry in entries:
        file.write(f"    .word {entry["id"]}_title\n")

    file.write("\n    ; string lengths\n")
    file.write("    title_lengths:\n")

    for index in range(len(entries)):
        if index == len(entries) - 1:
            file.write(f"        .byte entry_titles_end - {entries[index]["id"]}_title\n")
        else:
            file.write(f"        .byte {entries[index + 1]["id"]}_title - {entries[index]["id"]}_title\n")

    file.write("\n    ; string data\n")

    for entry in entries:
        file.write(f"    {entry["id"]}_title:\n")
        file.write(f"        .byte {", ".join(f"${value:02x}" for value in text_to_tiles(entry["name"]))} ; \"{entry["name"]}\"\n")

    file.write("entry_titles_end:\n")

with open("roms/banks.asm", "w") as file:
    file.write("; PRG-ROM\n")

    for index, entry in enumerate(entries):
        file.write(f".segment \"BANK{index}\"\n")
        file.write(f"    .incbin \"../roms/{entry["id"]}.nes\", $10, $4000\n")

    file.write("\n; CHR-ROM\n")

    for index in range(0, len(entries), 2):
        file.write(f".segment \"BANK{index // 2 + len(entries)}\"\n")
        file.write(f"    .incbin \"../roms/{entries[index]["id"]}.nes\", $4010, $2000\n")
        file.write(f"    .incbin \"../roms/{entries[index + 1]["id"]}.nes\", $4010, $2000\n")
