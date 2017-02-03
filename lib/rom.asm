
; -----------------------------------------------------------------------------
	include	"lib/msx/symbols.asm"
	
; MSX cartridge (ROM) header, entry point and initialization
	include "lib/msx/cartridge.asm"
	
; Input routines (BIOS-based)
	include "lib/msx/input.asm"

; VRAM buffers routines (NAMTBL and SPRATR)
; and logical coordinates sprite routines
	include "lib/msx/vram.asm"
; -----------------------------------------------------------------------------
	
; -----------------------------------------------------------------------------
; Generic Z80 assembly convenience routines
	include "lib/asm.asm"
; -----------------------------------------------------------------------------

; EOF
