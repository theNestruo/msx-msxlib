
; =============================================================================
; 	Replayer vars and buffers: WYZPlayer v0.47c-based implementation
; =============================================================================

; -----------------------------------------------------------------------------
IFDEF CFG_REPLAYER_INSTALLABLE

; Backup of the H.TIMI hook previous to the installation of the replayer hook
previous_htimi_hook:
	rb	HOOK_SIZE
	
; 60Hz replayer syncrhonization
replayer_frameskip:
	rb	1

ENDIF

IFDEF CARGA_CANCION

; WYZPlayer v0.47c variables
	include	"libext/wyzplayer/wyzplayer047c-ram.tniasm.asm"

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
; -----------------------------------------------------------------------------

; EOF
