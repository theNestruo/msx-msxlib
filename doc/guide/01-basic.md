# Generic MSXlib cartridge

The minimal MSXlib cartridge described in the previous section reduces the boilerplate code and lets you focus on your code, but doesn't provide any help with that code. To actually start using MSXlib, use the following stub:
```
	include "lib/rom-default.asm"

INIT:
; YOUR CODE (ROM) GOES HERE

	include	"lib/msx/rom_end.asm"

	include	"lib/ram.asm"

; YOUR VARIABLES (RAM) GO HERE

	include	"lib/msx/ram_end.asm"
```

It's actually quite similar to the minimal example, but this actually provides you real benefits of using MSXlib.

`lib/rom-default.asm` is a convenience shortcut to include the general purpose core libraries of MSXlib with sensible defaults. Namely:
* Includes `lib/msx/symbols.asm`.
* Includes the cartridge header and initialization, which now sets up the MSXlib hook to read input (and disables BIOS key interruption).
* Includes the NAMTBL and SPRATR buffer routines, text routines, logical coordinates sprites routines, timing routines, and pause routines.
* Includes generic Z80 assembly convenience routines.
* Includes ZX7 decoder as the unpacker routine, and reserves a buffer of 2048 bytes for it.


### VRAM initialization helpers

For the game initialization, MSXlib provides convenience routines to work with packed graphical data. Namely, there is a simple `UNPACK_LDIRVM` routine to unpack to VRAM:
```
INITIALIZE_SPRITES:
	ld	hl, .SPRTBL_PACKED
	ld	de, SPRTBL
	ld	bc, SPRTBL_SIZE
	jp	UNPACK_LDIRVM

.SPRTBL_PACKED:
	incbin	"examples/shared/sprites.pcx.spr.zx7"
```

There are also specific routines for working with the 3-banks of patterns. For example, this is a typical 3-bank charset initialization using MSXlib:
```
INITIALIZE_CHARSET:
	ld	hl, .CHRTBL_PACKED
	call	UNPACK_LDIRVM_CHRTBL
	ld	hl, .CLRTBL_PACKED
	jp	UNPACK_LDIRVM_CLRTBL

.CHRTBL_PACKED:
	incbin	"examples/shared/charset.pcx.chr.zx7"

.CLRTBL_PACKED:
	incbin	"examples/shared/charset.pcx.clr.zx7"
```


### VRAM buffers in RAM

For the NAMTBL and the SPRATR, MSXlib creates two RAM buffers (named: `namtbl_buffer` and `spratr_buffer`).

Having the SPRATR buffer is particularly useful, because your code will be faster (sprites attributes are a RAM read/write operation) and all of them will move in sync (and, optionally, with flickering):
```
FRAME_LOOP:
	halt
	call	LDIRVM_SPRATR
	; (...)
```

Working with the NAMTBL RAM buffer also has the advantages of being in RAM:
```
INITIALIZE_SCREEN:
	ld	hl, .NAMTBL_PACKED
	ld	de, namtbl_buffer
	call	UNPACK ; (unpack to RAM)

; Enables the screen, but using a fade-in effect to blit the NAMTBL buffer to the VRAM
	jp	ENASCR_FADE_IN

.NAMTBL_PACKED:
	incbin	"examples/shared/screen.tmx.bin.zx7"
```

MSXlib provides several routines to work with these buffers:
* `CLS_NAMTBL` and `CLS_SPRATR` to clear them
* `LDIRVM_NAMTBL` and `LDIRVM_SPRATR` to blit them
* `DISSCR_NO_FADE` and `DISSCR_FADE_OUT` to disable the screen (without or with fading effect), automatically hiding the sprites
* `ENASCR_NO_FADE` and `ENASCR_FADE_IN` to enable the screen (without or with fading effect), automatically showing the sprites


### Cursors and joystick input

By default, MSXlib hook takes control of reading the input on every frame and conveniently saving the input status in RAM.
For example, to check if either the joystick or the keyboard are pointing to a direction, in MSXlib you can use the following code:
```
	ld	a, [input.level]
	bit	BIT_STICK_UP, a
	jr	nz, MOVE_PLAYER_UP ; (routine provided by the developer)
```

The bits for `input.level` are:
```
	BIT_STICK_UP:		equ 0
	BIT_STICK_DOWN:		equ 1
	BIT_STICK_LEFT:		equ 2
	BIT_STICK_RIGHT:	equ 3
	BIT_TRIGGER_A:		equ 4
	BIT_TRIGGER_B:		equ 5
	BIT_BUTTON_SELECT:	equ 6
	BIT_BUTTON_START:	equ 7
```

By default, trigger B is mapped to the M key, the SELECT bit to the SELECT key, and the START bit to the STOP key.

Additionaly, besides `input.level` (that returns the actual status of the bit) you can use `input.edge` to sense when a key gets pressed. This is particularly useful for firing or jumping, or for movements that are not to be repeated each frame (e.g.: moving a cursor on a menu):
```
	ld	a, [input.edge]
	bit	BIT_TRIGGER_A, a
	jr	nz, FIRE_CANNONS ; (routine provided by the developer)
```

Please note that BIOS key interruption gets disabled by MSXlib by default, so variables depending on it (such as `OLDKEY` and `NEWKEY` matrices) can no longer be used.

For a complete list and description of all the routines available, please refer to the reference documentation.


## Configuration

Automatic input read in the hook can be disabled. In that case, you need to manually `call READ_INPUT` to update `input.level` and `input.edge`. To disable automatic input read in the hook define:
```
	CFG_HOOK_DISABLE_AUTO_INPUT:
```

<!--
If automatic input is disabled, BIOS key interruption routine can be restored by additionally defining:
```
	CFG_HOOK_DISABLE_AUTO_INPUT:
	CFG_HOOK_KEEP_BIOS_KEYINT:
```
-->

When blitting the SPRATR buffer, flickering can be used to compensate the 5th sprite rule by defining:
```
	CFG_SPRITES_FLICKER:
```

If you have some sprites that should no flicker (e.g.: mask sprites, some important sprites, etc.), additionally define:
```
	CFG_SPRITES_FLICKER:
	CFG_SPRITES_NO_FLICKER:	equ 7
```

The NAMTBL buffer fades in/out from left to right. To use a centered double fade (from the center to the sides), define:
```
	CFG_FADE_TYPE_DOUBLE:
```

## Source code examples

- [Basic example](../games/examples/01basic/basic.asm): Basics on VRAM initialization helpers, VRAM buffers in RAM, and Cursors and joystick input.
- [Snake game example](../games/examples/02snake/snake.asm): A more elaborate example using wait routines, text printing and fading routines provided by MSXlib.
