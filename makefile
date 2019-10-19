
#
# current game name
#

EXAMPLES_PATH=\
	games\examples

SHARED_DATAS=\
	$(EXAMPLES_PATH)\shared\charset.pcx.chr \
	$(EXAMPLES_PATH)\shared\charset.pcx.chr.$(PACK_EXTENSION) \
	$(EXAMPLES_PATH)\shared\charset.pcx.clr \
	$(EXAMPLES_PATH)\shared\charset.pcx.clr.$(PACK_EXTENSION) \
	$(EXAMPLES_PATH)\shared\sprites.pcx.spr \
	$(EXAMPLES_PATH)\shared\sprites.pcx.spr.$(PACK_EXTENSION) \
	$(EXAMPLES_PATH)\shared\screen.tmx.bin \
	$(EXAMPLES_PATH)\shared\screen.tmx.bin.$(PACK_EXTENSION)

#
# tools
#

ASM=tniasm
EMULATOR=cmd /c start
DEBUGGER=cmd /c start \MSX\bin\blueMSX_2.8.2\blueMSX.exe
PCX2MSX=pcx2msx+
PCX2SPR=pcx2spr
TMX2BIN=tmx2bin

# Uncomment for Pletter 0.5c1
# PACK=pletter
# PACK_EXTENSION=plet5

# Uncomment for ZX7
# (please note that ZX7 does not overwrite output)
PACK=zx7.exe
PACK_EXTENSION=zx7

#
# commands
#

COPY=cmd /c copy
MKDIR=cmd /c mkdir
MOVE=cmd /c move
REMOVE=cmd /c del
RENAME=cmd /c ren

#
# paths and file lists
#

ROMS=\
	$(EXAMPLES_PATH)\00minimal\minimal.rom \
	$(EXAMPLES_PATH)\01basic\basic.rom \
	$(EXAMPLES_PATH)\02snake\snake.rom

SYMS=\
	$(EXAMPLES_PATH)\00minimal\minimal.sym \
	$(EXAMPLES_PATH)\01basic\basic.sym \
	$(EXAMPLES_PATH)\02snake\snake.sym

SRCS_MSXLIB=\
	lib\rom-default.asm \
	lib\ram.asm \
	lib\msx\symbols.asm \
	lib\msx\page0.asm \
	lib\msx\page0_end.asm \
	lib\msx\cartridge.asm \
	lib\msx\hook.asm \
	lib\msx\rom_end.asm \
	lib\msx\ram.asm \
	lib\msx\ram_end.asm \
	lib\msx\io\input.asm \
	lib\msx\io\keyboard.asm \
	lib\msx\io\timing.asm \
	lib\msx\io\vram.asm \
	lib\msx\io\replayer_pt3.asm \
	lib\msx\io\replayer_wyz.asm \
	lib\msx\unpack\unpack_zx7.asm \
	lib\msx\etc\msx2_palette.asm \
	lib\msx\etc\vpokes.asm \
	lib\msx\etc\spriteables.asm \
	lib\msx\etc\attract_print.asm \
	lib\msx\etc\ram.asm \
	lib\asm\asm.asm \
	lib\game\tiles.asm \
	lib\game\player.asm \
	lib\game\enemy.asm \
	lib\game\bullet.asm \
	lib\game\collision.asm \
	lib\game\ram.asm \
	lib\game\platformer\platformer_player.asm \
	lib\game\platformer\platformer_enemy.asm \
	lib\game\etc\password.asm \
	lib\game\etc\ram.asm

SRCS_LIBEXT=\
	libext\ayFX-replayer\ayFX-ROM.tniasm.asm \
	libext\ayFX-replayer\ayFX-RAM.tniasm.asm \
	libext\pletter05c\pletter05c-unpackRam.tniasm.asm \
	libext\pt3\PT3-ROM.tniasm.asm \
	libext\pt3\PT3-RAM.tniasm.asm \
	libext\wyzplayer\WYZPROPLAY47cMSX.ASM \
	libext\wyzplayer\WYZPROPLAY47c_RAM.tniasm.ASM \
	libext\zx7\dzx7_standard.tniasm.asm

#
# phony targets
#

# default target
default: compile

clean:
	$(REMOVE) $(ROMS)
	$(REMOVE) $(SYMS) tniasm.sym tniasm.tmp

cleandata:
	$(REMOVE) $(SHARED_DATAS)

cleanall: clean cleandata

compile: $(ROMS)

# test: $(ROMS)
# 	$(EMULATOR) $<

# debug: $(ROMS) $(SYMS)
# 	$(DEBUGGER) $<

# deploy: $(ROM)

#
# main targets
#

$(EXAMPLES_PATH)\00minimal\minimal.rom: $(EXAMPLES_PATH)\00minimal\minimal.asm $(SRCS_MSXLIB)
	$(ASM) $< $@
	cmd /c findstr /b /i "dbg_" tniasm.sym | sort

$(EXAMPLES_PATH)\01basic\basic.rom: $(EXAMPLES_PATH)\01basic\basic.asm $(SRCS_MSXLIB) $(SHARED_DATAS)
	$(ASM) $< $@
	cmd /c findstr /b /i "dbg_" tniasm.sym | sort

$(EXAMPLES_PATH)\02snake\snake.rom: $(EXAMPLES_PATH)\02snake\snake.asm $(SRCS_MSXLIB) $(SHARED_DATAS)
	$(ASM) $< $@
	cmd /c findstr /b /i "dbg_" tniasm.sym | sort

#
# GFXs targets
#

%.pcx.chr.$(PACK_EXTENSION): %.pcx.chr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.clr.$(PACK_EXTENSION): %.pcx.clr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.nam.$(PACK_EXTENSION): %.pcx.nam
	$(REMOVE) $@
	$(PACK) $<

# -lh by default because packing usally produces smaller binaries
%.pcx.chr %.pcx.clr: %.pcx
	$(PCX2MSX) -lh $<

#
# SPRs targets
#

%.pcx.spr.$(PACK_EXTENSION): %.pcx.spr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.spr: %.pcx
	$(PCX2SPR) $<

#
# BINs targets
#

%.tmx.bin.$(PACK_EXTENSION): %.tmx.bin
	$(REMOVE) $@
	$(PACK) $<

%.tmx.bin: %.tmx
	$(TMX2BIN) $< $@
