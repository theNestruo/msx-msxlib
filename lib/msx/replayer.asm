
; =============================================================================
; 	Replayer routines: WYZPlayer v0.47c-based implementation
; =============================================================================

REPLAYER:

; -----------------------------------------------------------------------------
; Initializes the replayer
.RESET:
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
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Starts the replayer
; param a: song index (0, 1, 2...)
.PLAY:		equ CARGA_CANCION
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stops the replayer
.STOP:		equ PLAYER_OFF
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Processes a frame in the replayer
.HANDLER:	equ INICIO
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
; WYZPlayer v0.47c
	include	"libext/wyzplayer/WYZPROPLAY47cMSX.ASM"
; -----------------------------------------------------------------------------

; EOF
