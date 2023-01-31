
; =============================================================================
;	MSX symbolic constants
; =============================================================================

; -----------------------------------------------------------------------------
; MSX BIOS entry points and constants

; MSX BIOS
	CHKRAM:	equ $0000 ; Power-up, check RAM
	CGTABL:	equ $0004 ; Two bytes, address of ROM character set
	VDP_DR:	equ $0006 ; One byte, VDP Data Port number (read)
	VDP_DW:	equ $0007 ; One byte, VDP Data Port number (write)
	SYNCHR:	equ $0008 ; Check BASIC program character
	RDSLT:	equ $000c ; Read RAM in any slot
	CHRGTR:	equ $0010 ; Get next BASIC program character
	WRSLT:	equ $0014 ; Write to RAM in any slot
	OUTDO:	equ $0018 ; Output to current device
	CALSLT:	equ $001c ; Call routine in any slot
	DCOMPR:	equ $0020 ; Compare register pairs HL and DE
	ENASLT:	equ $0024 ; Enable any slot permanently
	GETYPR:	equ $0028 ; Get BASIC operand type
	MSXID1:	equ $002b ; Frecuency (1b), date format (3b) and charset (4b)
		; Default interrupt frequency: 0 = 60Hz, 1 = 50Hz
		; Date format: 0 = Y-M-D, 1 = M-D-Y, 2 = D-M-Y
		; Character set: 0 = Japanese, 1 = International, 2=Korean
	MSXID2:	equ $002c ; Basic version (4b) and Keybaord type (4b)
		; Basic version: 0 = Japanese, 1 = International
		; Keyboard type: 0 = Japanese, 1 = International, 2 = French (AZERTY), 3 = UK, 4 = German (DIN)
	MSXID3:	equ $002d ; MSX version number
		; 0 = MSX 1
		; 1 = MSX 2
		; 2 = MSX 2+
		; 3 = MSX turbo R
	MSXID4:	equ $002e ; Bit 0: if 1 then MSX-MIDI is present internally (MSX turbo R only)
	MSXID5:	equ $002f ; Reserved
	CALLF:	equ $0030 ; Call routine in any slot
	KEYINT:	equ $0038 ; Interrupt handler, keyboard scan
	INITIO:	equ $003b ; Initialize I/O devices
	INIFNK:	equ $003e ; Initialize function key strings
	DISSCR:	equ $0041 ; Disable screen
	ENASCR:	equ $0044 ; Enable screen
	WRTVDP:	equ $0047 ; Write to any VDP register
	RDVRM:	equ $004a ; Read byte from VRAM
	WRTVRM:	equ $004d ; Write byte to VRAM
	SETRD:	equ $0050 ; Set up VDP for read
	SETWRT:	equ $0053 ; Set up VDP for write
	FILVRM:	equ $0056 ; Fill block of VRAM with data byte
	LDIRMV:	equ $0059 ; Copy block to memory from VRAM
	LDIRVM:	equ $005c ; Copy block to VRAM, from memory
	CHGMOD:	equ $005f ; Change VDP mode
	CHGCLR:	equ $0062 ; Change VDP colours
	NMI:	equ $0066 ; Non Maskable Interrupt handler
	CLRSPR:	equ $0069 ; Clear all sprites
	INITXT:	equ $006c ; Initialize VDP to 40x24 Text Mode
	INIT32:	equ $006f ; Initialize VDP to 32x24 Text Mode
	INIGRP:	equ $0072 ; Initialize VDP to Graphics Mode
	INIMLT:	equ $0075 ; Initialize VDP to Multicolour Mode
	SETTXT:	equ $0078 ; Set VDP to 40x24 Text Mode
	SETT32:	equ $007b ; Set VDP to 32x24 Text Mode
	SETGRP:	equ $007e ; Set VDP to Graphics Mode
	SETMLT:	equ $0081 ; Set VDP to Multicolour Mode
	CALPAT:	equ $0084 ; Calculate address of sprite pattern
	CALATR:	equ $0087 ; Calculate address of sprite attribute
	GSPSIZ:	equ $008a ; Get sprite size
	GRPPRT:	equ $008d ; Print character on graphic screen
	GICINI:	equ $0090 ; Initialize PSG (GI Chip)
	WRTPSG:	equ $0093 ; Write to any PSG register
	RDPSG:	equ $0096 ; Read from any PSG register
	STRTMS:	equ $0099 ; Start music dequeueing
	CHSNS:	equ $009c ; Sense keyboard buffer for character
	CHGET:	equ $009f ; Get character from keyboard buffer (wait)
	CHPUT:	equ $00a2 ; Screen character output
	LPTOUT:	equ $00a5 ; Line printer character output
	LPTSTT:	equ $00a8 ; Line printer status test
	CNVCHR:	equ $00ab ; Convert character with graphic header
	PINLIN:	equ $00ae ; Get line from console (editor)
	INLIN:	equ $00b1 ; Get line from console (editor)
	QINLIN:	equ $00b4 ; Display "?", get line from console (editor)
	BREAKX:	equ $00b7 ; Check CTRL-STOP key directly
	ISCNTC:	equ $00ba ; Check CRTL-STOP key
	CKCNTC:	equ $00bd ; Check CTRL-STOP key
	BEEP:	equ $00c0 ; Go beep
	CLS:	equ $00c3 ; Clear screen
	POSIT:	equ $00c6 ; Set cursor position
	FNKSB:	equ $00c9 ; Check if function key display on
	ERAFNK:	equ $00cc ; Erase function key display
	DSPFNK:	equ $00cf ; Display function keys
	TOTEXT:	equ $00d2 ; Return VDP to text mode
	GTSTCK:	equ $00d5 ; Get joystick status
	GTTRIG:	equ $00d8 ; Get trigger status
	GTPAD:	equ $00db ; Get touch pad status
	GTPDL:	equ $00de ; Get paddle status
	TAPION:	equ $00e1 ; Tape input ON
	TAPIN:	equ $00e4 ; Tape input
	TAPIOF:	equ $00e7 ; Tape input OFF
	TAPOON:	equ $00ea ; Tape output ON
	TAPOUT:	equ $00ed ; Tape output
	TAPOOF:	equ $00f0 ; Tape output OFF
	STMOTR:	equ $00f3 ; Turn motor ON/OFF
	LFTQ:	equ $00f6 ; Space left in music queue
	PUTQ:	equ $00f9 ; Put byte in music queue
	RIGHTC:	equ $00fc ; Move current pixel physical address right
	LEFTC:	equ $00ff ; Move current pixel physical address left
	UPC:	equ $0102 ; Move current pixel physical address up
	TUPC:	equ $0105 ; Test then UPC if legal
	DOWNC:	equ $0108 ; Move current pixel physical address down
	TDOWNC:	equ $010b ; Test then DOWNC if legal
	SCALXY:	equ $010e ; Scale graphics coordinates
	MAPXYC:	equ $0111 ; Map graphic coordinates to physical address
	FETCHC:	equ $0114 ; Fetch current pixel physical address
	STOREC:	equ $0117 ; Store current pixel physical address
	SETATR:	equ $011a ; Set attribute byte
	READC:	equ $011d ; Read attribute of current pixel
	SETC:	equ $0120 ; Set attribute of current pixel
	NSETCX:	equ $0123 ; Set attribute of number of pixels
	GTASPC:	equ $0126 ; Get aspect ratio
	PNTINI:	equ $0129 ; Paint initialize
	SCANR:	equ $012c ; Scan pixels to right
	SCANL:	equ $012f ; Scan pixels to left
	CHGCAP:	equ $0132 ; Change Caps Lock LED
	CHGSND:	equ $0135 ; Change Key Click sound output
	RSLREG:	equ $0138 ; Read Primary Slot Register
	WSLREG:	equ $013b ; Write to Primary Slot Register
	RDVDP:	equ $013e ; Read VDP Status Register
	SNSMAT:	equ $0141 ; Read row of keyboard matrix
		; a = $00 ; 7 6 5 4 3 2 1 0
		; a = $01 ; ; ] [ \ = - 9 8
		; a = $02 ; B A pound / . , ` '
		; a = $03 ; J I H G F E D C
		; a = $04 ; R Q P O N M L K
		; a = $05 ; Z Y X W V U T S
		; a = $06 ; F3 F2 F1 CODE CAP GRAPH CTRL SHIFT
		; a = $07 ; CR SEL BS STOP TAB ESC F5 F4
		; a = $08 ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
		; a = $09 ; 4 3 2 1 0 none none none
		; a = $0a ; . , - 9 8 7 6 5
	PHYDIO:	equ $0144 ; Disk, no action
	FORMAT:	equ $0147 ; Disk, no action
	ISFLIO:	equ $014a ; Check for file I/O
	OUTDLP:	equ $014d ; Formatted output to line printer
	GETVCP:	equ $0150 ; Get music voice pointer
	GETVC2:	equ $0153 ; Get music voice pointer
	KILBUF:	equ $0156 ; Clear keyboard buffer
	CALBAS:	equ $0159 ; Call to BASIC from any slot

; MSX 2 BIOS
	SUBROM:	equ $015c ; Calls a routine in SUB-ROM
	EXTROM:	equ $015f ; Calls a routine in SUB-ROM. Most common way
	CHKSLZ:	equ $0162 ; Search slots for SUB-ROM
	CHKNEW:	equ $0165
	EOL:	equ $0168
	BIGFIL:	equ $016b
	NSETRD:	equ $016e
	NSTWRT:	equ $0171
	NRDVRM:	equ $0174
	NWRVRM:	equ $0177

; MSX 2+ BIOS
	RDBTST:	equ $017a
	WRBTST:	equ $017d

; MSX turbo R BIOS
	CHGCPU:	equ $0180 ; Changes CPU mode
	GETCPU:	equ $0183 ; Returns current CPU mode
	PCMPLY:	equ $0186 ; Plays specified memory area through the PCM chip
	PCMREC:	equ $0189 ; Records audio using the PCM chip into the specified memory area
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Stack pointer initialization
	STACK_POINTER_INIT:	equ $f380 ; As suggested by the MSX2 Technical Handbook

; MSX system variables
	RDPRIM:	equ $f380 ; RDSLT subroutine that reads from a primary slot (5b)
	WRPRIM:	equ $f385 ; WRSLT subroutine that writes to a primary slot (7b)
	CLPRIM:	equ $f38c ; CALSLT subroutine that calls a routine in a primary Slot (14b)
	USRTAB:	equ $f39a ; Table of addresses of routines specified with the instruction DEFUSRX= (20b)
	LINL40: equ $f3ae ; Width for SCREEN 0 (default 37)
	LINL32: equ $f3af ; Width for SCREEN 1 (default 29)
	LINLEN: equ $f3b0 ; Width for the current text mode
	CLIKSW:	equ $f3db ; Keyboard click sound
	RG0SAV:	equ $f3df ; Content of VDP(0) register (R#0)
	RG1SAV:	equ $f3e0 ; Content of VDP(1) register (R#1)
	RG2SAV:	equ $f3e1 ; Content of VDP(2) register (R#2)
	RG3SAV:	equ $f3e2 ; Content of VDP(3) register (R#3)
	RG4SAV:	equ $f3e3 ; Content of VDP(4) register (R#4)
	RG5SAV:	equ $f3e4 ; Content of VDP(5) register (R#5)
	RG6SAV:	equ $f3e5 ; Content of VDP(6) register (R#6)
	RG7SAV:	equ $f3e6 ; Content of VDP(7) register (R#7)
	STATFL: equ $f3e7 ; Content of VDP status register (S#0)
	TRGFLG:	equ $f3e8 ; State of the four joystick trigger inputs and the space key
	FORCLR:	equ $f3e9 ; Foreground colour
	BAKCLR:	equ $f3ea ; Background colour
	BDRCLR:	equ $f3eb ; Border colour
	SCNCNT: equ $f3f6 ; Key scan timing
	OLDKEY:	equ $fbda ; Previous state of the keyboard matrix (11b)
	NEWKEY:	equ $fbe5 ; Current state of the keyboard matrix (11b)
		; $fbda, $fbe5 ; 7 6 5 4 3 2 1 0
		; $fbdb, $fbe6 ; ; ] [ \ = - 9 8
		; $fbdc, $fbe7 ; B A pound / . , ` '
		; $fbdd, $fbe8 ; J I H G F E D C
		; $fbde, $fbe9 ; R Q P O N M L K
		; $fbdf, $fbea ; Z Y X W V U T S
		; $fbe0, $fbeb ; F3 F2 F1 CODE CAP GRAPH CTRL SHIFT
		; $fbe1, $fbec ; CR SEL BS STOP TAB ESC F5 F4
		; $fbe2, $fbed ; RIGHT DOWN UP LEFT DEL INS HOME SPACE
		; $fbe3, $fbee ; 4 3 2 1 0 none none none
		; $fbe4, $fbef ; . , - 9 8 7 6 5
	BOTTOM: equ $fc48 ; Address of the beginning of the available RAM area
	HIMEM:	equ $fc4a ; High free RAM address available (init stack with)
	INTFLG:	equ $fc9b ; STOP flag (0 = none, 3 = CTRL+STOP, 4 = STOP)
	JIFFY:	equ $fc9e ; Software clock; each VDP interrupt gets increased by 1
	INTCNT:	equ $fca2 ; ON INTERVAL counter (counts backwards)
	CSRSW:	equ $fca9 ; Flag to indicate whether the cursor will be shown (0 = no; another value, yes)
	CAPST:	equ $fcab ; Capital status. (0 = Off; another value = On)
	KANAST:	equ $fcac ; Status of the KANA key (0 = Off; another value = On)
	KANAMD: equ $fcad ; Flag to know if the keyboard type is "KANA" (0) or "JIS" (another value)
	SCRMOD: equ $fcaf ; Screen mode
	OLDSCR:	equ $fcb0 ; Old screen mode
	EXPTBL:	equ $fcc1 ; Set to $80 during power-up if Primary Slot is expanded (4b)
	MNROM:	equ $fcc1 ; The first EXPTBL variable is also the Main ROM (BIOS) slot ID
	SLTTBL:	equ $fcc5 ; Mirror of the four possible Secondary Slot Registers (4b)
	SLTADR:	equ $fcc9 ; Indicates the existence of routines on any page in any slot (64b)
	SLTWRK: equ $fd09 ; Work area for slots and pages, reserving two bytes for each page (128b)
	PROCNM:	equ $fd89 ; Work area of the instructions CALL and OPEN. Contents the instruction name or device name (16b)

; MSX system hooks
	HKEYI:	equ $fd9a ; Called at the beginning of the KEYINT interrupt routine
	HTIMI:	equ $fd9f ; Called by the KEYINT interrupt routine when Vblank interrupt occurs
	HRUNC:	equ $fecb ; Called at the beginning of the routine RUNC, used by the Basic instructions NEW and RUN
	HSTKE:	equ $feda ; This hook allows to automatically re-execute the ROM after the disks are installed
	HOOK_SIZE:	equ HTIMI - HKEYI
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VDP

; VRAM addresses
	CHRTBL:	equ $0000 ; Pattern table
	NAMTBL:	equ $1800 ; Name table
	CLRTBL:	equ $2000 ; Color table
	SPRATR:	equ $1B00 ; Sprite attributes table
	SPRTBL:	equ $3800 ; Sprite pattern table

; VDP symbolic constants
	CHRTBL_SIZE:	equ 256 * 8
	NAMTBL_SIZE:	equ 32 * 24
	CLRTBL_SIZE:	equ 256 * 8
	SPRATR_SIZE:	equ 32 * 4
	SPRTBL_SIZE:	equ 32 * 64

	SCR_WIDTH:	equ 32
	SCR_HEIGHT:	equ 24

	SPRITE_WIDTH:	equ 16
	SPRITE_HEIGHT:	equ 16

	SPAT_END:	equ $d0 ; Sprite attribute table end marker
	SPAT_OB:	equ $d1 ; Sprite out of bounds marker (not standard)
	SPAT_EC:	equ $80 ; Early clock bit (32 pixels)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PPI (Programmable Peripheral Interface)
	PPI.A: equ $a8 ; PPI port A: primary slot selection register
		; 33221100: number of slot to select on page n
	PPI.B: equ $a9 ; PPI port B: read the keyboard matrix row specified via the PPI port C ($AA)
	PPI.C: equ $aa ; PPI port C: control keyboard CAP LED, data recorder signals, and keyboard matrix row
		; bits 0-3: Row number of specified keyboard matrix to read via port B
		; bit 4: Data recorder motor (reset to turn on)
		; bit 5: Set to write on tape
		; bit 6: Keyboard LED CAPS (reset to turn on)
		; bit 7: 1, then 0 shortly thereafter to make a clicking sound (used for the keyboard)
	PPI.R: equ $ab ; PPI ports control register (write only)
		; bit 0 = Bit status to change
		; bit 1-3 = Number of the bit to change at port C of the PPI
		; bit 4-6 = Unused
		; bit 7 = Must be always reset on MSX
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ASCII
	ASCII_NUL:	equ $00 ; NUL (null)
	ASCII_EOT:	equ $04 ; EOT (End of transmission)
	ASCII_BEL:	equ $07 ; BEL (bell)
	ASCII_BS:	equ $08 ; BS (Backspace)
	ASCII_HT:	equ $09 ; HT (Horizontal tab)
	ASCII_LF:	equ $0a ; LF (Line feed)
	ASCII_CR:	equ $0d ; CR (Carriage return)
	ASCII_SYN:	equ $16 ; SYN (Synchronous idle)
	ASCII_SUB:	equ $1a ; SUB (Substitute) (see ASCII_EOF)
	ASCII_EOF:	equ $1a ; EOF (End of file, Control-Z) (see ASCII_SUB)
	ASCII_ESC:	equ $1b ; ESC (Escape)
	ASCII_DEL:	equ $7f ; DEL (Delete)
; -----------------------------------------------------------------------------

; EOF
