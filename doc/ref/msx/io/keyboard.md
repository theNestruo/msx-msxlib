# Keyboard input routines

> Important notice: These routines change OLDKEY/NEWKEY semantics!

## `RESET_KEYBOARD`
Initializes the level values before the first READ_KEYBOARD invocation.
- ret [OLDKEY + i]: $00

## `READ_KEYBOARD`
Reads the keyboard level and edge values.
- param b: number of keyboard rows to read
- param c: first keyboard row to be read
- ret [OLDKEY + i]: current bit map (level)
- ret [NEWKEY + i]: bits that went from off to on (edge)

> Important: if `CFG_HOOK_ENABLE_AUTO_KEYBOARD` is set, this routine is automatically invoked during the [MSXlib `H.TIMI` hook](../hook.md#HOOK) and there is no need to invoke this routine manually.
