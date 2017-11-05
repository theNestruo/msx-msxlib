
	CFG_REPLAYER_PT3PLAYER:	equ 1

; =============================================================================
; 	Replayer routines: PT3-based implementation
; =============================================================================

; -----------------------------------------------------------------------------
; Initializes the replayer
REPLAYER.RESET:
	call	PT3_MUTE
	jp	PT3_ROUT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Processes a frame in the replayer
REPLAYER.FRAME:
	; ld	hl, PT3_SETUP
	; bit	0, [hl]
	; ret	z ; no (está en modo bucle)
	; bit	7, [hl]
	; ret	nz
; frame normal: reproduce música
	; di	; innecesario (estamos en la interrupción)
	call	PT3_ROUT
	call	PT3_PLAY
	; ei	; innecesario (estamos en la interrupción)
; comprueba si se ha llegado al final de la canción
	; ld	hl, PT3_SETUP
	; bit	0, [hl]
	; ret	z ; no (está en modo bucle)
	; bit	7, [hl]
	; ret	z ; no (no ha terminado)
; sí: detiene automáticamente el reproductor
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts the replayer
; param a: song index (0, 1, 2...)
REPLAYER.PLAY:
; ...inicializa la reproducción
	ld	hl, TABLA_SONG.SONG_0 ; ld	hl, music -100
	call	PT3_INIT
	ld	hl, PT3_SETUP
	res	0, [hl] ; desactiva loop
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stops the replayer
REPLAYER.STOP:	equ	PT3_MUTE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PT3 replayer by Dioniso/MSX-KUN/SapphiRe
	include	"libext/pt3/PT3-ROM.tniasm.ASM"
; -----------------------------------------------------------------------------

; EOF
