
; =============================================================================
; 	MSX cartridge (ROM) header, entry point and initialization
; =============================================================================

; -----------------------------------------------------------------------------
; Cartridge header
	org	$4000, $bfff
ROM_START:
	db	"AB"		; ID ("AB")
	dw	.INIT		; INIT
	ds	$4010 - $, $00	; STATEMENT, DEVICE, TEXT, Reserved
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Data

; RAM check warning text
IFDEF CFG_INIT_16KB_RAM
.TXT:
	db	"16KB RAM REQUIRED"
	.TXT_SIZE:	equ $ - .TXT
ENDIF ; CFG_INIT_16KB_RAM

; Frame rate related values
.FRAME_RATE_50HZ_0:
	db	50	; frame rate
	db	5	; frames per tenth
	
.FRAME_RATE_60HZ_0:
	db	60	; frame rate
	db	6	; frames per tenth
	
	.FRAME_RATE_SIZE:	equ $ - .FRAME_RATE_60HZ_0
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Cartridge entry point
; System initialization: stack pointer, slots, RAM, CPU, VDP, PSG, etc.
.INIT:
; Ensures interrupt mode and stack pointer
; (perhaps this ROM is not the first thing to be loaded)
	di
	im	1
	ld	sp, [HIMEM]

IFDEF CFG_INIT_32KB_ROM
; Reads the primary slot of the page 1
	call    RSLREG	; a = 33221100
	rrca
	rrca
	and	$03	; a = xxxxxxPP
	ld	c, a	; c = xxxxxxPP
; Reads the expanded slot flag
	ld	hl, EXPTBL ; EXPTBL + a => EXPTBL for slot of page 1
	add	a, l
	ld	l, a
	ld	a, [hl]
	and	$80	; a = Exxxxxxx
; Defines slot ID (1/2)
	or	c	; a = ExxxxxPP
	ld	c, a	; c = ExxxxxPP
; Reads the secondary slot selection register
	inc	l ; hl += 4 => = SLTTBL for slot of page 1
	inc	l
	inc	l
	inc	l
	ld	a, [hl]
	and	$0c	; a = xxxxSSxx
; Define slot ID (2/2)
	or	c	; a = ExxxSSPP
; Enable
	ld	h, $80 ; Bit 6 and 7: page 2 ($8000)
	call	ENASLT
ENDIF ; CFG_INIT_32KB_ROM

IFDEF CFG_INIT_16KB_RAM
; RAM: checks availability of 16kB
	ld	hl, ram_start
	ld	a, [hl]
	cpl
	ld	[hl], a
	xor	[hl]
	jr	z, .RAM_OK ; yes

; no: screen 1 and warning text
	call	INIT32
	ld	hl, .TXT
	ld	de, NAMTBL + (SCR_WIDTH-.TXT_SIZE)/2 + 11*SCR_WIDTH
	ld	bc, 17
	call	LDIRVM
; halts the execution
	di
	halt
.RAM_OK:
ENDIF ; CFG_INIT_16KB_RAM

; CPU: Ensures Z80 mode
	ld	a, [MSXID3]
	cp	3 ; 3 = MSX turbo R
	jr	nz, .CPU_OK
; MSX turbo R: switches to Z80 mode
	ld	a, $80 ; also disables the LED
	call	CHGCPU
.CPU_OK:

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

; Zeroes all the used RAM
	ld	hl, ram_start
	ld	de, ram_start +1
	ld	bc, ram_end - ram_start  -1
	ld	[hl], 0
	ldir

; Frame rate related variables
; Chooses the proper source (50Hz or 60Hz)
	ld	a, [MSXID1]
	bit	7, a ; 0=60Hz, 1=50Hz
	ld	hl, .FRAME_RATE_50HZ_0
	ld	bc, .FRAME_RATE_SIZE
	jr	nz, .HL_OK
; skips the 50Hz entry and goes to the 60Hz entry
	add	hl, bc
.HL_OK:
; blits the correct entry
	ld	de, frame_rate
	; ld	bc, .FRAME_RATE_SIZE ; (unecessary)
	ldir

; PSG: silence
	call	GICINI

; Skips to the game entry point
	jp	MAIN_INIT
; -----------------------------------------------------------------------------

; EOF
