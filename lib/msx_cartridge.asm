
; =============================================================================
; 	Global symbolic constants
; =============================================================================

; -----------------------------------------------------------------------------
; BIOS entry points
	.bios

; ROM (BIOS constants)
	VDP_DR	equ $0006 ; Base port address for VDP data read
	VDP_DW	equ $0007 ; Base port address for VDP data write
	MSXID1	equ $002b ; Frecuency, date format, charset
	MSXID3	equ $002d ; MSX version number

; RAM (system vars)
	CLIKSW	equ $f3db ; Keyboard click sound
	RG1SAV	equ $f3e0 ; Content of VDP(1) register (R#1)
	FORCLR	equ $f3e9 ; Foreground colour
	BAKCLR	equ $f3ea ; Background colour
	BDRCLR	equ $f3eb ; Border colour
	NEWKEY	equ $fbe5 ; Current state of the keyboard matrix ($fbe5-$fbef)
	HIMEM 	equ $fc4a ; High free RAM address available (init stack with)

; RAM (hooks)
	HKEYI	equ $fd9a ; Interrupt handler
	HTIMI	equ $fd9f ; Interrupt handler
	HOOK_SIZE	equ HTIMI - HKEYI

; VRAM addresses
	CHRTBL	equ $0000 ; Pattern table
	NAMTBL	equ $1800 ; Name table
	CLRTBL	equ $2000 ; Color table
	SPRATR	equ $1B00 ; Sprite attributes table
	SPRTBL	equ $3800 ; Sprite pattern table

; VRAM symbolic constants
	SCR_WIDTH	equ 32
	SCR_HEIGHT	equ 24
	NAMTBL_SIZE	equ SCR_HEIGHT * SCR_WIDTH
	CHRTBL_SIZE	equ 256 * 8
	SPRTBL_SIZE	equ 64 *32
	SPRATR_SIZE	equ 32 *4
	SPAT_END	equ $d0 ; Sprite attribute table end marker
	SPAT_OB		equ $d1 ; Sprite out of bounds marker (not standard)
	SPAT_EC		equ $80 ; Early clock bit (32 pixels)
; -----------------------------------------------------------------------------

; =============================================================================
; 	MSX cartridge (ROM) header, entry point and initialization
; =============================================================================

; -----------------------------------------------------------------------------
; Cartridge header
	.page	1
rom_start:
	.rom			; ID ("AB")
	.start	CARTRIDGE_INIT	; INIT
	nop			; random NOPs make asmsx happy
	nop
	nop
	.org	rom_start + $10	; STATEMENT, DEVICE, TEXT, Reserved

	.printtext	"-----Cartridge header---------$4000-ROM-"
	.printhex	$
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Cartridge entry point
; System initialization: stack pointer, slots, RAM, CPU, VDP, PSG, etc.
CARTRIDGE_INIT:
; Ensures interrupt mode and stack pointer
; (perhaps this ROM is not the first thing to be loaded)
	di
	im	1
	ld	sp, [HIMEM]

IF (CFG_INIT_32KB_ROM > 0)
; Automatically locates slot and subslot for the page 2
	.search
ENDIF ; (CFG_INIT_32KB_ROM > 0)

IF (CFG_INIT_16KB_RAM > 0)
; RAM: checks availability of 16kB
	ld	hl, ram_start
	ld	a, [hl]
	cpl
	ld	[hl], a
	xor	[hl]
	jr	z, @@RAM_OK ; yes

; no: screen 1 and warning text
	call	INIT32
	ld	hl, @@TXT
	ld	de, NAMTBL + (SCR_WIDTH - 17) /2 + 11 *SCR_WIDTH
	ld	bc, 17
	call	LDIRVM
; halts the execution
	di
	halt
@@TXT:
	.db	"16KB RAM REQUIRED" ; 17 bytes
@@RAM_OK:
ENDIF ; (CFG_INIT_16KB_RAM > 0)

; CPU: Ensures Z80 mode
	ld	a, [MSXID3]
	cp	3 ; 3 = MSX turbo R
	jr	nz, @@CPU_OK
; MSX turbo R: switches to Z80 mode
	ld	a, $80 ; also disables the LED (besides the R800)
	call	CHGCPU
@@CPU_OK:

; VDP: color 15,1,1
	ld	a, 15
	ld	[FORCLR], a
	ld	a, 1
	ld	[BAKCLR], a
	ld	[BDRCLR], a
; VDP: screen 2
	call	INIGRP
	call	DISSCR
; screen ,2
	ld	hl, RG1SAV
	set	1, [hl]
; screen ,,0
	xor	a
	ld	[CLIKSW], a

; PSG: silence
	call	GICINI

; Zeroes all the used RAM
	ld	hl, ram_start
	ld	de, ram_start +1
	ld	bc, ram_end - ram_start  -1
	ld	[hl], 0
	ldir

; Frame rate dependant variables
; Chooses the proper source (50Hz or 60Hz)
	ld	a, [MSXID1]
	bit	7, a ; 0=60Hz, 1=50Hz
	ld	hl, FRAME_RATE_50HZ_0
	ld	bc, FRAME_RATE_SIZE
	jr	nz, @@HL_OK
; skips the 50Hz entry and goes to the 60Hz entry
	add	hl, bc
@@HL_OK:
; blits the correct entry
	ld	de, frame_rate
	ld	bc, FRAME_RATE_SIZE
	ldir

; IF (CFG_OPTIONAL_PT3HOOK > 0)
; ; preserva la rutina de interrupción que pudiera existir
	; ld	hl, HTIMI
	; ld	de, old_htimi_hook
	; ld	bc, HOOK_SIZE
	; ldir
; ENDIF ; (CFG_OPTIONAL_PT3HOOK > 0)

; salta hasta el punto de entrada principal del juego
	jp	MAIN
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; frame_rate / frames_per_tenth
FRAME_RATE_50HZ_0:
	.db	50, 5
	FRAME_RATE_SIZE	equ $ - FRAME_RATE_50HZ_0
	
FRAME_RATE_60HZ_0:
	.db	60, 6
; -----------------------------------------------------------------------------

	.printtext	" ... msxlib init"
	.printhex	$

; EOF
