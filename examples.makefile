
# commands and tools
include config.makefile

#
# paths and file lists
#

ROM=\
	games\examples\00minimal\minimal.rom \
	games\examples\01basic\basic.rom \
	games\examples\02snake\snake.rom

SYM=\
	games\examples\00minimal\minimal.sym \
	games\examples\01basic\basic.sym \
	games\examples\02snake\snake.sym

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

games\examples\00minimal\minimal.rom: games\examples\00minimal\minimal.asm $(SRCS_MSXLIB)
	$(ASM) $< $@

games\examples\01basic\basic.rom: games\examples\01basic\basic.asm $(SRCS_MSXLIB) $(SHARED_DATAS)
	$(ASM) $< $@

games\examples\02snake\snake.rom: games\examples\02snake\snake.asm $(SRCS_MSXLIB) $(SHARED_DATAS)
	$(ASM) $< $@

# default targets
include msxlib.makefile
