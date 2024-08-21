
# commands and tools
include examples.makefile

run: runnable
#	$(EMULATOR) games\examples\04flash\flash.rom
#	$(EMULATOR) games\examples\pt3music\pt3music.rom
	$(EMULATOR) games\examples\wyzmusic\wyzmusic.rom
