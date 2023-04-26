
# default target
default: compile

# commands and tools
include config.makefile

# packer; must match the included unpacker routine
PACK_EXTENSION=zx0

#
# paths and file lists
#

ROM=\
	games\minigames\run23\run23.rom

SYM=\
	games\minigames\run23\run23.sym

DATAS=\
	games\minigames\run23\charset.png.chr.$(PACK_EXTENSION) \
	games\minigames\run23\charset.png.clr.$(PACK_EXTENSION) \
	games\minigames\run23\screen.tmx.bin.$(PACK_EXTENSION) \
	games\minigames\run23\sprites.png.spr.$(PACK_EXTENSION) \
	games\minigames\run23\music\empty.pt3.hl.$(PACK_EXTENSION) \
	games\minigames\run23\music\RUN23_ShuffleOne.pt3.hl.$(PACK_EXTENSION) \
	games\minigames\run23\music\RUN23_YouWin1.pt3.hl.$(PACK_EXTENSION) \
	games\minigames\run23\music\run23.afb


DATAS_INTERMEDIATE=\
	games\minigames\run23\charset.png.chr \
	games\minigames\run23\charset.png.clr \
	games\minigames\run23\screen.tmx.bin \
	games\minigames\run23\music\empty.pt3.hl \
	games\minigames\run23\music\RUN23_ShuffleOne.pt3.hl \
	games\minigames\run23\music\RUN23_YouWin1.pt3.hl \
	games\minigames\run23\sprites.png.spr

SHARED_DATAS=

SHARED_DATAS_INTERMEDIATE=

#
# targets
#

# default targets
include msxlib.makefile

games\minigames\run23\run23.rom: games\minigames\run23\run23.asm $(MSXLIB) $(DATAS) $(SHARED_DATAS)
	$(ASM) $< $@

# secondary targets
.secondary: $(DATAS_INTERMEDIATE) $(SHARED_DATAS_INTERMEDIATE)

# custom targets
games\minigames\run23\music\empty.pt3.hl \
games\minigames\run23\music\RUN23_ShuffleOne.pt3.hl \
games\minigames\run23\music\RUN23_YouWin1.pt3.hl \
: \
games\minigames\run23\music\headerless.asm \
games\minigames\run23\music\empty.pt3 \
games\minigames\run23\music\RUN23_ShuffleOne.pt3 \
games\minigames\run23\music\RUN23_YouWin1.pt3
	$(ASM) $<

%.pt3.hl.zx0: %.pt3.hl
	$(PACK_ZX0) -f $<
