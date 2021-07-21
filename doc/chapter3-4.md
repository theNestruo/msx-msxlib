
# MSXlib cookbook: Other recipes

A cookbook that explains the MSXlib capabilities using examples and source code.

The _Other recipes_ section cover routines that did not suit any of the previous sections.


## Using page 0 ($0000-$3FFF) as a compressed data storage

If you want to create a 48kB using MSXlib, use the following structure:

```assembly
; MSX symbolic constants
	include	"lib/msx/symbols.asm"

; -----------------------------------------------------------------------------
; ROM

; Page 0
	include "lib/page0.asm"

	;
	; YOUR DATA AT PAGE 0 (ROM) START HERE
	;

	include "lib/page0_end.asm"

; Define the ROM size in kB (8kB, 16kB, 24kB, 32kB, or 48kB)
	CFG_INIT_ROM_SIZE:	equ 48

; MSXlib helper: default configuration
	include	"lib/rom-default.asm"

; Game entry point
INIT:
	;
	; YOUR CODE (ROM) GOES HERE
	;
	ret

	include	"lib/msx/rom_end.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; RAM

; MSXlib core and game-related variables
	include	"lib/ram.asm"

	;
	; YOUR VARIABLES (RAM) START HERE
	;

	include	"lib/msx/ram_end.asm"
; -----------------------------------------------------------------------------
```

This structure is not very different from the [A not-so-minimal MSXlib cartridge](chapter1.md#a-not-so-minimal-msxlib-cartridge) section of the first chapter. Changes comprises:
* Demarcation of the page 0 by `include "lib/page0.asm"` at the beginning and `include "lib/page0_end.asm"` at the end. The page 0 must be coded:
	* Either at the beginning of the source code (i.e.: before the `include "lib/rom-default.asm"` or the `include "lib/msx/cartridge.asm"`), which is the preferred way,
	* or at the end of the source code (i.e.: after the `include "lib/msx/rom_end.asm"` and before the `include "lib/ram.asm"`)
* Declare the cartridge target size as 48kB (`CFG_INIT_ROM_SIZE: equ 48`). Initialization will store the slot/subslot configuration during the search for page 2 slot/subslot to allow page 0 switching.

Since the ROM cartridge size (`CFG_INIT_ROM_SIZE`) is configured to be larger than 32kB, you can make use of the following routines:

* `SET_PAGE0.CARTRIDGE`: Selects and enables the cartridge slot/sublot in page 0.
	> Important: Caller is responsible of enabling interruptions after invoking this routine.

* `SET_PAGE0.BIOS`: Restores the BIOS (selects and enables the Main ROM slot/subslot in page 0).
	> Important: Caller is responsible of disabling interruptions before invoking this routine

Despite both code and data are allowed in page 0, MSXlib supports using it as a compressed data storage. If the page 0 is present, the provided [compressed data unpackers](chapter2.md#compressed-data-unpacker) will be aware of it and, if the source compressed data is in that page, will automatically select the cartridge slot/subslot in page 0 before unpacking, and restore the BIOS afterwards.


## Detecting a catridge in the secondary slot

To emulate Konami and Casio cartridge combinations, include the secondary slot routines:

```assembly
include "lib/msx/etc/slot2.asm"
```

Then, you need to know what to look for and at which address it is and invoke the `SEARCH_IN_ANY_SLOT` routine.

A simple example is to look for a Konami game released after Game Master, when they started to embed the RC code (a cartridge ID) at a fixed position:

```assembly
; Checks for Konami's "Goonies" (RC 734)
	ld    hl, .GOONIES_DATA
	call  SEARCH_IN_ANY_SLOT
	ret   z ; "Goonies" is not present
; "Goonies" is present
	; ...

.GOONIES_DATA:
	dw    $4010 ; At address $4010...
	db    4     ; ...check the following 4 bytes:
	db    $43, $44, $07 $34 ; "CD" followed by the RC code 734 (BCD)
```

---
* Back to index: [MSXlib Development Guide](index.md)
* Previous chapter: [MSXlib cookbook: Music and sound effects](chapter3-3.md)
* Next chapter: [Appendix A. MSXlib reference](appendixA.md)
