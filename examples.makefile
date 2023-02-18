
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
	games\examples\00minimal\minimal.rom \
	games\examples\01basic\basic.rom \
	games\examples\02snake\snake.rom \
	games\examples\03minimal48kb\minimal48kb.rom

SYM=\
	games\examples\00minimal\minimal.sym \
	games\examples\01basic\basic.sym \
	games\examples\02snake\snake.sym \
	games\examples\03minimal48kb\minimal48kb.sym

SHARED_DATAS=\
	games\examples\shared\charset.pcx.chr.$(PACK_EXTENSION) \
	games\examples\shared\charset.pcx.clr.$(PACK_EXTENSION) \
	games\examples\shared\sprites.pcx.spr.$(PACK_EXTENSION) \
	games\examples\shared\screen.tmx.bin.$(PACK_EXTENSION)

SHARED_DATAS_INTERMEDIATE=\
	games\examples\shared\charset.pcx.chr \
	games\examples\shared\charset.pcx.clr \
	games\examples\shared\sprites.pcx.spr \
	games\examples\shared\screen.tmx.bin

#
# targets
#

# default targets
include msxlib.makefile

games\examples\00minimal\minimal.rom: games\examples\00minimal\minimal.asm $(MSXLIB)
	$(ASM) $< $@

games\examples\01basic\basic.rom: games\examples\01basic\basic.asm $(MSXLIB) $(SHARED_DATAS)
	$(ASM) $< $@

games\examples\02snake\snake.rom: games\examples\02snake\snake.asm $(MSXLIB) $(SHARED_DATAS)
	$(ASM) $< $@

games\examples\03minimal48kb\minimal48kb.rom: games\examples\03minimal48kb\minimal48kb.asm $(MSXLIB) $(SHARED_DATAS)
	$(ASM) $< $@
