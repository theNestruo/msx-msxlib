
; =============================================================================
; 	Replayer routines: WYZ PSG proPLAYER v0.47d-based implementation
; =============================================================================

	CFG_RAM_REPLAYER_WYZ:	equ 1

; -----------------------------------------------------------------------------
; Initializes the replayer
REPLAYER.RESET:
; (ensures no WYZ_REPRODUCE_FRAME/ROUT in the middle of WYZ_PLAYER_INIT/WYZ_PLAYER_OFF)
	halt
	jp	WYZ_PLAYER_INIT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts the replayer
; param a: song index (0, 1, 2...)
REPLAYER.PLAY:
	IFDEF CFG_WYZ_PACKED
	; (makes the replayer stop during unpack to avoid corruption)
		push	af ; (preserves song index)
		call	REPLAYER.STOP
		pop	af ; (restores song index)

	; Locates and unpacks the song
		ld	hl, SONG_TABLE
		call	GET_HL_2A_WORD
		IFEXIST unpack_buffer.song
			ld	de, unpack_buffer.song
		ELSE
			ld	de, unpack_buffer
		ENDIF ; IFEXIST unpack_buffer.song
		call	UNPACK

	; (ensures no ROUT in the middle of WYZ_CARGA_CANCION_HL)
		halt
	; Initializes song
		IFEXIST unpack_buffer.song
			ld	hl, unpack_buffer.song
		ELSE
			ld	hl, unpack_buffer
		ENDIF ; IFEXIST unpack_buffer.song
		jp	WYZ_CARGA_CANCION_HL

	ELSE
	; (makes the replayer stop during startup to avoid corruption)
		push	af ; (preserves song index)
		call	REPLAYER.STOP
		pop	af ; (restores song index)
		jp	WYZ_CARGA_CANCION
	ENDIF ; IFDEF CFG_WYZ_PACKED
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
	IFDEF CFG_WYZ_FADE

; Starts a fade-out
REPLAYER.FADE_OUT:
; Prevents double fade-out
	ld	a, [FADE]
	rrca
	ret	c ; (bit set; already fading out)
; (ensures no ROUT in the middle of WYZ_INICIA_FADE_OUT)
	halt
	ld	a, 6
	jp	WYZ_INICIA_FADE_OUT

	ENDIF ; IFDEF CFG_WYZ_FADE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stops the replayer
REPLAYER.STOP:
; (ensures no ROUT in the middle of WYZ_PLAYER_OFF)
	halt
	jp	WYZ_PLAYER_OFF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
	IFDEF CFG_WYZ_SFX

; Starts playing a sound
; param a: sound index
REPLAYER.SOUND:	equ	WYZ_INICIA_EFECTO

	ENDIF ; IFDEF CFG_WYZ_SFX
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Processes a frame in the replayer
REPLAYER.FRAME:	equ	WYZ_REPRODUCE_FRAME
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; WYZ PSG proPLAYER v0.47d
	include	"libext/wyzplayer047d/wyzplayer-ROM.tniasm.asm"
; -----------------------------------------------------------------------------

; EOF
