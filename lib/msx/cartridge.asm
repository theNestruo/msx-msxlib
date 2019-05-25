
; =============================================================================
; 	MSX cartridge (ROM) header, entry point and initialization
; =============================================================================

	CFG_RAM_CARTRIDGE:	equ 1

; -----------------------------------------------------------------------------
; Cartridge header
	org	$4000, $bfff
CARTRIDGE_HEADER:
	db	"AB"		; ID ("AB")
	dw	CARTRIDGE_INIT	; INIT
	dw	$0000		; STATEMENT
	dw	$0000		; DEVICE
	dw	$0000		; TEXT
.RESERVED:
	ds	$4010 - $, $00	; Reserved
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

IFDEF CFG_INIT_32KB_ROM
; Is the game running on RAM? (e.g.: ROM Loader)
	ld	hl, $400a ; (first reserved byte of the cartridge header)
	ld	a, [hl]
	cpl
	ld	[hl], a
	xor	[hl]
	jr	z, .RAM_OK ; yes
; No: Reads the primary slot of the page 1
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
	jr	z, .RAM_OK ; yes (value was written)

; no: screen 1 and warning text
	call	INIT32
	ld	hl, .TXT
	ld	de, NAMTBL + (SCR_WIDTH-.TXT_SIZE)/2 + 11*SCR_WIDTH
	ld	bc, 17
	call	LDIRVM
; halts the execution
	di
	halt
	
; RAM check warning text
.TXT:
	db	"16KB RAM REQUIRED"
	.TXT_SIZE:	equ $ - .TXT
ENDIF ; CFG_INIT_16KB_RAM
.RAM_OK:

; CPU: Ensures Z80 mode
	ld	a, [MSXID3]
	cp	3 ; 3 = MSX turbo R
	jr	nz, .CPU_OK
; MSX turbo R: switches to Z80 mode
	ld	a, $80 ; also disables the LED
	call	CHGCPU
.CPU_OK:

; Splash screens before further initialization
IFEXIST SPLASH_SCREENS_PACKED_TABLE
; Reads the number of splash screens to show
	ld	hl, SPLASH_SCREENS_PACKED_TABLE
	ld	b, [hl]
	inc	hl
	
; For each splash screen
.SPLASH_LOOP:
	push	bc ; preserves counter
	push	hl ; preserves pointer
; Unpacks the actual splash screen 
	call	LD_HL_HL
	ld	de, $e000
	call	UNPACK
; Invokes the splash screen routine
	call	$e000
; Goes for the next splash screen
	pop	hl ; restores pointer
	inc	hl
	inc	hl
	pop	bc ; restores counter
	djnz	.SPLASH_LOOP
ENDIF ; IFEXIST SPLASH_SCREENS_PACKED_TABLE

; VDP: color 15,1,1
	ld	a, 15
	ld	[FORCLR], a
	ld	a, 1
	ld	[BAKCLR], a
	ld	[BDRCLR], a
; VDP: screen 2
	call	INIGRP
; screen ,2
	call	DISSCR
	ld	hl, RG1SAV
	set	1, [hl] ; (first call to ENASCR will actually apply to the VDP)
; screen ,,0
	xor	a
	ld	[CLIKSW], a

IFEXIST SET_PALETTE
; MSX2 VDP: Custom palette
	ld	a, [MSXID3]
	or	a
	jr	z, .PALETTE_OK ; not MSX2
; Is the 1 key or 2 key down?
	xor	a ; 7 6 5 4 3 2 1 0
	call	SNSMAT
	ld	hl, DEFAULT_PALETTE.TMS_APPROXIMATE
	bit	1, a
	jr	z, .SET_PALETTE ; Yes (1 key): TMS approximate
	ld	hl, DEFAULT_PALETTE.MSX2
	bit	2, a
	jr	z, .SET_PALETTE ; Yes (2 key): Default MSX2 palette
; no: sets custom palette
IFEXIST CFG_CUSTOM_PALETTE
	ld	hl, CFG_CUSTOM_PALETTE
ELSE
	ld	hl, DEFAULT_PALETTE.COOL_COLORS
ENDIF
.SET_PALETTE:
	call	SET_PALETTE
.PALETTE_OK:
ENDIF

; Zeroes all the used RAM
	ld	hl, ram_start
	ld	de, ram_start +1
	ld	bc, ram_end - ram_start  -1
	ld	[hl], l ; l = $00
	ldir
	
; PSG: silence
	call	GICINI

; Initializes the replayer
IFEXIST REPLAYER.RESET
	call	REPLAYER.RESET
ENDIF

; Frame rate related variables
	ld	a, [MSXID1]
	bit	7, a ; 0=60Hz, 1=50Hz
	ld	hl, 5 << 8 + 50 ; frame rate and frames per tenth for 50Hz
	jr	nz, .HL_OK
	ld	hl, 6 << 8 + 60 ; frame rate and frames per tenth for 60Hz
.HL_OK:
	ld	[frame_rate], hl
	
; Installs the H.TIMI hook in the interruption
IFEXIST HOOK
; Preserves the existing hook
	ld	hl, HTIMI
	ld	de, old_htimi_hook
	ld	bc, HOOK_SIZE
	ldir
; Install the interrupt routine
	di
	ld	a, $c3 ; opcode for "JP nn"
	ld	[HTIMI], a
	ld	hl, HOOK
	ld	[HTIMI +1], hl
	ei
ENDIF

; Skips to the game entry point
	jp	INIT
; -----------------------------------------------------------------------------

; EOF
