
# commands and tools
include experiments.makefile

run: runnable
	$(EMULATOR) games\experiments\fsjh1test\fsjh1test.rom
