
; =============================================================================
; 	Replayer routines: PT3-based implementation
; =============================================================================

	CFG_RAM_REPLAYER_PT3:	equ 1

; -----------------------------------------------------------------------------
; Initializes the replayer
REPLAYER.RESET:
IFEXIST ayFX_SETUP
; Initializes the PT3 replayer
	call	REPLAYER.STOP
; Initializes the ayFX replayer
	ld	hl, SOUND_BANK
	jp	ayFX_SETUP
ELSE ; IFEXIST ayFX_SETUP
	; REPLAYER.RESET: equ REPLAYER.STOP ; falls through
ENDIF ; IFEXIST ayFX_SETUP
; ------VVVV----falls through--------------------------------------------------

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
; Starts the replayer
; param a: liiiiiii, where l (MSB) is the loop flag (0 = loop),
;	and iiiiiii is the 0-based song index (0, 1, 2...)
REPLAYER.PLAY:
IFDEF CFG_PT3_PACKED
; (makes the replayer stop during unpack to avoid corruption)
	push	af ; (preserves song index)
	call	REPLAYER.STOP
	pop	af ; (restores song index)
ENDIF ; CFG_PT3_PACKED

; Locates the song (1/2)
	rlca	; (moves loop flag to LSB)
	push	af ; (preserves song index)
	and	$fe ; (song index only = 0, 2, 4)

IFDEF CFG_PT3_PACKED
; Locates the song (2/2, packed)
	ld	hl, SONG_TABLE
	call	GET_HL_A_WORD
; Unpacks the song
	ld	de, unpack_buffer
	call	UNPACK
	ld	hl, unpack_buffer

ELSE ; CFG_PT3_PACKED
; Locates the song (2/2, unpacked)
	ld	hl, SONG_TABLE
	call	GET_HL_A_WORD
ENDIF ; CFG_PT3_PACKED

REPLAYER.PLAY_HL_OK:
; Adjusts the song pointer
IFDEF CFG_PT3_HEADERLESS
	ld	bc, -100
	add	hl, bc
ENDIF
; Initializes song
	call	PT3_INIT
; Saves the configuration (the loop flag)
	pop	af ; (restores song index)
	and	$01 ; (loop flag only)
	ld	[PT3_SETUP], a
	ret
; -----------------------------------------------------------------------------

IFDEF CFG_PT3_PACKED

; -----------------------------------------------------------------------------
; Starts the replayer over an un packed song
; param hl: pointer to the unpacked song
; param a: lxxxxxxx, where l (MSB) is the loop flag (0 = loop)
REPLAYER.PLAY_UNPACKED:
	rlca	; (moves loop flag to LSB)
	push	af ; (preserves song index)
	jr	REPLAYER.PLAY_HL_OK
; -----------------------------------------------------------------------------

ENDIF ; CFG_PT3_PACKED

; -----------------------------------------------------------------------------
; Processes a frame in the replayer
REPLAYER.FRAME:
; Plays the actual frame
	call	PT3_ROUT

IFEXIST ayFX_PLAY
; Prepares both PT3 and ayFX next frame
	call	.PT3
	jp	ayFX_PLAY
.PT3:
ENDIF ; IFEXIST ayFX_PLAY

; Prepares PT3 next frame
; Checks if the end of the song has been reached
	ld	a, [PT3_SETUP]
	bit	7, a ; "bit7 is set each time, when loop point is passed"
	jp	z, PT3_PLAY ; no: prepares next frame
; yes: Checks if loop is enabled
	bit	0, a ; "set bit0 to 1, if you want to play without looping"
	ret	nz ; no: does nothing
; yes: reactivates the player and prepares next frame
	res	7, a
	ld	[PT3_SETUP], a
	jp	PT3_PLAY
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PT3 replayer by Dioniso/MSX-KUN/SapphiRe
	include	"libext/pt3/PT3-ROM.tniasm.ASM"
; -----------------------------------------------------------------------------


; EOF
