
# commands and tools
include examples.makefile

run: runnable
	$(EMULATOR) games\experiments\fsjh1test\fsjh1test.rom
