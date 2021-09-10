
#
# commands
#

REMOVE=cmd /c del

#
# tools
#

ASM=tniasm.exe
PNG2MSX=png2msx.exe
PNG2SPR=png2spr.exe
TMX2BIN=tmx2bin.exe

PACK_PLET5=pletter
PACK_ZX0=..\libext\ZX0\win\zx0.exe
PACK_ZX1=..\libext\ZX1\win\zx1.exe
PACK_ZX7=zx7.exe

# default target
default: compile

#
# paths and file lists
#

MSXLIB=\
	msxlib.bin.plet5 \
	msxlib.bin.zx0 \
	msxlib.bin.zx1 \
	msxlib.bin.zx7 \
	msxlib\msxlib.bin \
	msxlib\msxlib.rom

MSXLIB_SRCS=\
	msxlib\msxlib.asm

MSXLIB_DATAS=\
	msxlib\charset.png.chr \
	msxlib\sprites.png.spr

RETROEUSKAL=\
	retroeuskal.bin.plet5 \
	retroeuskal.bin.zx0 \
	retroeuskal.bin.zx1 \
	retroeuskal.bin.zx7 \
	retroeuskal\retroeuskal.bin \
	retroeuskal\retroeuskal.rom

RETROEUSKAL_SRCS=\
	retroeuskal\retroeuskal.asm

RETROEUSKAL_DATAS=\
	retroeuskal\charset.png.chr \
	retroeuskal\screen.tmx.bin \
	retroeuskal\sprites.png.spr \

#
# phony targets
#

# default target
default: compile

clean:
	$(REMOVE) $(MSXLIB) $(RETROEUSKAL)
	$(REMOVE) tniasm.sym tniasm.tmp

compile: $(MSXLIB) $(RETROEUSKAL)

#
# MSXlib splash targets
#

msxlib.bin.plet5: msxlib\msxlib.bin
	$(PACK_PLET5) $< $@

msxlib.bin.zx0: msxlib\msxlib.bin
	$(REMOVE) $@
	$(PACK_ZX0) $< $@

msxlib.bin.zx1: msxlib\msxlib.bin
	$(REMOVE) $@
	$(PACK_ZX1) $< $@

msxlib.bin.zx7: msxlib\msxlib.bin
	$(REMOVE) $@
	$(PACK_ZX7) $< $@

msxlib\msxlib.bin: msxlib\msxlib_bin.asm $(MSXLIB_SRCS) $(MSXLIB_DATAS)
	$(ASM) $< $@

msxlib\msxlib.rom: msxlib\msxlib_rom.asm $(MSXLIB_SRCS) $(MSXLIB_DATAS)
	$(ASM) $< $@

msxlib\charset.png.chr: msxlib\charset.png
	$(PNG2MSX) -hl $<

msxlib\sprites.png.spr: msxlib\sprites.png
	$(PNG2SPR) $<

#
# Retroeuskal splash targets
#

retroeuskal.bin.plet5: retroeuskal\retroeuskal.bin
	$(PACK_PLET5) $< $@

retroeuskal.bin.zx0: retroeuskal\retroeuskal.bin
	$(REMOVE) $@
	$(PACK_ZX0) $< $@

retroeuskal.bin.zx1: retroeuskal\retroeuskal.bin
	$(REMOVE) $@
	$(PACK_ZX1) $< $@

retroeuskal.bin.zx7: retroeuskal\retroeuskal.bin
	$(REMOVE) $@
	$(PACK_ZX7) $< $@

retroeuskal\retroeuskal.bin: retroeuskal\retroeuskal_bin.asm $(RETROEUSKAL_SRCS) $(RETROEUSKAL_DATAS)
	$(ASM) $< $@

retroeuskal\retroeuskal.rom: retroeuskal\retroeuskal_rom.asm $(RETROEUSKAL_SRCS) $(RETROEUSKAL_DATAS)
	$(ASM) $< $@

retroeuskal\charset.png.chr: retroeuskal\charset.png
	$(PNG2MSX) -hl $<

retroeuskal\sprites.png.spr: retroeuskal\sprites.png
	$(PNG2SPR) $<

retroeuskal\screen.tmx.bin: retroeuskal\screen.tmx
	$(TMX2BIN) $< $@
