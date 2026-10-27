# constants
AS = ca65
ASFLAGS = -t nes -g

LD = ld65
LDFLAGS = -C linker.cfg --dbgfile $(BUILD_DIR)/$(FILENAME).dbg --mapfile $(BUILD_DIR)/$(FILENAME).map

SRC_DIR = src
ASSETS_DIR = assets
BUILD_DIR = build

SOURCES = $(wildcard $(SRC_DIR)/*.asm)
ASSETS = $(wildcard $(ASSETS_DIR)/*)

FILENAME = mmc1-multicart

# phony
.PHONY: all clean run

# targets
all: $(BUILD_DIR)/$(FILENAME).nes

clean:
	$(RM) -r $(BUILD_DIR)

run: $(BUILD_DIR)/$(FILENAME).nes
	mesen $<

run-fceux: $(BUILD_DIR)/$(FILENAME).nes
	fceux $<

# rules
$(BUILD_DIR)/$(FILENAME).nes: $(BUILD_DIR)/main.o $(SOURCES) $(ASSETS)
	$(LD) $(LDFLAGS) $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm | $(BUILD_DIR)
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR):
	mkdir -p $@