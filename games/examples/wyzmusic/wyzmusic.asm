
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

; Define to enable packed songs when using the WYZ-based implementation
	; CFG_MUS_PACKED:

; Define to include fade-out support
	; CFG_WYZ_FADE:

; Define to include hybrid tempos (half tempos) support
	; CFG_WYZ_HYBRID:

; Define to include (external) sound effect support
	; CFG_WYZ_SFX:

; WYZ PSG proPLAYER v0.47d-based implementation
	include	"lib/msx/io/replayer_wyz.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Game entry point
INIT:

; Besides the minimal initialization, the MSXlib hook has been installed.
; Initialization includes the replayer (REPLAYER.RESET),
; and the hook already renders a frame of music (REPLAYER.FRAME)

	call	.INIT_SCREEN

; First song
	ld	a, [song_index]
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
	ld	de, namtbl_buffer + SCR_WIDTH * 1
	call	PRINT_TEXT
	inc	hl
	ld	de, namtbl_buffer + SCR_WIDTH * 2
	call	PRINT_TEXT
	inc	hl
	ld	de, namtbl_buffer + SCR_WIDTH * 4 + 2
	call	PRINT_TEXT
	inc	hl
	ld	de, namtbl_buffer + SCR_WIDTH * 5 + 2
	call	PRINT_TEXT

	jp	ENASCR_NO_FADE

.DATA:
	db	"MSXlib WYZ PSG proPLAYER v0.47d", ASCII_NUL
	db	"replayer example", ASCII_NUL
	db	"Song: maryjane2.wyz", ASCII_NUL
	db	"from: WYZTracker demo songs", ASCII_NUL
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
SONG_TABLE:
TABLA_SONG:
	dw	.maryjane2
.maryjane2:
	incbin	"games/examples/wyzmusic/maryjane2.mus"

	include	"games/examples/wyzmusic/maryjane2.mus.asm"
; -----------------------------------------------------------------------------

	include	"lib/rom_end.asm"

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"

; lib/ram.asm automatically starts the RAM section at the proper address
; (either $C000 (16KB) or $E000 (8KB)) and includes everything MSXlib requires.

song_index:
	rb	1
; -----------------------------------------------------------------------------

	include	"lib/ram_end.asm"

; EOF
