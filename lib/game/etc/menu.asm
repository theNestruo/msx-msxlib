
; =============================================================================
;	Menu control routines
; =============================================================================

	CFG_RAM_MENU:	equ	1

; -----------------------------------------------------------------------------
; Initializes the options menu
; param hl: pointer to the menu definition (size, offset, option coordinates+texts)
; param a: the initially selected option
INIT_OPTIONS_MENU:
	ld	[options_menu.current_position], a
; Copies the menu definition
	ld	de, options_menu
	ld	a, [hl] ; (number of options in a)
	ld	bc, 5
	ldir	; options_menu.size, .cursor_definition, .offset
	ex	de, hl
	ld	[hl], e ; options_menu.coordinates (l)
	inc	hl
	ld	[hl], d ; options_menu.coordinates (h)
	inc	hl
; (skips the coordinates table)
	add	a
	call	ADD_DE_A
	ld	[hl], e ; options_menu.options (l)
	inc	hl
	ld	[hl], d ; options_menu.options (h)
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints the options of the menu
PRINT_OPTIONS_MENU:
	ld	a, [options_menu.size]
	ld	hl, [options_menu.options]
	push	hl ; (preserves options texts)
	ld	hl, [options_menu.coordinates]
.LOOP:
	push	af ; (preserves size)
; Reads the coordinates
	ld	e, [hl]
	inc	hl
	ld	d, [hl]
	inc	hl
; Applies the cursor-to-text offset
	ex	de, hl
	ld	bc, [options_menu.offset]
	add	hl, bc
	ex	de, hl
; Prints the text
	pop	af
	ex	[sp], hl ; (restores options text, preserves coordinates pointer)
	push	af
	call	PRINT_TEXT
	inc	hl
	pop	af
	ex	[sp], hl ; (preserves options text, restores coordinates pointer)
	dec	a
	jr	nz, .LOOP
	pop	hl ; (restores stack state)
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Prints the options menu cursor
PRINT_OPTIONS_MENU_CURSOR:
	ld	b, 0
	ld	hl, [options_menu.coordinates]
.LOOP:
	push	bc ; (preserves counter)
; Reads the coordinates
	ld	e, [hl]
	inc	hl
	ld	d, [hl]
	inc	hl
; Compares with the current option
	push	hl ; (preserves data pointer)
	call	.PRINT_CURSOR_OR_BLANK
	pop	hl ; (restores data pointer)
	pop	bc ; (restores size)
	inc	b
	ld	a, [options_menu.size]
	cp	b
	jr	nz, .LOOP
	ret

; param b: the current option index
; param de: the coordinates
; touches a, bc, de, hl
.PRINT_CURSOR_OR_BLANK:
	ld	hl, [options_menu.cursor_definition]
	ld	a, [options_menu.current_position]
	cp	b
	jp	z, PRINT_TEXT
.PRINT_BLANK:
	xor	a
	cp	[hl]
	ret	z ; \0 found
	ld	a, $20 ; " " ASCII
	ld	[de], a
	inc	hl
	inc	de
	jr	.PRINT_BLANK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Hides the options menu cursor
HIDES_OPTIONS_MENU_CURSOR:
	ld	b, 0
	ld	hl, [options_menu.coordinates]
.LOOP:
	push	bc ; (preserves counter)
; Reads the coordinates
	ld	e, [hl]
	inc	hl
	ld	d, [hl]
	inc	hl
; Compares with the current option
	push	hl ; (preserves data pointer)
	ld	hl, [options_menu.cursor_definition]
	call	PRINT_OPTIONS_MENU_CURSOR.PRINT_BLANK
	pop	hl ; (restores data pointer)
	pop	bc ; (restores size)
	inc	b
	ld	a, [options_menu.size]
	cp	b
	jr	nz, .LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret nc: no option change
; ret c: option change
HANDLE_OPTIONS_MENU_UP_DOWN:
	ld	a, [input.edge]
; Changes option on stick
	bit	BIT_STICK_UP, a
	jr	nz, HANDLE_OPTIONS_MENU.DEC
	bit	BIT_STICK_DOWN, a
	jr	nz, HANDLE_OPTIONS_MENU.INC
	or	a ; (rets nc)
	ret

; ret c: option change
HANDLE_OPTIONS_MENU_UP_DOWN_CIRCULAR:
	ld	a, [input.edge]
; Changes option on stick
	bit	BIT_STICK_UP, a
	jr	nz, HANDLE_OPTIONS_MENU.DEC_CIRCULAR
	bit	BIT_STICK_DOWN, a
	jr	nz, HANDLE_OPTIONS_MENU.INC_CIRCULAR
	or	a ; (rets nc)
	ret

; ret nc: no option change
; ret c: option change
HANDLE_OPTIONS_MENU_LR:
	ld	a, [input.edge]
; Changes option on stick
	bit	BIT_STICK_LEFT, a
	jr	nz, HANDLE_OPTIONS_MENU.DEC
	bit	BIT_STICK_RIGHT, a
	jr	nz, HANDLE_OPTIONS_MENU.INC
	or	a ; (rets nc)
	ret

; ret c: option change
HANDLE_OPTIONS_MENU_LR_CIRCULAR:
	ld	a, [input.edge]
; Changes option on stick
	bit	BIT_STICK_LEFT, a
	jr	nz, HANDLE_OPTIONS_MENU.DEC_CIRCULAR
	bit	BIT_STICK_RIGHT, a
	jr	nz, HANDLE_OPTIONS_MENU.INC_CIRCULAR
	or	a ; (rets nc)
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret nz: accept current selection
; ret z+nc: no option change
; ret z+c: option change
HANDLE_OPTIONS_MENU_TRIGGER_AB:
	ld	a, [input.edge]
; Accepts on trigger A
	bit	BIT_TRIGGER_A, a
	ret	nz
; No option change on no trigger B
	or	a ; (prepares nc)
	bit	BIT_TRIGGER_B, a
	ret	z ; (rets z+nc)
; Changes option on trigger B (was: option change)
	call	HANDLE_OPTIONS_MENU.LAST
	jp	c, .RET_Z_C
; Accepts on trigger B (was: no option change, already last option)
	or	-1 ; (rets nz+nc)
	ret
.RET_Z_C:
	xor	a ; (prepares z)
	scf	; (prepares c)
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ret nc: no option change
; ret c: option change
HANDLE_OPTIONS_MENU:

; Moves up/left towards the first option
.DEC:
; First option?
	ld	hl, options_menu.current_position
	ld	a, [hl]
	or	a
	jr	nz, .DO_DEC ; no
; yes ; (rets nc)
	ret

; Moves up/left towards the first option, or wraps around to the last option
.DEC_CIRCULAR:
; First option?
	call	.DEC
	ret	c ; no
; yes
	jr	.DO_LAST

; Actually decreases the current position
.DO_DEC:
	dec	[hl]
; Feedback sound
	IFEXIST	CFG_MENU_ON_MOVE
		call	CFG_MENU_ON_MOVE
	ENDIF ; IFEXIST CFG_MENU_ON_MOVE
; rets c
	scf
	ret


; Moves down/right towards the last option
.INC:
; Last option?
	ld	hl, options_menu.current_position
	ld	a, [options_menu.size]
	dec	a
	cp	[hl]
	jr	nz, .DO_INC ; no
; yes ; (rets nc)
	ret

; Moves down/right towards the last option, or wraps around to the first option
.INC_CIRCULAR:
; Last option?
	call	.INC
	ret	c ; no
; yes
	jr	.DO_FIRST

; Actually increases the current position
.DO_INC:
	inc	[hl]
; Feedback sound
	IFEXIST	CFG_MENU_ON_MOVE
		call	CFG_MENU_ON_MOVE
	ENDIF ; IFEXIST CFG_MENU_ON_MOVE
; rets c
	scf
	ret


; Actually sets the current position to the first position
.DO_FIRST:
	xor	a
	ld	[hl], a
; Feedback sound
	IFEXIST	CFG_MENU_ON_MOVE
		call	CFG_MENU_ON_MOVE
	ENDIF ; IFEXIST CFG_MENU_ON_MOVE
; rets c
	scf
	ret


; Moves directly to the last option
.LAST:
; Last option?
	ld	hl, options_menu.current_position
	ld	a, [options_menu.size]
	dec	a
	cp	[hl]
	jr	nz, .DO_LAST_A_OK ; no
; yes ; (rets nc)
	ret

; Actually sets the current position to the last position
.DO_LAST:
	ld	a, [options_menu.size]
	dec	a
.DO_LAST_A_OK:
	ld	[hl], a
; Feedback sound
	IFEXIST	CFG_MENU_ON_MOVE
		call	CFG_MENU_ON_MOVE
	ENDIF ; IFEXIST CFG_MENU_ON_MOVE
; rets c
	scf
	ret
; -----------------------------------------------------------------------------

; EOF
