
; -----------------------------------------------------------------------------
; MSX symbolic constants
	include	"lib/msx/symbols.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Cartridge header & entry point
	org	$8000, $bfff
ROM_START:
	db	"AB"		; ID ("AB")
	dw	.INIT		; INIT
	ds	$8010 - $, $00	; STATEMENT, DEVICE, TEXT, Reserved
.INIT:
; Ensures interrupt mode and stack pointer
; (perhaps this ROM is not the first thing to be loaded)
	di
	im	1
	ld	sp, [HIMEM]
	ei

; WYZPlayer test code

; Initializes the replayer
	call	PLAYER_OFF
	LD	HL, wyzplayer_buffer.a
	LD	[CANAL_A],HL
	LD	HL, wyzplayer_buffer.b
	LD	[CANAL_B],HL
	LD	HL, wyzplayer_buffer.c
	LD	[CANAL_C],HL
	LD	HL, wyzplayer_buffer.p
	LD	[CANAL_P],HL
; Loads song #0
	LD	A, 0
	CALL	CARGA_CANCION
; Sets envelope wave shape (unnecessary since 0.47c?)
	; LD	A, $0e		; $0e = "/\/\/\/\"
	; LD	[PSG_REG+13], A ; Envelope Wave Shape

; Plays the song (witout using the interrupt)
.LOOP:
	halt
	call	INICIO
	jr	.LOOP

; Replayer routines (WYZPlayer v0.47c-based implementation)
	include	"lib\msx\replayer.asm"

; WYZPlayer test data
TABLA_SONG:
	dw	.SONG_0
.SONG_0:
	incbin	"games/wyzplayer-test/knightmare_start.mus"

	include	"games/wyzplayer-test/knightmare_start.mus.asm"

; Padding to a 8kB boundary
	ds	($ OR $1fff) -$ +1, $ff ; $ff = rst $38
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; MSXlib core and game-related variables
	include	"lib/ram.asm"
ram_end:
; -----------------------------------------------------------------------------

; EOF
