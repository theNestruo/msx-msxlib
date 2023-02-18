
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
	lib\msx\cartridge_header.asm \
	lib\msx\cartridge_init.asm \
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
	lib\asm\etc.asm \
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
	lib\unpack\unpack_zx1.asm \
	lib\unpack\unpack_zx7.asm \
	lib\unpack\ram.asm \
	lib\etc\random.asm \
	lib\etc\ram.asm

SRCS_LIBEXT=\
	libext\ayFX-replayer\ayFX-ROM.tniasm.asm \
	libext\ayFX-replayer\ayFX-RAM.tniasm.asm \
	libext\pletter05c\pletter05c-unpackRam.tniasm.asm \
	libext\pt3\PT3-ROM.tniasm.asm \
	libext\pt3\PT3-RAM.tniasm.asm \
	libext\wyzplayer\WYZPROPLAY47cMSX.ASM \
	libext\wyzplayer\WYZPROPLAY47c_RAM.tniasm.ASM \
	libext\ZX0\z80\dzx0_standard.asm \
	libext\ZX1\z80\dzx1_standard.asm \
	libext\zx7\dzx7_standard.tniasm.asm

BINS_MSXLIB=\
	splash\msxlib.bin.plet5 \
	splash\msxlib.bin.zx0 \
	splash\msxlib.bin.zx1 \
	splash\msxlib.bin.zx7 \
	splash\retroeuskal.bin.plet5 \
	splash\retroeuskal.bin.zx0 \
	splash\retroeuskal.bin.zx1 \
	splash\retroeuskal.bin.zx7

MSXLIB=$(SRC_MSXLIB) $(SRCS_LIBEXT) $(BINS_MSXLIB)

#
# phony targets
#

clean:
	$(REMOVE) $(ROM)
	$(REMOVE) $(SYM) tniasm.sym tniasm.tmp

compile: $(ROM) $(MSXLIB)

run: runnable
	$(EMULATOR) $(ROM)

debug: debuggable
	$(DEBUGGER) $(ROM)

#
# Convenience auxiliary targets
#

runnable: $(ROM)

debuggable: $(ROM) $(SYM)

$(SYM): tniasm.sym
	$(COPY) $< $@

#
# GFXs, SPRs, and BINs targets
#

# -hl by default for FILVRM compatibility
%.pcx.chr %.pcx.clr: %.pcx
	$(PCX2MSX) -hl $<

# -hl by default for FILVRM compatibility
%.png.chr %.png.clr: %.png
	$(PNG2MSX) -hl $<

%.pcx.spr: %.pcx
	$(PCX2SPR) $<

%.png.spr: %.png
	$(PNG2SPR) $<

%.tmx.bin: %.tmx
	$(TMX2BIN) $< $@

#
# Compressed targets
#

# Pletter 0.5c1

%.bin.plet5: %.bin
	$(PACK_PLET5) $<

%.chr.plet5: %.chr
	$(PACK_PLET5) $<

%.clr.plet5: %.clr
	$(PACK_PLET5) $<

%.nam.plet5: %.nam
	$(PACK_PLET5) $<

%.spr.plet5: %.spr
	$(PACK_PLET5) $<

# ZX0 v2.0

%.bin.zx0: %.bin
	$(PACK_ZX0) -f $<

%.chr.zx0: %.chr
	$(PACK_ZX0) -f $<

%.clr.zx0: %.clr
	$(PACK_ZX0) -f $<

%.nam.zx0: %.nam
	$(PACK_ZX0) -f $<

%.spr.zx0: %.spr
	$(PACK_ZX0) -f $<

# ZX1

%.bin.zx1: %.bin
	$(PACK_ZX1) -f $<

%.chr.zx1: %.chr
	$(PACK_ZX1) -f $<

%.clr.zx1: %.clr
	$(PACK_ZX1) -f $<

%.nam.zx1: %.nam
	$(PACK_ZX1) -f $<

%.spr.zx1: %.spr
	$(PACK_ZX1) -f $<

# ZX7

%.bin.zx7: %.bin
	$(REMOVE) $@
	$(PACK_ZX7) $<

%.chr.zx7: %.chr
	$(REMOVE) $@
	$(PACK_ZX7) $<

%.clr.zx7: %.clr
	$(REMOVE) $@
	$(PACK_ZX7) $<

%.nam.zx7: %.nam
	$(REMOVE) $@
	$(PACK_ZX7) $<

%.spr.zx7: %.spr
	$(REMOVE) $@
	$(PACK_ZX7) $<
