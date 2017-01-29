
	CFG_OPTIONAL_MSX2_OPTIONS	equ 0

	OPTIONS_X	equ 9 ; Coordenadas de la primera opción en el menú de opciones
	OPTIONS_Y	equ 8

	TIMES_BLINK		equ 10 ; Número de repeticiones del parpadeo
	FRAMES_BLINK		equ 3 ; Frames de duración del parpadeo
	FRAMES_INPUT_PAUSE	equ 10 ; Pausa tras el cambio de opción

	CHAR_EOF	equ $00 ; Fin de texto
	CHAR_CR		equ $01 ; Fin de línea
	CHAR_LF		equ $02 ; Nueva línea
	CHAR_CLR	equ $03 ; Borrado de línea actual
	CHAR_CLS	equ $04 ; Borrado de todas las línes
	CHAR_PAUSE	equ $05	; Pausa en la escritura

; -----------------------------------------------------------------------------
; Vuelca a RAM las variables dependientes del framerate
; eligiendo el origen de datos correcto (50Hz o 60Hz)
; param z/nz: 60Hz/50Hz
BLIT_FRAME_RATE:
; Variables dependientes del framerate
	ld	hl, FRAME_RATE_50HZ_0
	ld	bc, FRAME_RATE_SIZE
	jr	nz, @@HL_OK
; salta la tabla de 50Hz y va a la de 60Hz
	add	hl, bc
@@HL_OK:
; vuelca los valores dependientes de la frecuencia
	ld	de, frame_rate
	ld	bc, FRAME_RATE_SIZE
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Pantalla de opciones de video (MSX-2 o superior)
MSX2_OPTIONS:
; inicializa la pantalla
	call	CLS_NAMTBL
; textos fijos
	ld	hl, TXT_OPTIONS
	ld	de, namtbl_buffer + OPTIONS_Y *SCR_WIDTH
	call	PRINT_TXT
	inc	hl ; hl = TXT_OPTION_FREQUENCY
	ld	de, namtbl_buffer + (OPTIONS_Y +3) *SCR_WIDTH + OPTIONS_X
	call	PRINT_TXT_DE_OK
	inc	hl ; hl = TXT_OPTION_PALETTE
	ld	de, namtbl_buffer + (OPTIONS_Y +5) *SCR_WIDTH + OPTIONS_X
	call	PRINT_TXT_DE_OK
	inc	hl ; hl = TXT_OPTION_RETURN
	ld	de, namtbl_buffer + (OPTIONS_Y +7) *SCR_WIDTH + OPTIONS_X
	call	PRINT_TXT_DE_OK
; texto variable: frecuencia
	ld	a, [frames_per_tenth]
	add	$30 ; "0" ASCII
	ld	[namtbl_buffer + (OPTIONS_Y +3) *SCR_WIDTH + OPTIONS_X + TXT_OPTION_FREQUENCY_OFFSET], a
; texto variable: paleta
	ld	a, [msx_version_palette]
	or	a
	jr	z, @@PALETTE_VER_OK ; 0 = MSX 1
	ld	a, 1 ; 1,2,3,etc. -> 1 = MSX 2
@@PALETTE_VER_OK:
	add	$31 ; "1" ASCII
	ld	[namtbl_buffer + (OPTIONS_Y +5) *SCR_WIDTH + OPTIONS_X + TXT_OPTION_PALETTE_OFFSET], a
; sprites
	ld	hl, SPRATR_OPTIONS_0
	ld	de, spratr_buffer
	ld	bc, SPRATR_OPTIONS_0_LENGTH
	ldir

; fundido de entrada y sprites
	call	ENASCR_FADE_IN
	call	LDIRVM_SPRATR

; Selecciona una opción
	xor	a
	ld	[tmp_byte], a ; índice de inicial marcada
	ld	[tmp_frame], a ; no hay pausa inicial porque hay fundido
	ld	bc, 2 * 256 + 16 ; 3 opciones, saltos de 16 píxeles
	call	GET_CURSOR_OPTION
	call	BLINK_CURSOR
; Salta a la opción seleccionada
	ld	a, [tmp_byte]
	ld	hl, @@JUMP_TABLE
	jp	JP_TABLE
@@JUMP_TABLE:
	.dw	@@FREQUENCY
	.dw	@@PALETTE
	.dw	@@EXIT

@@FREQUENCY:
; Alterna la frecuencia en RAM
	ld	a, [frame_rate]
	xor	(50 ^ 60)
; Vuelca las variables dependientes del framerate
	cp	60 ; prepara el z/nz
	call	BLIT_FRAME_RATE
; Cambio de la frecuencia en VDP y vuelta al menú
	call	DISSCR_FADE_OUT
	; TODO	...
; set50hz:
	; ld a,2
	; out (#99),a
	; ld a,128+9
	; out (#99),a
	; jp stp        
; set60hz:
	; ld a,0
	; out (#99),a
	; ld a,128+9
	; out (#99),a
	; jp stp        
	; TODO	...
	jp	MSX2_OPTIONS

@@PALETTE:
; Alterna la paleta en RAM
	ld	hl, msx_version_palette
	ld	a, 1
	xor	[hl]
	ld	[hl], a
; Cambio de la paleta en VDP y vuelta al menú
	call	DISSCR_FADE_OUT
	; TODO	...
	; ld	a,(7)		; get first VDP write port
	; ld	c,a
	; inc	c		; prepare to write register data
	; di			; interrupts could screw things up
	; xor	a		; from color 0
	; out	(c),a
	; ld	a,128+16	; write R#16
	; out	(c),a
	; ei
	; inc	c		; prepare to write palette data
	; ld	b,32		; 16 color * 2 bytes for palette data
	; ld	hl,palette
	; otir
	; ret
; ;
; ; the format of the palette is like $GRB
; ; and R, G and B must be between 0-7
; ; currently it's the default MSX2 palette
; ; but you set up your own in these dw's
; ;
; palette:	dw	$000,$000,$611,$733,$117,$327,$151,$627
	; dw	$171,$373,$661,$664,$411,$265,$555,$777

; ;
; ;Set the VDP's palette to the palette HL points to
; ;Changes: AF, BC, HL (=updated)
; ;
; SetPalet:     xor     a             ;Set p#pointer to zero.
              ; di
              ; out     (#99),a
              ; ld      a,16+128
              ; ei
              ; out     (#99),a
              ; ld      c,#9A
              ; DW      #A3ED,#A3ED,#A3ED,#A3ED   ;32x OUTI instruction
              ; DW      #A3ED,#A3ED,#A3ED,#A3ED   ; (faster than OTIR)
              ; DW      #A3ED,#A3ED,#A3ED,#A3ED
              ; DW      #A3ED,#A3ED,#A3ED,#A3ED
              ; DW      #A3ED,#A3ED,#A3ED,#A3ED
              ; DW      #A3ED,#A3ED,#A3ED,#A3ED
              ; DW      #A3ED,#A3ED,#A3ED,#A3ED
              ; DW      #A3ED,#A3ED,#A3ED,#A3ED
	; TODO	...
	jp	MSX2_OPTIONS
	
@@EXIT:
; Vuelve al bucle principal
	jp	DISSCR_FADE_OUT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Selecciona una opción mediante un cursor movido por los cursores.
; param [tmp_byte]: opción inicial, empezando en 0
; param b: opción máxima, empezando en 0
; param c: número de píxeles a mover el cursor
; ret [tmp_byte]: opción seleccionada, empezando en 0
GET_CURSOR_OPTION:
	push	bc ; preserva parámetros
@@PAUSE_LOOP:
	halt
	call	LDIRVM_SPRATR
; Comprueba pausa
	ld	hl, tmp_frame
	ld	a, [hl]
	or	a
	jr	z, @@OK ; no hay pausa
	dec	[hl]
	jr	@@PAUSE_LOOP
@@OK:
; Comprueba selección
	call	GET_TRIGGER
	jr	nz, @@TRIGGER
; Comprueba cambio de opción
	call	GET_STICK
	pop	bc ; restaura parámetros
	cp	5
	jr	z, @@DOWN
	cp	1
	jr	nz, GET_CURSOR_OPTION
	; jr	@@UP ; falls through
@@UP:
; ¿es la primera opción?
	ld	hl, tmp_byte
	ld	a, [hl]
	or	a
	jr	z, GET_CURSOR_OPTION ; sí
; no: sube una opción
	dec	[hl] ; cambia la opción
	ld	a, c
	neg
	jr	@@MOVE
@@DOWN:
; ¿es la última opción?
	ld	hl, tmp_byte
	ld	a, [hl]
	cp	b
	jr	z, GET_CURSOR_OPTION
; no: baja una opción
	inc	[hl] ; cambia la opción
	ld	a, c
	; jr	@@MOVE
@@MOVE:
; Mueve el sprite
	ld	hl, spratr_buffer
	add	[hl]
	ld	[hl], a
; Pausa para evitar un movimiento del cursor demasiado rápido
	ld	a, FRAMES_INPUT_PAUSE
	ld	[tmp_frame], a
	jr	GET_CURSOR_OPTION
@@TRIGGER:
	pop	bc ; restaura el stack
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Hace parpadear el cursor para indicar que se ha seleccionado una opción
BLINK_CURSOR:
; Parpadeo
	ld	b, TIMES_BLINK *2
@@BLINK_LOOP:
	push	bc ; preserva el contador
; alterna el color del sprite: 15, 0, 15, 0, 15...
	ld	a, 15
	ld	hl, spratr_buffer +3
	xor	[hl]
	ld	[hl], a
; Vuelca y pausa
	call	LDIRVM_SPRATR
	ld	b, FRAMES_BLINK
	call	WAIT_FRAMES

	pop	bc ; restaura el contador
	djnz	@@BLINK_LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
TXT_OPTIONS:
	.db	"VDP options", 0

TXT_OPTION_FREQUENCY:
	.db	"Frequency: "
	TXT_OPTION_FREQUENCY_OFFSET equ $ - TXT_OPTION_FREQUENCY
	.db	"00Hz", 0

TXT_OPTION_PALETTE:
	.db	"Palette: "
	TXT_OPTION_PALETTE_OFFSET equ $ - TXT_OPTION_PALETTE
	.db	0

TXT_OPTION_RETURN:
	.db	"Return", 0

TXT_PALETTES:
	.db	"Emulate MSX 1", 0
	.db	"MSX 2 (default)", 0
	.db	"Optimized", 0

SPRATR_OPTIONS_0:
	.db	(OPTIONS_Y +3) *8 -1
	.db	OPTIONS_X *8 -32
	.db	BOX_SPRITE_PATTERN
	.db	BOX_SPRITE_COLOR
	.db	SPAT_END
	SPRATR_OPTIONS_0_LENGTH equ $ - SPRATR_OPTIONS_0
; -----------------------------------------------------------------------------

; EOF
