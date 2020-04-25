# Timing and wait routines

## `WAIT_FOUR_SECONDS`
Four seconds pause

## `WAIT_TWO_SECONDS`
Two seconds pause

## `WAIT_ONE_SECOND`
One second pause

## `WAIT_FRAMES`
Pause
- param b: pause length (in frames)

## `WAIT_TRIGGER_FOUR_SECONDS`
Skippable four seconds pause
- ret nz: if the trigger went from off to on (edge)
- ret z: if the pause timed out

## `WAIT_TRIGGER_ONE_SECOND`
Skippable one second pause
- ret nz: if the trigger went from off to on (edge)
- ret z: if the pause timed out

## `WAIT_TRIGGER_FRAMES_A`
Skippable pause
- param a: pause length (in frames)
- ret nz: if the trigger went from off to on (edge)
- ret z: if the pause timed out

## `WAIT_TRIGGER_FRAMES`
Skippable pause
- param b: pause length (in frames)
- ret nz: if the trigger went from off to on (edge)
- ret z: if the pause timed out

## `WAIT_TRIGGER`
Waits for the trigger
- ret nz always: the trigger went from off to on (edge)
