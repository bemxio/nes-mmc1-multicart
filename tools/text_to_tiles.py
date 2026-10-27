text = input().strip()
invert = int(input("Invert text (y or n)? ").strip().lower() == "y")

print(".byte", ", ".join(f"${(ord(character) - 32) * 2 + invert:02x}" for character in text))