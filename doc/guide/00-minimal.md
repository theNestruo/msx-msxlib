# Minimal MSXlib cartridge

The minimal example of MSXlib-based cartridge is as follows:
```
	include "lib/msx/symbols.asm"

	include "lib/msx/cartridge.asm"

INIT:
; YOUR CODE (ROM) GOES HERE

	include	"lib/msx/rom_end.asm"

	include	"lib/ram.asm"

; YOUR VARIABLES (RAM) GO HERE

	include	"lib/msx/ram_end.asm"
```

MSXlib will help you reduce the boilerplate code and obscure technical stuff, so you can simply focus on coding your game.


The first included file (`lib/msx/symbols.asm`) does not add any code to your project, but defines symbolic constants for MSX BIOS entry points, MSX system variables, VRAM addresses and symbolic constants, PPI (Programmable Peripheral Interface) ports, and some special ASCII codes. This way, you can simply type `call ENASCR` (instead of the more obscure `call $0044`).


The next file (`lib/msx/cartridge.asm`) includes the cartridge header and performs some initialization for you. Without other MSXlib modules present, this initialization comprises:
* Initializes the interrupt mode and the stack pointer
* Ensures the CPU is in Z80 mode when running in a MSX turbo R or superior
* Initializes the screen with the ASM equivalent to BASIC `COLOR 15,1,1` and `SCREEN 2,2,0`
* Disables the screen
* Zeroes all the used RAM
* Initializes the PSG to silence
* Saves the refresh rate in Hertzs (50Hz/60Hz) reported by the BIOS into `frame_rate`, and the number of frames per tenth into `frames_per_tenth`
* Jumps to the `INIT` label

So, when the execution reaches `INIT`, everything is conveniently initialized for you.

Also, please note that the screen is disabled after the initialization. This is intentional and actually convenient (to load the game charset, for example), but don't forget to `call ENASCR`.


The `lib/msx/rom_end.asm` include marks the end of the ROM, and MSXlib automatically pads the remaining space to the next 8kB boundary.


For the RAM part, always start including `lib/ram.asm`. This will define the RAM start ($E000 by default), and include the variables MSXlib requires depending on the includes you are using.

Your variables can be declared after that.

Don't forget to include `lib/msx/ram_end.asm` after your variables. This include lets MSXlib know where the RAM ends (to zero it during initialization).


## Configuration

If your cartridge is larger than 16kb (typically, 32kB), define the following for the initialization to the search for page 2 slot/subslot:
```
	CFG_INIT_32KB_ROM:
	include "lib/msx/cartridge.asm"
```

If your RAM requirements are 16kB instead of 8kB, define the following for the initialization to check the availability of 16kB, and to make the RAM start at the beginning of the page 2 ($c000) instead of at $e000:
```
	CFG_INIT_16KB_RAM:
	include "lib/msx/cartridge.asm"
```
