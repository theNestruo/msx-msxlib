
;
; =============================================================================
;	MSXlib 48kB ROM minimal example
; =============================================================================
;

; -----------------------------------------------------------------------------
	include "lib/page0.asm"

;
; YOUR DATA AT PAGE 0 (ROM) START HERE
;
; Example:
;

; The message to print
MY_MESSAGE:
	db	"Hello, World!"
	.SIZE:	equ $ - MY_MESSAGE

	include "lib/page0_end.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; MSX cartridge (ROM) header, entry point and initialization

; Define the ROM size in kB (8kB, 16kB, 24kB, 32kB, or 48kB)
; Includes search for page 2 slot/subslot at start
; and declares routines to set the page 0 cartridge's slot/subslot
; and to restore the BIOS at page 0
	CFG_INIT_ROM_SIZE:	equ 48

; MSXlib helper: default configuration
	include	"lib/rom-default.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
INIT:

; At this point, the cartridge is init, the RAM zeroed,
; The screen mode 2 with 16x16 unmagnified sprites,
; the keyboard click is muted, and the screen is disabled.

;
; YOUR CODE (ROM) START HERE
;
; Example:
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
	ld	a, $20 ; ' '
	ld	hl, NAMTBL
	ld	bc, NAMTBL_SIZE
	call	FILVRM

; Retrieves data from the page 0
	di
	call	SET_PAGE0.CARTRIDGE
	ld	hl, MY_MESSAGE
	ld	de, message_buffer
	ld	bc, MY_MESSAGE.SIZE
	ldir
	call	SET_PAGE0.BIOS
	ei

; Prints the message retrieved from the page 0
	ld	hl, message_buffer
	ld	de, NAMTBL
	ld	bc, MY_MESSAGE.SIZE
	call	LDIRVM

; Re-enables the screen so we can see the results
	call	ENASCR

; (infinite loop)
.LOOP:
	halt
	jr	.LOOP
; -----------------------------------------------------------------------------

	include	"lib/rom_end.asm"

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

; lib/ram.asm automatically starts the RAM section at the proper address
; (either $C000 (16KB) or $E000 (8KB)) and includes everything MSXlib requires.

;
; YOUR VARIABLES (RAM) START HERE
;
message_buffer:
	rb	MY_MESSAGE.SIZE


; -----------------------------------------------------------------------------

	include	"lib/ram_end.asm"

; EOF
