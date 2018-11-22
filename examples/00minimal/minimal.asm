
;
; =============================================================================
;	MSXlib minimal example
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSX symbolic constants
	include	"lib/msx/symbols.asm"
; -----------------------------------------------------------------------------

; =============================================================================
;	ROM
; =============================================================================

; -----------------------------------------------------------------------------
; MSX cartridge (ROM) header, entry point and initialization
	include "lib/msx/cartridge.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
MAIN_INIT:

; At this point, the cartridge is init, the RAM zeroed,
; The screen mode 2 with 16x16 unmagnified sprites,
; the keyboard click is muted, and the screen is disabled.

;
; PUT YOUR CODE (ROM) HERE
;

; In screen mode 2 we need to set up a charset
; to actually show something in the screen.
; Prepares a very uninspired charset (the default one) in the first bank
	ld	hl, [CGTABL] ; (address of ROM character set)
	ld	de, CHRTBL
	ld	bc, CHRTBL_SIZE
	call	LDIRVM
	ld	a, $F0 ; (white over blak)
	ld	hl, CLRTBL
	ld	bc, CHRTBL_SIZE
	call	FILVRM

; Fills the name table with spaces
; and prints a simple message
	ld	a, $20 ; ' '
	ld	hl, NAMTBL
	ld	bc, NAMTBL_SIZE
	call	FILVRM
	ld	hl, .MESSAGE
	ld	de, NAMTBL
	ld	bc, .MESSAGE_SIZE
	call	LDIRVM
	
; Re-enables the screen so we can see the results
	call	ENASCR

; (infinite loop)
.LOOP:
	halt
	jr	.LOOP

; The message to print
.MESSAGE:
	db	"Hello, World!"
	.MESSAGE_SIZE:	equ $ - .MESSAGE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Padding to a 8kB boundary
PADDING:
	ds	($ OR $1fff) -$ +1, $ff ; $ff = rst $38
	.SIZE:	equ $ - PADDING
; -----------------------------------------------------------------------------

; =============================================================================
;	RAM
; =============================================================================

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; lib/ram.asm automatically starts the RAM section at the proper address
; (either $C000 (16KB) or $E000 (8KB)) and includes everything MSXlib requires.

;
; PUT YOUR VARIABLES (RAM) HERE
;

ram_end: ; (required by MSXlib)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	dbg_rom_size_bytes:	equ PADDING - ROM_START
	dbg_rom_free_bytes:	equ PADDING.SIZE
	
	dbg_ram_size_bytes:	equ $ - ram_start
	dbg_ram_free_bytes:	equ $f380 - $
; -----------------------------------------------------------------------------

; EOF
