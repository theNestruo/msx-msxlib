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

## `PRINT_BCD`
Prints two digits of a BCD value in the NAMTBL buffer
- param hl: source BCD value
- param de: NAMTBL buffer pointer
- ret de: updated NAMTBL buffer pointer

## `PRINT_BLOCK`
Prints a block of b x c characters
- param hl: source data
- param bc: [height, width] of the block
- param de: NAMTBL buffer pointer
