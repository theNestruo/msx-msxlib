
# commands and tools
include examples.makefile

run: runnable
	$(EMULATOR) games\examples\wyzmusic\wyzmusic.rom
