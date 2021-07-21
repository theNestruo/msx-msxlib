
# MSXlib cookbook: Texts and graphics

A cookbook that explains the MSXlib capabilities using examples and source code.

This section contains several text and graphic related routines, such as loading a charset or printing a BCD number.


## Loading the chaset graphics

## Printing text in screen

<!--
# NAMTBL buffer text and block routines

## `PRINT_CENTERED_TEXT`
Writes a 0-terminated string centered in the NAMTBL buffer
- param hl: source string
- param de: NAMTBL buffer pointer (beginning of the line)

## `PRINT_TEXT`
Writes a 0-terminated string in the NAMTBL buffer
- param hl: source string
- param de: NAMTBL buffer pointer

## `LOCATE_CENTER`
Centers a 0-terminated string
- param hl: source string
- param de: NAMTBL buffer pointer (beginning of the line)
- ret de: NAMTBL buffer pointer

## `CLEAR_LINE`
Clears a line in the NAMTBL buffer with the blank space character ($20, " " ASCII)
- param hl: NAMTBL buffer pointer (beginning of the line)

## `CLEAR_LINE.USING_A`
Fills a line in the NAMTBL buffer with the specified character
- param hl: NAMTBL buffer pointer (beginning of the line)
- param a: the character to fill the line

## `GET_TEXT`
Reads a string from a 0-terminated string array
- param hl: source of the first string
- param a: string index
- ret hl: source of the a-th string
-->

<!--
## `PRINT_BLOCK`
Prints a block of b x c characters
- param hl: source data
- param bc: [height, width] of the block
- param de: NAMTBL buffer pointer
-->


## Printing numbers in screen

<!--
## `PRINT_BCD`
Prints two digits of a BCD value in the NAMTBL buffer
- param hl: source BCD value
- param de: NAMTBL buffer pointer
- ret de: updated NAMTBL buffer pointer
-->


## Putting sprites


## Flickering sprites

When blitting the SPRATR buffer, flickering can be used to compensate the 5th sprite rule by defining:

```assembly
CFG_SPRITES_FLICKER:
```

That's all. `LDIRVM_SPRATR` will automatically flicker the sprites. Of course, you'll need to invoke it after *every* halt even if the SPRATR buffer hasn't changed.

If you have some sprites that should no flicker (e.g.: mask sprites, some important sprites, etc.), additionally define:

```assembly
CFG_SPRITES_FLICKER:
CFG_SPRITES_NO_FLICKER:	equ 7
```


## Fading-in/out the screen

Working with the NAMTBL RAM buffer gains the advantage of being able to blit the screen with fade-in/out effects by using `DISSCR_FADE_OUT` and `ENASCR_FADE_IN` instead of `DISSCR_NO_FADE` and `ENASCR_NO_FADE`.

Example code:

```assembly
INITIALIZE_SCREEN:
	ld    hl, .NAMTBL_PACKED
	ld    de, namtbl_buffer
	call  UNPACK ; (unpack to RAM)

; Enables the screen, but using a fade-in effect to blit the NAMTBL buffer to the VRAM
	jp    ENASCR_FADE_IN

.NAMTBL_PACKED:
	incbin "examples/shared/screen.tmx.bin.zx7"
```

> The NAMTBL buffer fades in/out from left to right by default. To use a centered double fade (from the center to the sides), define:
> ```assembly
> CFG_FADE_TYPE_DOUBLE:
> ```


---
* Back to index: [MSXlib Development Guide](index.md)
* Previous chapter: [Before you continue...](chapter2.md)
* Next chapter: [MSXlib cookbook: Player input](chapter3-2.md)
