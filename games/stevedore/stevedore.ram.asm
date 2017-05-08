
;
; =============================================================================
;	Game var
; =============================================================================
;

; -----------------------------------------------------------------------------
;	User vars

; Global vars (i.e.: initialized only once)
globals:

.hi_score:
	rw	1

; Game vars (i.e.: vars from start to game over)
game:

.current_stage:
	rb	1
.continues:
	rb	1
.score:
	rw	1
.lives:
	rb	1

; Stage vars (i.e.: vars inside the main game loop)
stage:

; Number of consecutive frames the player has been pushing an object
player.pushing:
	rb	1
; The flags the define the state of the stage
stage.flags:
	rb	1
; -----------------------------------------------------------------------------

; EOF
