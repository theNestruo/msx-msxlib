
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
	games\experiments\fsjh1test\fsjh1test.rom

SYM=\
	games\experiments\fsjh1test\fsjh1test.sym

SHARED_DATAS=\
	games\examples\shared\charset.png.chr.$(PACK_EXTENSION) \
	games\examples\shared\charset.png.clr.$(PACK_EXTENSION) \
	games\experiments\shared\sprites.png.spr.$(PACK_EXTENSION)

SHARED_DATAS_INTERMEDIATE=\
	games\examples\shared\charset.png.chr \
	games\examples\shared\charset.png.clr \
	games\experiments\shared\sprites.png.spr

#
# targets
#

# default targets
include msxlib.makefile

games\experiments\fsjh1test\fsjh1test.rom: games\experiments\fsjh1test\fsjh1test.asm $(MSXLIB) $(SHARED_DATAS)
	$(ASM) $< $@

# secondary targets
.secondary: $(SHARED_DATAS_INTERMEDIATE)
