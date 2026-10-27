CHARSET = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"'(),./?"

text = input().strip()
invert = int(input("Invert text (y or n)? ").strip().lower() == "y")

print(".byte", ", ".join(f"${CHARSET.index(character) * 2 + invert:02x}" for character in text))