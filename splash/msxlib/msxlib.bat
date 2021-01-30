@echo off
pcx2msx charset.pcx -hl
pcx2spr sprites.pcx

tniasm msxlib_rom.asm msxlib.rom

tniasm msxlib_bin.asm msxlib.bin

if exist ..\msxlib.bin.plet5 del ..\msxlib.bin.plet5
pletter msxlib.bin ..\msxlib.bin.plet5

if exist ..\msxlib.bin.zx0 del ..\msxlib.bin.zx0
zx0 msxlib.bin ..\msxlib.bin.zx0

if exist ..\msxlib.bin.zx1 del ..\msxlib.bin.zx1
zx1 msxlib.bin ..\msxlib.bin.zx1

if exist ..\msxlib.bin.zx7 del ..\msxlib.bin.zx7
zx7 msxlib.bin ..\msxlib.bin.zx7
