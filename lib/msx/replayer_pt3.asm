
	CFG_REPLAYER_PT3:	equ 1

; =============================================================================
; 	Replayer routines: PT3-based implementation
; =============================================================================

; -----------------------------------------------------------------------------
; Initializes the replayer
REPLAYER.RESET:	equ REPLAYER.STOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts the replayer
; param a: liiiiiii, where l (MSB) is the loop flag (0 = loop),
;	and iiiiiii is the 0-based song index (0, 1, 2...)
REPLAYER.PLAY:
	rlca	; (moves loop flag to LSB)
IFDEF CFG_PT3_PACKED
; (makes the replayer stop during unpack to avoid corruption)
	push	af ; (preserves song index)
	call	REPLAYER.STOP
	pop	af ; (restores song index)
ENDIF
	push	af ; (preserves song index)
; Locates the song (1/2)
	and	$fe ; (song index only = 0, 2, 4)
IFDEF CFG_PT3_PACKED
; Locates the song (2/2)
	ld	hl, SONG_PACKED_TABLE
	call	GET_HL_A_WORD
; Unpacks the song
	ld	de, unpack_buffer
	call	UNPACK
IFDEF CFG_PT3_HEADERLESS
	ld	hl, unpack_buffer -100
ELSE
	ld	hl, unpack_buffer
ENDIF ; CFG_PT3_HEADERLESS
ELSE
; Locates the song (2/2)
	ld	hl, SONG_PACKED_TABLE
	call	GET_HL_A_WORD
IFDEF CFG_PT3_HEADERLESS
	ld	bc, -100
	add	hl, bc
ENDIF ; CFG_PT3_HEADERLESS
ENDIF ; CFG_PT3_PACKED
; Initializes song
	call	PT3_INIT
; Saves the configuration (the loop flag)
	pop	af ; (restores song index)
	and	$01 ; (loop flag only)
	ld	[PT3_SETUP], a
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stops the replayer
REPLAYER.STOP:
; Sets "end of the song" marker and no loop
	ld	a, $81
	ld	[PT3_SETUP], a
; Prepares next frame with silence
	jp	PT3_MUTE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Processes a frame in the replayer
REPLAYER.FRAME:
; Plays the actual frame
	call	PT3_ROUT
; Checks if the end of the song has been reached
	ld	hl, PT3_SETUP
	bit	7, [hl]
	jp	z, PT3_PLAY ; no: prepares next frame
; yes: checks if loop is enabled
	bit	0, [hl]
	jp	nz, REPLAYER.STOP ; no
; yes: reactivates the player and prepares next frame
	res	7, [hl]
	jp	PT3_PLAY
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PT3 replayer by Dioniso/MSX-KUN/SapphiRe
	include	"libext/pt3/PT3-ROM.tniasm.ASM"
; -----------------------------------------------------------------------------

; EOF
