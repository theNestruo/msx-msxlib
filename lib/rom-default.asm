
;
; =============================================================================
;	MSXlib helper: default configuration
; =============================================================================
;

; -----------------------------------------------------------------------------
; MSX symbolic constants
	include	"lib/msx/symbols.asm"
; -----------------------------------------------------------------------------

; =============================================================================
;	ROM
; =============================================================================

; -----------------------------------------------------------------------------
; MSX cartridge (ROM) header, entry point and initialization
	include "lib/msx/cartridge.asm"

; ; MSXlib splash screen
; SPLASH_SCREENS_PACKED_TABLE:
	; db	1
	; dw	$ + 2
	; incbin	"splash/msxlib.bin.zx7"

; Interrupt routine (hook)
	include "lib/msx/hook.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VRAM routines (BIOS-based)
; NAMBTL and SPRATR buffer routines (BIOS-based)
; NAMTBL buffer text routines
; Logical coordinates sprite routines
	include "lib/msx/io/vram.asm"

; Logical-to-physical sprite coordinates offsets (pixels)
	CFG_SPRITES_X_OFFSET:	equ -8
	CFG_SPRITES_Y_OFFSET:	equ -17

; Input, timing & pause routines (BIOS-based)
	include "lib/msx/io/input.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Generic Z80 assembly convenience routines
	include "lib/asm/asm.asm"
; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; ; Unpacker routine

; ; ZX7 decoder by Einar Saukas, Antonio Villena & Metalbrain
; ; "Standard" version (69 bytes only)
; ; param hl: packed data source address
; ; param de: destination buffer address
	; UNPACK: equ dzx7_standard
	; include	"libext/zx7/dzx7_standard.tniasm.asm"

; ; Buffer size to check it actually fits before system variables
	; CFG_RAM_RESERVE_BUFFER:	equ 2048
; ; -----------------------------------------------------------------------------

; EOF
