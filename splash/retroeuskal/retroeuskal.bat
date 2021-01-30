@echo off
pcx2msx charset.pcx -hl
tmx2bin screen.tmx
pcx2spr sprites.pcx

tniasm retroeuskal_rom.asm retroeuskal.rom

tniasm retroeuskal_bin.asm retroeuskal.bin

if exist ..\retroeuskal.bin.plet5 del ..\retroeuskal.bin.plet5
pletter retroeuskal.bin ..\retroeuskal.bin.plet5

if exist ..\retroeuskal.bin.zx0 del ..\retroeuskal.bin.zx0
zx0 retroeuskal.bin ..\retroeuskal.bin.zx0

if exist ..\retroeuskal.bin.zx1 del ..\retroeuskal.bin.zx1
zx1 retroeuskal.bin ..\retroeuskal.bin.zx1

if exist ..\retroeuskal.bin.zx7 del ..\retroeuskal.bin.zx7
zx7 retroeuskal.bin ..\retroeuskal.bin.zx7
