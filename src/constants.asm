; hardware registers
PPU_CTRL = $2000
PPU_MASK = $2001
PPU_STATUS = $2002
PPU_SCROLL = $2005
PPU_ADDR = $2006
PPU_DATA = $2007

OAM_ADDR = $2003
OAM_DMA = $4014

APU_DMC = $4010
APU_FRAME_COUNTER = $4017

JOY1 = $4016

MMC1_CTRL = $8000
MMC1_PRG = $E000

; memory locations
OAM_BUFFER = $0200 ; OAM buffer address in RAM

; amounts and sizes
FONT_SIZE = (font_data_end - font_data) / 256 ; size of font CHR data in pages
ENTRY_AMOUNT = (title_lengths - entry_titles) / 2 ; amount of entries in menu

; background and text colors
BACKGROUND_COLOR = $0f ; black
TEXT_COLOR = $30 ; white