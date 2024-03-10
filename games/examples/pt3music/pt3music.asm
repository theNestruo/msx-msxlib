
;
; =============================================================================
;	MSXlib basic example
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSXlib helper: default configuration
	include	"lib/rom-default.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Replayer routines

; Define to enable packed songs when using the PT3-based implementation
	; CFG_PT3_PACKED:

; Define to use headerless PT3 files (without first 100 bytes)
	; CFG_PT3_HEADERLESS:

; PT3-based implementation
	include	"lib/msx/io/replayer_pt3.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
INIT:

; Besides the minimal initialization, the MSXlib hook has been installed.
; Initialization includes the replayer (REPLAYER.RESET),
; and the hook already renders a frame of music (REPLAYER.FRAME)

	call	.INIT_SCREEN

; First song
	xor	a
	call	REPLAYER.PLAY

; (infinite loop)
.LOOP:
	halt			; (sync)
	jr	.LOOP

.INIT_SCREEN:
	ld	hl, [CGTABL]
	ld	de, CHRTBL
	ld	bc, $800
	call	LDIRVM

	ld	a, $f0
	ld	hl, CLRTBL
	ld	bc, $800
	call	FILVRM

	ld	hl, .DATA
	ld	de, namtbl_buffer + SCR_WIDTH * 1 + 2
	call	PRINT_TEXT
	inc	hl
	ld	de, namtbl_buffer + SCR_WIDTH * 3 + 2
	call	PRINT_TEXT
	inc	hl
	ld	de, namtbl_buffer + SCR_WIDTH * 4 + 2
	call	PRINT_TEXT

	jp	ENASCR_NO_FADE

.DATA:
	db	"MSXlib PT3 replayer example", ASCII_NUL
	db	"Song: RUN23 - Shuffle 1", ASCII_NUL
	db	"  by: KNM 2003-2023", ASCII_NUL
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
SONG_TABLE:
	dw	.ShuffleOne
.ShuffleOne:
	incbin	"games/examples/pt3music/RUN23_ShuffleOne.pt3"
; -----------------------------------------------------------------------------

	include	"lib/rom_end.asm"

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

; lib/ram.asm automatically starts the RAM section at the proper address
; (either $C000 (16KB) or $E000 (8KB)) and includes everything MSXlib requires.
; -----------------------------------------------------------------------------

	include	"lib/ram_end.asm"

; EOF
