
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
	games\examples\03minimal48kb\minimal48kb.rom \
	games\examples\pt3music\pt3music.rom \
	games\examples\wyzmusic\wyzmusic.rom

SYM=\
	games\examples\00minimal\minimal.sym \
	games\examples\01basic\basic.sym \
	games\examples\02snake\snake.sym \
	games\examples\03minimal48kb\minimal48kb.sym \
	games\examples\pt3music\pt3music.sym \
	games\examples\wyzmusic\wyzmusic.sym

SHARED_DATAS=\
	games\examples\shared\charset.png.chr.$(PACK_EXTENSION) \
	games\examples\shared\charset.png.clr.$(PACK_EXTENSION) \
	games\examples\shared\sprites.png.spr.$(PACK_EXTENSION) \
	games\examples\shared\screen.tmx.bin.$(PACK_EXTENSION)

SHARED_DATAS_INTERMEDIATE=\
	games\examples\shared\charset.png.chr \
	games\examples\shared\charset.png.clr \
	games\examples\shared\sprites.png.spr \
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

games\examples\pt3music\pt3music.rom: games\examples\pt3music\pt3music.asm $(MSXLIB)
	$(ASM) $< $@

games\examples\wyzmusic\wyzmusic.rom: games\examples\wyzmusic\wyzmusic.asm $(MSXLIB)
	$(ASM) $< $@

# secondary targets
.secondary: $(SHARED_DATAS_INTERMEDIATE)
