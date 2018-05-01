		; --- asMSX example of use of PT3 replayer from ROM ---
		; --- Version 1: FIXED FREQUENCY TABLE              ---
		; --- May 21st, 2008 by SapphiRe                    ---

		.bios					; MSX BIOS
		.page	1				; Page 1 -> org address $4000
		.rom					; It's a ROM!
		.start	INIT				; Rom starts in INIT label

		; --- ROM HEADER ---
		.dw	0,0,0,0,0,0			; Fill 12 bytes with 0

INIT:		di					; Disable interrupts
		ld	hl,MUSIC-100			; hl <- initial address of module - 100
		call	PT3_INIT			; Inits PT3 player
		ei					; Enable interrupts
		halt					; Synchro
		halt					; Synchro


LOOP:		halt					; Synchro
		di					; Disable interrupts
		; --- Small loop to easily view the raster bars ---
		ld	b,8				; b:=8
OUTER:		ld	c,b				; c:=b
		ld	b,0				; b:=0 (256)
INNER:		djnz	INNER				; Inner loop
		ld	b,c				; b:=c
		djnz	OUTER				; Outer loop

		; --- Raster bar to show PSG writes ---
		ld	bc,$0c07			; b:=12;c:=7
		call	WRTVDP				; Set border color 12
		; --- Raster bar to show PSG writes ---
		
		; --- Place this instruction on interrupt or after HALT instruction to synchronize music ---
		call	PT3_ROUT			; Write values on PSG registers

		; --- Raster bar to show PT3 calculations ---
		ld	bc,$0807			; b:=8;c:=7
		call	WRTVDP				; Set border color 8
		; --- Raster bar to show PT3 calculations ---

		; --- To speed up VDP writes you can place this instruction after all of them, but before next INT ---
		call	PT3_PLAY			; Calculates PSG values for next frame

		; --- You can place here your favourite FX system and write the values to AYREGS label ---
		; --- so on next frame the FX will be played automatically when calling PT3_ROUT       ---

		; --- No more raster bars ---
		ld	bc,$0107			; b:=1;c:=7
		call	WRTVDP				; Set border color 1

		ei					; Enable interrupts
		jp	LOOP				; Close main loop


		; --- INCLUDE PT3-ROM.ASM in ROM code ---
REPLAYER:	.INCLUDE	"PT3-ROM.ASM"

		; --- INCLUDE MUSIC in ROM code (don't forget to strip first 100 bytes of PT3 module ---
MUSIC:		.INCBIN		"MUSIC.100"





		; --- RAM SECTION ---
		.PAGE	3				; Page 3 -> org address $C000

		; --- INCLUDE PT3-RAM.ASM in RAM section (no code output, but label definitions) ---
		.INCLUDE	"PT3-RAM.ASM"
