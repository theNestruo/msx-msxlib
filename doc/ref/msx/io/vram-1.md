
# NAMBTL and SPRATR buffer routines (BIOS-based)

## `CLS_NAMTBL`
Fills the NAMTBL buffer with the blank space character ($20, " " ASCII)

## `CLS_SPRATR`
Fills the SPRATR buffer with the SPAT_END marker value

## `LDIRVM_NAMTBL`
LDIRVM the NAMTBL buffer

## `LDIRVM_SPRATR`
LDIRVM the SPRATR buffer.

If `CFG_SPRITES_FLICKER` is set, applies a sprite flickering routine

## `DISSCR_NO_FADE`
Disables the screen, clears NAMTBL and disables sprites

## `ENASCR_NO_FADE`
LDIRVM the NAMTBL and SPRATR buffers and enables the screen


# Configuration

When blitting the SPRATR buffer, flickering can be used to compensate the 5th sprite rule by defining:
```
	CFG_SPRITES_FLICKER:
```

If you have some sprites that should no flicker (e.g.: mask sprites, some important sprites, etc.), additionally define:
```
	CFG_SPRITES_FLICKER:
	CFG_SPRITES_NO_FLICKER:	equ 7
```
