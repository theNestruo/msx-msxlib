
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

; MSXlib splash screen
SPLASH_SCREENS_PACKED_TABLE:
	db	1
	dw	$ + 2
	incbin	"splash/msxlib.bin.zx0"

; Interrupt routine (hook)
	include "lib/msx/hook.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Input routines (BIOS-based)
	include "lib/msx/io/input.asm"

; Keyboard input routines
; (note: these routines change OLDKEY/NEWKEY semantics!)
	include "lib/msx/io/keyboard.asm"

; Timing and wait routines
	include "lib/msx/io/timing.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VRAM routines (BIOS-based)
; NAMBTL and SPRATR buffer routines (BIOS-based)
	include "lib/msx/io/vram.asm"

; NAMTBL buffer text and block routines
	include "lib/msx/io/print.asm"

; Additional NAMBTL and SPRATR buffer based routines
	include "lib/msx/etc/fade.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Logical coordinates sprite routines
	include "lib/msx/io/sprites.asm"

; Logical-to-physical sprite coordinates offsets (pixels)
	CFG_SPRITES_X_OFFSET:	equ -8
	CFG_SPRITES_Y_OFFSET:	equ -17
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Unpacker routine (ZX0 decoder-based implementation)
	include	"lib/unpack/unpack_zx0.asm"

; Buffer size to check it actually fits before system variables
	CFG_RAM_RESERVE_BUFFER:	equ 2048
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Generic Z80 assembly convenience routines
	include "lib/asm/asm.asm"
; -----------------------------------------------------------------------------

; EOF
