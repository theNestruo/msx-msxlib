
; =============================================================================
; 	MSX symbolic constants
; =============================================================================

; -----------------------------------------------------------------------------
; BIOS entry points and constants
; -----------------------------------------------------------------------------
; RST-and other routines
	CHKRAM:	equ $0000 ; Tests RAM and sets RAM slot for the system
	CGTABL:	equ $0004
	VDP_DR:	equ $0006 ; Base port address for VDP data read
	VDP_DW:	equ $0007 ; Base port address for VDP data write
;	SYNCHR:	equ $0008 ; BASIC
	RDSLT:	equ $000C ; Reads the value of an address in another slot
;	CHRGTR:	equ $0010 ; BASIC
	WRSLT:	equ $0014 ; Writes a value to an address in another slot.
;	OUTDO:	equ $0018 ; BASIC
	CALSLT:	equ $001C ; xecutes inter-slot call
	DCOMPR:	equ $0020 ; Compares HL with DE
	ENASLT:	equ $0024 ; Switches indicated slot at indicated page on perpetual
	GETYPR:	equ $0028 ; Returns Type of DAC
	MSXID1:	equ $002b ; Frecuency (1b), date format (3b) and charset (4b)
	MSXID2:	equ $002c ; Basic version (4b) and Keybaord type (4b)
	MSXID3:	equ $002d ; MSX version number
	MSXID4:	equ $002e ; Bit 0: if 1 then MSX-MIDI is present internally (MSX turbo R only)
	MSXID5:	equ $002f ; Reserved
	CALLF:	equ $0030 ; Executes an interslot call
	KEYINT:	equ $0038 ; Executes the timer interrupt process routine
; Initialization routines
	INITIO:	equ $003B ; Initialises the device
	INIFNK:	equ $003E ; Initialises the contents of the function keys
; VDP routines
	DISSCR:	equ $0041 ; Inhibits the screen display
	ENASCR:	equ $0044 ; Displays the screen
	WRTVDP:	equ $0047 ; Write data in the VDP-register
	RDVRM:	equ $004A ; Reads the content of VRAM
	WRTVRM:	equ $004D ; Writes data in VRAM
	SETRD:	equ $0050 ; Enable VDP to read
	SETWRT:	equ $0053 ; Enable VDP to write
	FILVRM:	equ $0056 ; Fill VRAM with value
	LDIRMV:	equ $0059 ; Block transfer to memory from VRAM
	LDIRVM:	equ $005C ; Block transfer to VRAM from memory
	CHGMOD:	equ $005F ; Switches to given screenmode
	CHGCLR:	equ $0062 ; Changes the screencolors
	NMI:	equ $0066 ; Executes (non-maskable interupt) handling routine
	CLRSPR:	equ $0069 ; Initialises all sprites
	INITXT:	equ $006C ; Switches to SCREEN 0 (text screen with 40*24 characters)
	INIT32:	equ $006F ; Switches to SCREEN 1 (text screen with 32*24 characters)
	INIGRP:	equ $0072 ; Switches to SCREEN 2 (high resolution screen with 256*192 pixels)
	INIMLT:	equ $0075 ; Switches to SCREEN 3 (multi-color screen 64*48 pixels)
	SETTXT:	equ $0078 ; Switches to VDP in SCREEN 0 mode
	SETT32:	equ $007B ; Switches to VDP in SCREEN 1 mode
	SETGRP:	equ $007E ; Switches to VDP in SCREEN 2 mode
	SETMLT:	equ $0081 ; Switches to VDP in SCREEN 3 mode
	CALPAT:	equ $0084 ; Returns the address of the sprite pattern table
	CALATR:	equ $0087 ; Returns the address of the sprite attribute table
	GSPSIZ:	equ $008A ; Returns current sprite size
	GRPPRT:	equ $008D ; Displays a character on the graphic screen
; PSG routines
	GICINI:	equ $0090 ; Initialises PSG and sets initial value for the PLAY statement
	WRTPSG:	equ $0093 ; Writes data to PSG-register
	RDPSG:	equ $0096 ; Reads value from PSG-register
;	STRTMS:	equ $0099 ; BASIC
; Console routines
	CHSNS:	equ $009C ; Tests the status of the keyboard buffer
	CHGET:	equ $009F ; One character input (waiting)
	CHPUT:	equ $00A2 ; Displays one character
	LPTOUT:	equ $00A5
	LPTSTT:	equ $00A8
	CNVCHR:	equ $00AB
	PINLIN:	equ $00AE
	INLIN:	equ $00B1
	QINLIN:	equ $00B4
	BREAKX:	equ $00B7
	ISCNTC:	equ $00BA
	CKCNTC:	equ $00BD
	BEEP:	equ $00C0
	CLS:	equ $00C3
	POSIT:	equ $00C6
	FNKSB:	equ $00C9
	ERAFNK:	equ $00CC
	DSPFNK:	equ $00CF
	TOTEXT:	equ $00D2
; Controller routines
	GTSTCK:	equ $00D5
	GTTRIG:	equ $00D8
	GTPAD:	equ $00DB
	GTPDL:	equ $00DE
; Tape device routines
	TAPION:	equ $00E1
	TAPIN:	equ $00E4
	TAPIOF:	equ $00E7
	TAPOON:	equ $00EA
	TAPOUT:	equ $00ED
	TAPOOF:	equ $00F0
	STMOTR:	equ $00F3
; Queue routines	
	LFTQ:	equ $00F6
	PUTQ:	equ $00F9
; Graphic routines
	RIGHTC:	equ $00FC
	LEFTC:	equ $00FF
	UPC:	equ $0102
	TUPC:	equ $0105
	DOWNC:	equ $0108
	TDOWNC:	equ $010B
	SCALXY:	equ $010E
	MAPXY:	equ $0111
	FETCHC:	equ $0114
	STOREC:	equ $0117
	SETATR:	equ $011A
	READC:	equ $011D
	SETC:	equ $0120
	NSETCX:	equ $0123
	GTASPC:	equ $0126
	PNTINI:	equ $0129
	SCANR:	equ $012C
	SCANL:	equ $012F
; Misc routines
	CHGCAP:	equ $0132
	CHGSND:	equ $0135
	RSLREG:	equ $0138 ; Reads the primary slot register
	WSLREG:	equ $013B ; Writes value to the primary slot register
	RDVDP:	equ $013E ; Reads VDP status register
	SNSMAT:	equ $0141 ; Returns the value of the specified line from the keyboard matrix
	PHYDIO:	equ $0144 ; Executes I/O for mass-storage media like diskettes
	FORMAT:	equ $0147 ; Initialises mass-storage media like formatting of diskettes
	ISFLIO:	equ $014A ; Tests if I/O to device is taking place
	OUTDLP:	equ $014D ; Printer output
	GETVCP:	equ $0150 ; Returns pointer to play queue
	GETVC2:	equ $0153 ; Returns pointer to variable in queue number VOICEN (byte op #FB38)
	KILBUF:	equ $0156 ; Clear keyboard buffer
	CALBAS:	equ $0159 ; Executes inter-slot call to the routine in BASIC interpreter
; MSX 2 BIOS Entries
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
; MSX 2+ BIOS Entries
	RDBTST:	equ $017a
	WRBTST:	equ $017d
; MSX turbo R BIOS Entries
	CHGCPU:	equ $0180 ; Changes CPU mode
	GETCPU:	equ $0183 ; Returns current CPU mode
	PCMPLY:	equ $0186 ; Plays specified memory area through the PCM chip
	PCMREC:	equ $0189 ; Records audio using the PCM chip into the specified memory area

; -----------------------------------------------------------------------------
; BIOS system variables
; -----------------------------------------------------------------------------
	CLIKSW:	equ $f3db ; Keyboard click sound
	RG1SAV:	equ $f3e0 ; Content of VDP(1) register (R#1)
	FORCLR:	equ $f3e9 ; Foreground colour
	BAKCLR:	equ $f3ea ; Background colour
	BDRCLR:	equ $f3eb ; Border colour
	NEWKEY:	equ $fbe5 ; Current state of the keyboard matrix ($fbe5-$fbef)
	HIMEM:	equ $fc4a ; High free RAM address available (init stack with)
	EXPTBL:	equ $fcc1 ; Slot [0..3]: #80 = expanded, 0 = not expanded.
	SLTTBL: equ $fcc5 ; Mirror of slot [0..3] secondary slot selection register.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; BIOS hooks
; -----------------------------------------------------------------------------
	HKEYI:	equ $fd9a ; Interrupt handler
	HTIMI:	equ $fd9f ; Interrupt handler
	HOOK_SIZE:	equ HTIMI - HKEYI
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VRAM addresses
; -----------------------------------------------------------------------------
	CHRTBL:	equ $0000 ; Pattern table
	NAMTBL:	equ $1800 ; Name table
	CLRTBL:	equ $2000 ; Color table
	SPRATR:	equ $1B00 ; Sprite attributes table
	SPRTBL:	equ $3800 ; Sprite pattern table
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; VRAM symbolic constants
; -----------------------------------------------------------------------------
	SCR_WIDTH:	equ 32
	SCR_HEIGHT:	equ 24
	NAMTBL_SIZE:	equ 32 * 24
	CHRTBL_SIZE:	equ 256 * 8
	SPRTBL_SIZE:	equ 32 * 64
	SPRATR_SIZE:	equ 32 * 4
	SPAT_END:	equ $d0 ; Sprite attribute table end marker
	SPAT_OB:	equ $d1 ; Sprite out of bounds marker (not standard)
	SPAT_EC:	equ $80 ; Early clock bit (32 pixels)
; -----------------------------------------------------------------------------

; EOF
