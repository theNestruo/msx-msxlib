
	CFG_REPLAYER_WYZPLAYER:	equ 1
	CFG_REPLAYER_PT3PLAYER:	equ 2

; =============================================================================
; 	Replayer routines: WYZPlayer v0.47c-based implementation
; =============================================================================

REPLAYER:

; -----------------------------------------------------------------------------
; Initializes the replayer
.RESET:
IF (CFG_REPLAYER = CFG_REPLAYER_WYZPLAYER)
	call	.STOP
; Initializes WYZPlayer sound buffers
	ld	hl, wyzplayer_buffer.a
	ld	[CANAL_A], hl
	ld	hl, wyzplayer_buffer.b
	ld	[CANAL_B], hl
	ld	hl, wyzplayer_buffer.c
	ld	[CANAL_C], hl
	ld	hl, wyzplayer_buffer.p
	ld	[CANAL_P], hl
	ret
ENDIF
IF (CFG_REPLAYER = CFG_REPLAYER_PT3PLAYER)
	call	PT3_MUTE
	jr	.HANDLER
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts the replayer
; param a: song index (0, 1, 2...)
.PLAY:
IF (CFG_REPLAYER = CFG_REPLAYER_WYZPLAYER)
	jp	CARGA_CANCION
ENDIF
IF (CFG_REPLAYER = CFG_REPLAYER_PT3PLAYER)
; ...inicializa la reproducción
	ld	hl, TABLA_SONG.PT3 ; ld	hl, music -100
	call	PT3_INIT
	ld	hl, PT3_SETUP
	res	0, [hl] ; desactiva loop
	ret
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stops the replayer
.STOP:
IF (CFG_REPLAYER = CFG_REPLAYER_WYZPLAYER)
	jp	PLAYER_OFF
ENDIF
IF (CFG_REPLAYER = CFG_REPLAYER_PT3PLAYER)
	jp	PT3_MUTE
ENDIF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Processes a frame in the replayer
.HANDLER:
IF (CFG_REPLAYER = CFG_REPLAYER_WYZPLAYER)
	jp	INICIO
ENDIF
IF (CFG_REPLAYER = CFG_REPLAYER_PT3PLAYER)
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
ENDIF

; -----------------------------------------------------------------------------

IFDEF CFG_REPLAYER_INSTALLABLE

; -----------------------------------------------------------------------------
; Installs the replayer hook in the interruption
.INSTALL:
; Preserves the existing hook
	ld	hl, HTIMI
	ld	de, previous_htimi_hook
	ld	bc, HOOK_SIZE
	ldir
; Install the replayer hook
	di
	ld	hl, .HTIMI_HOOK
	ld	de, HTIMI
	ld	bc, HOOK_SIZE
	ldir
	ei
	ret

; Hook
.HTIMI_HOOK:
	jp	.HTIMI_HOOK_HANDLER
; (padding to match HOOK_SIZE)
	ret
	ret

; Actual hook (invokes both replayer hook previously existing hook)
.HTIMI_HOOK_HANDLER:	
	call	.HANDLER
	jp	previous_htimi_hook
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Removes the replayer hook from the interruption
.UNINSTALL:
; Restores the previously existing hook in the interruption
	di
	ld	hl, previous_htimi_hook
	ld	de, HTIMI
	ld	bc, HOOK_SIZE
	ldir
	ei
	ret
; -----------------------------------------------------------------------------

ENDIF ; CFG_REPLAYER_INSTALLABLE

; -----------------------------------------------------------------------------
IF (CFG_REPLAYER = CFG_REPLAYER_WYZPLAYER)
; WYZPlayer v0.47c
	include	"libext/wyzplayer/WYZPROPLAY47cMSX.ASM"
ENDIF
IF (CFG_REPLAYER = CFG_REPLAYER_PT3PLAYER)
	include	"libext/pt3/PT3-ROM.tniasm.ASM"
ENDIF
; -----------------------------------------------------------------------------

; EOF
