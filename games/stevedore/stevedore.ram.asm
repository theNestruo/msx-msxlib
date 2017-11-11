
;
; =============================================================================
;	Game var
; =============================================================================
;

; -----------------------------------------------------------------------------
;	User vars

; Global vars (i.e.: initialized only once)
globals:

.chapters:
	rb	1 ; (unlocked chapters)
.hi_score:
	rb	3 ; (6 BCD digits)

; Game vars (i.e.: vars from start to game over)
game:

.score:
	rb	3 ; (6 BCD digits)
.lives:
	rb	1
.stage:
	rb	1
.stage_bcd:
	rb	1 ; (2 BCD digits)

; Stage vars (i.e.: vars inside the main game loop)
stage:

; Number of consecutive frames the player has been pushing an object
player.pushing:
	rb	1
; The flags the define the state of the stage
stage.flags:
	rb	1
; Frame counter (e.g. to animate dynamic charset)
stage.framecounter:
	rb	1

; Main menu vars
menu:

; NAMTBL buffer pointer to start printing stage select options
.namtbl_buffer_origin:
	rw	1
; Coordinates of the sprite depending on the selected stage
.player_0_table:
	rb	2 ; Lighthouse
	rb	2 ; Ship
	rb	2 ; Jungle
	rb	2 ; Volcano
	rb	2 ; Temple
	rb	2 ; Warehouse (tutorial)
; The actual selection
.selected_chapter:
	rb	1
; -----------------------------------------------------------------------------

; EOF
