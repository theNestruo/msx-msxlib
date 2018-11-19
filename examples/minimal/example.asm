
;
; =============================================================================
;	MSXlib core configuration, routines and initialization
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSX cartridge (ROM) header, entry point and initialization

; Define if the ROM is larger than 16kB (typically, 32kB)
; Includes search for page 2 slot/subslot at start
	; CFG_INIT_32KB_ROM:

; Define if the game needs 16kB instead of 8kB
; RAM will start at the beginning of the page 2 instead of $e000
; and availability will be checked at start
	; CFG_INIT_16KB_RAM:
	
; MSX symbolic constants
	include	"lib/msx/symbols.asm"
; MSX cartridge (ROM) header, entry point and initialization
	include "lib/msx/cartridge.asm"
; -----------------------------------------------------------------------------

;
; =============================================================================
; 	Game code and data
; =============================================================================
;

; -----------------------------------------------------------------------------
; Game entry point
MAIN_INIT:

; (prepares an uninspired charset)
	ld	hl, [CGTABL]
	ld	de, CHRTBL
	ld	bc, CHRTBL_SIZE
	call	LDIRVM
; (white over black)
	ld	a, $F0
	ld	hl, CLRTBL
	ld	bc, CHRTBL_SIZE
	call	FILVRM

; CLS	
	ld	a, $20 ; ' '
	ld	hl, NAMTBL
	ld	bc, NAMTBL_SIZE
	call	FILVRM
	
; Prints a message
	ld	hl, HELLO_WORLD
	ld	de, NAMTBL
	ld	bc, HELLO_WORLD.SIZE
	call	LDIRVM
	
; Enables the screen
	call	ENASCR

; Infinite loop
.LOOP:
	halt
	jr	.LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; The message to print
HELLO_WORLD:
	db	"Hello, World!"
	.SIZE:	equ $ - HELLO_WORLD
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Padding to a 8kB boundary
PADDING:
	ds	($ OR $1fff) -$ +1, $ff ; $ff = rst $38
	.SIZE:	equ $ - PADDING
; -----------------------------------------------------------------------------

;
; =============================================================================
;	RAM
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"
; -----------------------------------------------------------------------------

ram_end:

; -----------------------------------------------------------------------------
; (for debugging purposes only)
	bytes_rom_MSXlib_code:	equ MAIN_INIT - ROM_START
	bytes_rom_game_code:	equ PADDING - MAIN_INIT

	; bytes_ram_MSXlib:	equ globals - ram_start
	; bytes_ram_game:		equ ram_end - globals
	
	bytes_total_rom:	equ PADDING - ROM_START
	bytes_total_ram:	equ ram_end - ram_start

	bytes_free_rom:		equ PADDING.SIZE
	bytes_free_ram:		equ $f380 - $
; -----------------------------------------------------------------------------

; EOF
