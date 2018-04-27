
; =============================================================================
; 	Replayer vars and buffers: WYZPlayer v0.47c-based implementation
; =============================================================================

; -----------------------------------------------------------------------------
IFDEF REPLAYER.FRAME

replayer:

; 60Hz replayer syncrhonization
.frameskip:
	rb	1

; Backup of the H.TIMI hook previous to the installation of the replayer hook
.old_htimi_hook:
	rb	HOOK_SIZE

ENDIF

IFDEF CFG_REPLAYER_PT3

; PT3 variables
	include	"libext/pt3/PT3-RAM.tniasm.ASM"

ENDIF


IFDEF CFG_REPLAYER_WYZPLAYER

; WYZPlayer v0.47c variables
	include	"libext/wyzplayer/WYZPROPLAY47c_RAM.tniasm.ASM"

; WYZPlayer sound buffers. Recommended at least $10 bytes per channel
wyzplayer_buffer:
.a:
	rb	$20
.b:
	rb	$20
.c:
	rb	$20
.p:
	rb	$20

ENDIF


IFDEF CFG_REPLAYER_AYFX

; ayFX REPLAYER v1.31 variables
	include	"libext/ayFX-replayer/ayFX-RAM.tniasm.asm"

ENDIF
; -----------------------------------------------------------------------------

; EOF
