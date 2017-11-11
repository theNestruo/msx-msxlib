
;
; =============================================================================
;	Game var
; =============================================================================
;

; -----------------------------------------------------------------------------
;	User vars

; Global vars (i.e.: initialized only once)
globals:

.zones:
	rb	1
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

.namtbl_buffer_origin:
	rw	1
.player_0_table:
	rb	2 * 6
.selected_zone:
	rb	1

; -----------------------------------------------------------------------------

; EOF
