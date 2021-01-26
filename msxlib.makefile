
#
# paths and file lists
#

SRCS_MSXLIB=\
	lib\page0.asm \
	lib\page0_end.asm \
	lib\rom-default.asm \
	lib\rom_end.asm \
	lib\ram.asm \
	lib\ram_end.asm \
	lib\msx\symbols.asm \
	lib\msx\cartridge.asm \
	lib\msx\hook.asm \
	lib\msx\ram.asm \
	lib\msx\io\input.asm \
	lib\msx\io\keyboard.asm \
	lib\msx\io\print.asm \
	lib\msx\io\sprites.asm \
	lib\msx\io\timing.asm \
	lib\msx\io\vram.asm \
	lib\msx\io\replayer_pt3.asm \
	lib\msx\io\replayer_wyz.asm \
	lib\msx\etc\fade.asm \
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
	lib\game\etc\ram.asm \
	lib\unpack\unpack_zx0.asm \
	lib\unpack\unpack_zx7.asm \
	lib\unpack\ram.asm

SRCS_LIBEXT=\
	libext\ayFX-replayer\ayFX-ROM.tniasm.asm \
	libext\ayFX-replayer\ayFX-RAM.tniasm.asm \
	libext\pletter05c\pletter05c-unpackRam.tniasm.asm \
	libext\pt3\PT3-ROM.tniasm.asm \
	libext\pt3\PT3-RAM.tniasm.asm \
	libext\wyzplayer\WYZPROPLAY47cMSX.ASM \
	libext\wyzplayer\WYZPROPLAY47c_RAM.tniasm.ASM \
	libext\zx0\dzx0_standard.asm \
	libext\zx7\dzx7_standard.tniasm.asm

#
# phony targets
#

# default target
default: compile

clean:
	$(REMOVE) $(ROM)
	$(REMOVE) $(SYM) tniasm.sym tniasm.tmp

compile: $(ROM)

test: $(ROM)
	$(EMULATOR) $<

debug: $(ROM) $(SYMS)
	$(DEBUGGER) $<

#
# GFXs, SPRs, and BINs targets
#

# -lh by default because packing usally produces smaller binaries
%.pcx.chr %.pcx.clr: %.pcx
	$(PCX2MSX) -lh $<

# -lh by default because packing usally produces smaller binaries
%.png.chr %.png.clr: %.png
	$(PNG2MSX) -lh $<

%.pcx.spr: %.pcx
	$(PCX2SPR) $<

%.png.spr: %.png
	$(PNG2SPR) $<

%.tmx.bin: %.tmx
	$(TMX2BIN) $< $@

#
# Compressed targets
#

%.bin.$(PACK_EXTENSION): %.bin
	$(REMOVE) $@
	$(PACK) $<

%.chr.$(PACK_EXTENSION): %.chr
	$(REMOVE) $@
	$(PACK) $<

%.clr.$(PACK_EXTENSION): %.clr
	$(REMOVE) $@
	$(PACK) $<

%.nam.$(PACK_EXTENSION): %.nam
	$(REMOVE) $@
	$(PACK) $<

%.spr.$(PACK_EXTENSION): %.spr
	$(REMOVE) $@
	$(PACK) $<
