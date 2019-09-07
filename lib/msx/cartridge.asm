
; =============================================================================
; 	MSX cartridge (ROM) header, entry point and initialization
; =============================================================================

	CFG_RAM_CARTRIDGE:	equ 1

; -----------------------------------------------------------------------------
; Cartridge header
IFDEF CFG_INIT_ROM_SIZE
IF (CFG_INIT_ROM_SIZE < 32)
	org	$4000, $4000 + (CFG_INIT_ROM_SIZE * $0400) - 1
ELSE
	org	$4000, $bfff
ENDIF ; IF (CFG_INIT_ROM_SIZE < 32)
ELSE
	org	$4000, $7fff
ENDIF ; IFDEF CFG_INIT_ROM_SIZE

CARTRIDGE_HEADER:
	db	"AB"		; ROM Catridge ID ("AB")
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

; CPU: Ensures Z80 mode
	ld	a, [MSXID3]
	cp	3 ; 3 = MSX turbo R
	jr	nz, .CPU_OK
; MSX turbo R: switches to Z80 mode
	ld	a, $80 ; also disables the LED
	call	CHGCPU
.CPU_OK:

IFDEF CFG_INIT_ROM_SIZE
IF CFG_INIT_ROM_SIZE > 16

IF CFG_INIT_ROM_SIZE <= 32
; Is the game running on RAM? (e.g.: ROM Loader)
	ld	a, $18 ; opcode for "JR nn"
	ld	[.JR_NC], a ; Replaces "JR NC,nn" by "JR nn" (if RAM)
	scf
.JR_NC:
	jr	nc, .ROM_OK ; yes
; No:
ENDIF ; IF CFG_INIT_ROM_SIZE <= 32

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

IF CFG_INIT_ROM_SIZE > 32
; Saves the slot of the cartridge
	push	af ; (Reserves a byte at the bottom of the stack
	inc	sp ; to avoid accidental overwriting)
ENDIF

; Enables page 2 cartridge slot/subslot at start
	ld	h, $80 ; Bit 6 and 7: page 2 ($8000)
	call	ENASLT
.ROM_OK:

ENDIF ; IF CFG_INIT_ROM_SIZE > 16
ENDIF ; IFDEF CFG_INIT_ROM_SIZE

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

IFDEF CFG_INIT_16KB_RAM
; RAM: checks availability of 16kB
	ld	hl, ram_start
	ld	de, [BOTTOM]
	call	DCOMPR
	jr	nc, .RAM_OK ; yes (BOTTOM is less or equal than ram_start)

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

.RAM_OK:

ENDIF ; CFG_INIT_16KB_RAM

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
	rra	; carry = bit 0
	rra	; carry = bit 1
	jr	nc, .SET_PALETTE ; Yes (1 key): TMS approximate
	ld	hl, DEFAULT_PALETTE.MSX2
	rra	; carry = bit 2
	jr	nc, .SET_PALETTE ; Yes (2 key): Default MSX2 palette
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

; -----------------------------------------------------------------------------
; 48kB ROM: Declares routines to set the page 0 slot/subslot and restore the bios
IFDEF CFG_INIT_ROM_SIZE
IF CFG_INIT_ROM_SIZE > 32

SET_PAGE0:

; Restores the BIOS (selects and enables the Main ROM slot/subslot in page 0)
; Caller is responsible of disabling interruptions before invoking this routine
; touches: a, bc, d
.BIOS:
	ld	a, [MNROM]
	jr	.DO_SET_PAGE0

; Selects and enables the cartridge slot/sublot in page 0
; Caller is responsible of enabling interruptions after invoking this routine
; touches: a, bc, d
.CARTRIDGE:
; Retrieves the slot of the cartridge from the bottom of the stack
	ld	bc, [HIMEM]
	dec	bc ; bc = [HIMEM] - 1
	ld	a, [bc]
	; jr	.DO_SET_PAGE0 ; falls through

; Selects and permanently enables the requested slot in page 0
; param a: slot ID (ExxxSSPP)
; touches: a, bc, d
.DO_SET_PAGE0:
	ld	b, a		; b = ExxxSSPP
	and	$03		; a = 000000PP
	ld	c, a		; c = 000000PP
; Computes the primary slot selection register
	in	a, [PPI.A]	; a = P3P2P1P0
	and	$fc		; a = P3P2P100
	or	c		; a = P3P2P1PP
; Is the slot expanded?
	bit	7, b
	jr	z, .SET_PRIMARY ; no
; yes
	ld	d, a ; (preserves primary slot selection register value)
; Selects primary slot in page 3 first (for $FFFF to refer to that slot)
	rrc	c
	rrc	c		; c = PP000000
	ld	a, d		; a = P3P2P1PP
	and	$3f		; a = 00P2P1PP
	or	c		; a = PPP2P1PP
	out	[PPI.A], a
; Selects secondary slot in page 0
	ld	a, b		; a = 1xxxSSPP
	and	$0c		; a = 0000SS00
	rrca
	rrca			; a = 000000SS
	ld	b, a		; b = 000000SS
	ld	a, [$ffff]
	cpl			; a = S3S2S1S0
	and	$fc		; a = S3S2S100
	or	b		; b = S3S2S1SS
	ld	[$ffff], a
; Selects primary slot in page 0
	ld	a, d ; (restores primary slot selection register value)
.SET_PRIMARY:
	out	[PPI.A], a
	ret

ENDIF ; IF CFG_INIT_ROM_SIZE > 32
ENDIF ; IFDEF CFG_INIT_ROM_SIZE
; -----------------------------------------------------------------------------

; EOF
