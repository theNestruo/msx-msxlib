
;
; =============================================================================
;	MSXlib minimal example
; =============================================================================
;

; -----------------------------------------------------------------------------
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
; and prints a simple message
	ld	a, $20 ; ' '
	ld	hl, NAMTBL
	ld	bc, NAMTBL_SIZE
	call	FILVRM
	ld	hl, .MY_MESSAGE
	ld	de, NAMTBL
	ld	bc, .MY_MESSAGE_SIZE
	call	LDIRVM

; Re-enables the screen so we can see the results
	call	ENASCR

; (infinite loop)
.LOOP:
	halt
; Key pressed?
	ld	a, [input.edge]
	or	a
	jr	z, .LOOP ; no
; yes

; Change border color to 14
	ld	a, 14
	ld	[BDRCLR], a
	halt	; (sync)
	call	CHGCLR
; Restore border color to 0
	xor	a
	ld	[BDRCLR], a
	halt	; (sync)
	call	CHGCLR
	jr	.LOOP

; Reference:
;	CHGCLR:	equ $0062 ; Change VDP colours (BIOS routine)
;	BDRCLR:	equ $f3eb ; Border colour (BIOS system variable)

; The message to print
.MY_MESSAGE:
	db	"Hello, World!"
	.MY_MESSAGE_SIZE:	equ $ - .MY_MESSAGE
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

; -----------------------------------------------------------------------------

	include	"lib/ram_end.asm"

; EOF
