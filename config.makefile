
#
# commands
#

COPY=cmd /c copy
MKDIR=cmd /c mkdir
MOVE=cmd /c move
REMOVE=cmd /c del
RENAME=cmd /c ren

#
# tools
#

ASM=tniasm.exe
EMULATOR=cmd /c start
DEBUGGER=cmd /c start \MSX\bin\blueMSX_2.8.2\blueMSX.exe
PCX2MSX=pcx2msx+.exe
PCX2SPR=pcx2spr.exe
PNG2MSX=png2msx.exe
PNG2SPR=png2spr.exe
TMX2BIN=tmx2bin.exe

# Uncomment for Pletter 0.5c1
# PACK=pletter
# PACK_EXTENSION=plet5

# Uncomment for ZX7
# (please note that ZX7 does not overwrite output)
PACK=zx7.exe
PACK_EXTENSION=zx7
