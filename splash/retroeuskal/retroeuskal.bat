@echo off
pcx2msx charset.pcx -hl
tmx2bin screen.tmx
pcx2spr sprites.pcx

tniasm retroeuskal_rom.asm retroeuskal.rom

tniasm retroeuskal_bin.asm retroeuskal.bin
if exist retroeuskal.bin.zx7 del retroeuskal.bin.zx7
zx7 retroeuskal.bin retroeuskal.bin.zx7
