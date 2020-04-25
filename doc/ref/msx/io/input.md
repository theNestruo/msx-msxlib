# Input routines (BIOS-based)

## `READ_INPUT`
Reads joystick and keyboard as a bit map.

Reads both bits that went from off to on (edge) and the current status (level).
- ret a / [input.edge]: bits that went from off to on (edge)
- ret b / [input.level]: current bit map (level)

Symbolic constants for the bit map:
- 0: `BIT_STICK_UP`
- 1: `BIT_STICK_DOWN`
- 2: `BIT_STICK_LEFT`
- 3: `BIT_STICK_RIGHT`
- 4: `BIT_TRIGGER_A`
- 5: `BIT_TRIGGER_B`
- 6: `BIT_BUTTON_SELECT`
- 7: `BIT_BUTTON_START`

> Important: if `CFG_HOOK_DISABLE_AUTO_INPUT` is **not** set, this routine is automatically invoked during the [MSXlib `H.TIMI` hook](../hook.md#HOOK) and there is no need to invoke this routine manually.
