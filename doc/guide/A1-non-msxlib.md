# MSXlib for non-MSXlib projects

MSXlib contains two ASM files that can be used without actually using MSXlib.


## MSX symbolic constants

The first one is `lib/msx/symbols.asm`, which defines symbolic constants for MSX BIOS entry points, MSX system variables, VRAM addresses and symbolic constants, and some special ASCII codes.
```
; MSX symbolic constants
	#include "lib/msx/symbols.asm"
```
This file does not add any code to your project.
It is simply a helper that allows writing more readable code (`call ENASCR` instead of `call $0044`). It can also be used as a reference.
For a complete list of the defined symbolic constants, please refer to the actual contents of the file.


## Generic Z80 assembly convenience routines

Another file that can be used outside MSXlib is `lib/asm/asm.asm`.
```
; Generic Z80 assembly convenience routines
	#include "lib/asm/asm.asm"
```
This file contains some useful convenience routines that are used internally by MSXlib, but that can be useful outside.
This routines emulate non-existent instructions (such as `add hl, a`), provide array functionality (`a = hl[a]`), jump tables (`ON a GOTO ...`), and others.
For a complete list of routines, please refer to the actual contents of the file.
