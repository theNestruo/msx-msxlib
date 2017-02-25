
; =============================================================================
; 	RAM
; =============================================================================

IFDEF CFG_INIT_16KB_RAM
	org	$c000, $f380
ELSE
	org	$e000, $f380
ENDIF
ram_start:

; -----------------------------------------------------------------------------
; Vars for the initialization routines
	include	"lib\msx\cartridge.ram.asm"

; Vars for the input routines
	include	"lib\msx\input.ram.asm"

; NAMBTL and SPRATR buffers
	include	"lib\msx\vram.ram.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Player vars
	include	"lib\game\player.ram.asm"

; Enemies array
	include	"lib\game\enemy.ram.asm"
	
; Bullet array
	include	"lib\game\bullet.ram.asm"
; -----------------------------------------------------------------------------

; EOF
