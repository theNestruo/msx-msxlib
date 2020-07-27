
# Appendix A. MSXlib reference

Non-comprehensive reference for some MSXlib modules


# MSXlib cartridge initialization sequence

`CARTRIDGE_INIT`, the MSXlib cartridge entry point, performs system initialization following the sequence:

- Ensures the right interrupt mode and initializes the stack pointer
- Ensures the CPU is in Z80 mode
- If the ROM Cartridge size (`CFG_INIT_ROM_SIZE`) is configured to be larger than 16KB, enables page 2 cartridge slot/subslot at start
	- If the ROM Cartridge size (`CFG_INIT_ROM_SIZE`) is configured to be larger than 32KB, initializes the variables required by the `SET_PAGE0` routines
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
- If the MSXlib `H.TIMI` hook is included, installs it in the interruption
- Skips to the game entry point by `jp INIT`


# MSXlib interrupt routine (`H.TIMI` hook)

The MSXlib `H.TIMI` hook performs the following sequence:

- If a replayer is included, invokes the replayer
- Automatically reads the inputs
	- If `CFG_HOOK_ENABLE_AUTO_KEYBOARD` is set, reads the entire keyboard matrix (`io/keyboard.md#READ_KEYBOARD`)
	- If `CFG_HOOK_DISABLE_AUTO_INPUT` is **not** set, reads the cursors and joystick (`io/input.md#READ_INPUT`)
- Tricks BIOS' `KEYINT` to skip keyboard scan, `TRGFLG`, `OLDKEY`/`NEWKEY`, `ON STRIG`...
- Invokes the previously existing hook


---
* Back to index: [MSXlib Development Guide](index.md)
* Previous chapter: [MSXlib cookbook](chapter3.md)
