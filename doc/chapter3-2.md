
# MSXlib cookbook: Player input

A cookbook that explains the MSXlib capabilities using examples and source code.


## Waiting and "Push space key"

To include a unskippable wait, call `WAIT_ONE_SECOND`, `WAIT_TWO_SECONDS`, or `WAIT_FOUR_SECONDS`. These routines work both in PAL (50Hz) and NTSC (60Hz) models.

To wait an specific number of frames, call `WAIT_FRAMES` with the pause length (in frames) in the register B.

To include an skippable wait, use `WAIT_TRIGGER_FOUR_SECONDS`, `WAIT_TRIGGER_ONE_SECOND`, or `WAIT_TRIGGER_FRAMES` instead. In this case, the routines will return the flag Z if the pause timed out, and the flag NZ if the trigger was triggered.

Example:
```assembly
	call  WAIT_TRIGGER_FOUR_SECONDS
	jp    nz, GAME_START
	jp    ATTRACT_MODE
```

Use `WAIT_TRIGGER` for an undefined pause. This function always returns the flag NZ (so it is interchangeable with the former routines).


## Reading cursors and joystick input

> Please note that BIOS key interruption gets disabled by MSXlib by default, so variables depending on it (such as `TRGFLG` byte, or the `OLDKEY` and `NEWKEY` matrices) can no longer be used.

By default, MSXlib hook takes control of reading the input on every frame and conveniently saving the input status in RAM.
For example, to check if either the joystick or the keyboard are pointing to a direction, in MSXlib you can use the following code:
```assembly
	ld   a, [input.level]
	bit  BIT_STICK_UP, a
	jr   nz, MOVE_PLAYER_UP ; (routine provided by the developer)
```

The bits for `input.level` are defined as:
```assembly
BIT_STICK_UP:		equ 0
BIT_STICK_DOWN:		equ 1
BIT_STICK_LEFT:		equ 2
BIT_STICK_RIGHT:	equ 3
BIT_TRIGGER_A:		equ 4
BIT_TRIGGER_B:		equ 5
BIT_BUTTON_SELECT:	equ 6
BIT_BUTTON_START:	equ 7
```

By default, trigger B is mapped to the `M` key, the SELECT bit to the `SELECT` key, and the START bit to the `STOP` key.

Additionaly, besides `input.level` (that returns the actual status of the bit) you can use `input.edge` to sense when a key gets pressed. This is particularly useful for firing or jumping, or for movements that are not to be repeated each frame (e.g.: moving a cursor on a menu):
```assembly
	ld  a, [input.edge]
	bit BIT_TRIGGER_A, a
	jr  nz, FIRE_CANNONS ; (routine provided by the developer)
```

> If you want to perform manual input read, disable automatic reads by defining:
> ```assembly
> CFG_HOOK_DISABLE_AUTO_INPUT
> ```
> And then invoke `READ_INPUT` manually. The value of `input.level` and `input.edge` will be returned in registers `b` and `a` for direct use, and still will be saved as `input.level` and `input.edge`, so there is no need to manually store their values nor invoke `READ_INPUT` more than once.


## Reading the keyboard

> Important notice: These routines change the BIOS semantics of the system variables `OLDKEY` and `NEWKEY`!

If the cursors and joystick input does not cover the keys you need to read (e.g.: F1), MSXlib offers an efficient way to read the keys you need.

As MSXlib registers both level (current state of the key) and edge (the "keydown" event; the frame the key is pressed), you need to initialize the level values before the first read by calling `RESET_KEYBOARD`.

Then, once per frame (or, at least, as frequently as possible), invoke `READ_KEYBOARD`.

To avoid reading the entire keyboard matrix for performance reasons, this routine takes two parameters:
- the first keyboard row to be read in C.
- the number of keyboard rows to read in B.

The results of the reading are stored in the system variables `OLDKEY` and `NEWKEY`:
- `OLDKEY + row` will contain the current state of the key (the level, similar to `input.level`), 1 meaning it is currently pressed.
- `NEWKEY + row` will contain the "keydown" events, the keys that were pressed in the current frame (similar to `input.edge`), 1 meaning the key was pressed in the current frame.

If you are used to BIOS, please note the different semantics of the system variables `OLDKEY` and `NEWKEY`!

Example:
```assembly
; Reads all the function keys (they split into two rows)
	ld    b, 2
	ld    c, 6 ; $06 = F3 F2 F1 CODE CAP GRAPH CTRL SHIFT
	           ; $07 = CR SEL BS STOP TAB ESC F5 F4
	call  READ_KEYBOARD

; Pauses the game when the player presses F1
	ld    a, [NEWKEY + 6] ; F3 F2 F1 CODE CAP GRAPH CTRL SHIFT
	bit   5, a
	call  nz, PAUSE_ROUTINE

; Increases the energy if the player is holding F5 (cheat!)
	ld    a, [OLDKEY + 7] ; CR SEL BS STOP TAB ESC F5 F4
	bit   1, a
	call  nz, CHEAT
```

> Please note that, if `CFG_HOOK_ENABLE_AUTO_KEYBOARD` is set, this routine is automatically invoked during the MSXlib `H.TIMI` hook, so there is no need to invoke this routine manually; `OLDKEY` and `NEWKEY` will be loaded after every frame. Also please note that, in this case, the entire keyboard matrix will be read.

For reference purposes, this is the international keyboard matrix:
|        | bit 7 | bit 6 | bit 5  | bit 4 | bit 3 | bit 2 | bit 1 | bit 0 |
|--------|-------|--------|-------|-------|-------|-------|-------|-------|
| row 0  | 7 &   | 6 ^    | 5 %   | 4 $   | 3 #   | 2 @   | 1 !   | 0 )   |
| row 1  | ; :   | ] }    | [ {   | \ ¦   | = +   | - _   | 9 (   | 8 *   |
| row 2  | B     | A      | DEAD  | / ?   | . >   | , <   | ` ~   | ' "   |
| row 3  | J     | I      | H     | G     | F     | E     | D     | C     |
| row 4  | R     | Q      | P     | O     | N     | M     | L     | K     |
| row 5  | Z     | Y      | X     | W     | V     | U     | T     | S     |
| row 6  | F3    | F2     | F1    | CODE  | CAPS  | GRAPH | CTRL  | SHIFT |
| row 7  | RET   | SELECT | BS    | STOP  | TAB   | ESC   | F5    | F4    |
| row 8  | &rarr;| &darr; | &uarr;| &larr;| DEL   | INS   | HOME  | SPACE |
| row 9  | NUM4  | NUM3   | NUM2  | NUM1  | NUM0  | NUM/  | NUM+  | NUM*  |
| row 10 | NUM.  | NUM,   | NUM-  | NUM9  | NUM8  | NUM7  | NUM6  | NUM5  |
(This keyboard matrix is also documented in `lib/msx/symbols.asm` as comments for `SNSMAT`, `OLDKEY` and `NEWKEY`)


---
* Back to index: [MSXlib Development Guide](index.md)
* Previous chapter: [MSXlib cookbook: Texts and graphics](chapter3-1.md)
* Next chapter: [MSXlib cookbook: Music and sound effects](chapter3-3.md)
