
# default target
default: compile

# commands and tools
include config.makefile

# packer; must match the included unpacker routine
PACK_EXTENSION=zx0

#
# current game name
#

GAME=template

GAME_PATH=\
	games\$(GAME)

ROM=\
	$(GAME_PATH)\$(GAME).rom

SYM=\
	$(GAME_PATH)\$(GAME).sym

SRCS=\
	$(GAME_PATH)\$(GAME).asm \
	splash\msxlib.bin.$(PACK_EXTENSION) \

DATAS=\
	$(GAME_PATH)\charset.pcx.chr.$(PACK_EXTENSION) \
	$(GAME_PATH)\charset.pcx.clr.$(PACK_EXTENSION) \
	$(GAME_PATH)\sprites.pcx.spr.$(PACK_EXTENSION) \
	$(GAME_PATH)\screen.tmx.bin.$(PACK_EXTENSION)

DATAS_INTERMEDIATE=\
	$(GAME_PATH)\charset.pcx.chr \
	$(GAME_PATH)\charset.pcx.clr \
	$(GAME_PATH)\sprites.pcx.spr \
	$(GAME_PATH)\screen.tmx.bin

# secondary targets
.secondary: $(DATAS_INTERMEDIATE)

#
# main targets
#

# default targets
include msxlib.makefile

$(ROM) tniasm.sym: $(SRCS) $(MSXLIB) $(DATAS)
	$(ASM) $< $@
# cmd /c findstr /b /i "dbg_" tniasm.sym | sort
