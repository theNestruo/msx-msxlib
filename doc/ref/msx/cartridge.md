# MSX cartridge (ROM) header, entry point and initialization

## `CARTRIDGE_HEADER`
Cartridge header.

The cartridge header is located in page one ($4000) and sets `INIT` to [`CARTRIDGE_INIT`](#CARTRIDGE_INIT).

## `CARTRIDGE_INIT`
MSXlib cartridge entry point. Perform system initialization: stack pointer, slots, RAM, CPU, VDP, PSG, etc.

- Ensures the right interrupt mode and initializes the stack pointer
- Ensures the CPU is in Z80 mode
- If the ROM Cartridge size (`CFG_INIT_ROM_SIZE`) is configured to be larger than 16KB, enables page 2 cartridge slot/subslot at start
	- If the ROM Cartridge size (`CFG_INIT_ROM_SIZE`) is configured to be larger than 32KB, initializes the variables required by the [`SET_PAGE0`](#SET_PAGE0) routines
- Splash screens before further initialization
- If the RAM size is required to be at least 16Kb, (`CFG_INIT_16KB_RAM`) checks the availability of 16kB. If it is not available, shows a warning text and halts the execution
- Initializes the VDP: `color 15,1,1` and `screen 2,2,0`. If it is a MSX2 VDP:
	- If the 1 key is down: sets the palette to TMS approximate
	- If the 2 key is down: sets the palette to default MSX2 palette
	- Otherwise: sets the palette to a custom palette (if defined), or to the CoolColors palette (&copy; Fabio R. Schmidlin, 1997)
- Zeroes all the used RAM
- Initializes the PSG: silence
	- If a replayer is included, initializes it
- Initializes the frame rate related variables
- If the [MSXlib `H.TIMI` hook](hook.md#HOOK) is included, installs it in the interruption
- Skips to the game entry point by `jp INIT`

## `SET_PAGE0`
Declares routines to set the page 0 slot/subslot and restore the BIOS.

This routines are optional, and will only be present if the ROM Cartridge size (`CFG_INIT_ROM_SIZE`) is configured to be larger than 32KB.

### `SET_PAGE0.BIOS`
Restores the BIOS (selects and enables the Main ROM slot/subslot in page 0).

> Important: Caller is responsible of disabling interruptions before invoking this routine

### `SET_PAGE0.CARTRIDGE`
Selects and enables the cartridge slot/sublot in page 0.

> Important: Caller is responsible of enabling interruptions after invoking this routine.


# Configuration

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
