@echo off
pcx2msx charset.pcx -hl
pcx2spr sprites.pcx

tniasm msxlib_rom.asm msxlib.rom

tniasm msxlib_bin.asm msxlib.bin
if exist ..\msxlib.bin.zx7 del ..\msxlib.bin.zx7
zx7 msxlib.bin ..\msxlib.bin.zx7
