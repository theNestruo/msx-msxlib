# Additional NAMBTL and SPRATR buffer based routines

## `ENASCR_FADE_IN`
Fade in (horizontal sweep)

LDIRVM the NAMTBL and SPRATR buffer and enables the screen

If the screen is already enabled, defaults to [`LDIRVM_NAMTBL_FADE_INOUT`](#LDIRVM_NAMTBL_FADE_INOUT)

## `LDIRVM_NAMTBL_FADE_INOUT`
Fade in/out (horizontal sweep) from current VRAM NAMTBL contents to NAMTBL buffer contents

## `DISSCR_FADE_OUT`
Fade out (horizontal sweep)

Disables the screen, clears NAMTBL and disables sprites


# Configuration

The NAMTBL buffer fades in/out from left to right. To use a centered double fade (from the center to the sides), define:
```
	CFG_FADE_TYPE_DOUBLE:
```
