
IFDEF CFG_RAM_VRAM
; -----------------------------------------------------------------------------
; Variables for: NAMBTL and SPRATR buffer routines (BIOS-based)

; NAMTBL buffer in RAM ; (aligned to $xx00)
namtbl_buffer:
	rb	NAMTBL_SIZE

; SPRATR buffer in RAM ; (aligned to $xx00)
spratr_buffer:
	rb	SPRATR_SIZE
.end:
	rb	1 ; to store one SPAT_END when the buffer is full

IFDEF CFG_SPRITES_FLICKER

; (extra space for the flickering routine)
	rb	SPRATR_SIZE -CFG_SPRITES_NO_FLICKER *4 -16

; Offset used by the flickering routine
.flicker_offset:
	rb	1

ENDIF ; IFDEF CFG_SPRITES_FLICKER
; -----------------------------------------------------------------------------
ENDIF ; IFDEF CFG_RAM_VRAM



IFDEF CFG_RAM_CARTRIDGE
; -----------------------------------------------------------------------------
; Variables for: MSX cartridge (ROM) header, entry point and initialization

; Refresh rate in Hertzs (50Hz/60Hz) and related convenience vars
frame_rate:
	rb	1
frames_per_tenth:
	rb	1
; -----------------------------------------------------------------------------
ENDIF ; IFDEF CFG_RAM_CARTRIDGE


IFDEF CFG_RAM_HOOK
; -----------------------------------------------------------------------------
; Variables for: Interrupt routine (H.TIMI hook)

IFDEF CFG_INIT_USE_HIMEM_KEEP_HOOKS
; Backup of the H.TIMI hook previous to the installation of the replayer hook
old_htimi_hook:
	rb	HOOK_SIZE
ENDIF ; IFDEF CFG_INIT_USE_HIMEM_KEEP_HOOKS

IFEXIST REPLAYER.FRAME

; 60Hz replayer synchronization
replayer.frameskip:
	rb	1

ENDIF ; IFEXIST REPLAYER.FRAME
; -----------------------------------------------------------------------------
ENDIF ; IFDEF CFG_RAM_HOOK


IFDEF CFG_RAM_INPUT
; -----------------------------------------------------------------------------
; Variables for: Input routines (BIOS-based)

; Stores joystick and keyboard as a bit map
input:
	.level:
	rb	1
	.edge:
	rb	1
; -----------------------------------------------------------------------------
ENDIF ; IFDEF CFG_RAM_INPUT


IFDEF CFG_RAM_REPLAYER_PT3
; -----------------------------------------------------------------------------
; Variables for: Replayer routines: PT3-based implementation

; PT3 variables
	include	"libext/pt3/PT3-RAM.tniasm.ASM"

IFEXIST ayFX_SETUP

; ayFX REPLAYER v1.31 variables
	include	"libext/ayFX-replayer/ayFX-RAM.tniasm.asm"

ENDIF ; IFEXIST ayFX_SETUP
; -----------------------------------------------------------------------------
ENDIF ; IFDEF CFG_RAM_REPLAYER_PT3


IFDEF CFG_RAM_REPLAYER_WYZ
; -----------------------------------------------------------------------------
; Variables for: Replayer routines: WYZPlayer v0.47c-based implementation

; WYZPlayer v0.47c variables
	include	"libext/wyzplayer/WYZPROPLAY47c_RAM.tniasm.ASM"
; -----------------------------------------------------------------------------
ENDIF ; IFDEF CFG_RAM_REPLAYER_WYZ


; EOF
