# Interrupt routine (`H.TIMI` hook)

## `HOOK`
MSXlib `H.TIMI` hook.

- If a replayer is included, invokes the replayer
- Automatically reads the inputs
	- If `CFG_HOOK_ENABLE_AUTO_KEYBOARD` is set, [reads the entire keyboard matrix](io/keyboard.md#READ_KEYBOARD)
	- If `CFG_HOOK_DISABLE_AUTO_INPUT` is **not** set, [reads the cursors and joystick](io/input.md#READ_INPUT)
- Tricks BIOS' `KEYINT` to skip keyboard scan, `TRGFLG`, `OLDKEY`/`NEWKEY`, `ON STRIG`...
- Invokes the previously existing hook

> Important: This hook is automatically installed by [MSXlib cartridge entry point](cartridge.md#CARTRIDGE_INIT).


# Configuration

Automatic input read in the hook can be disabled. In that case, you need to manually `call READ_INPUT` to update `input.level` and `input.edge`. To disable automatic input read in the hook define:
```
	CFG_HOOK_DISABLE_AUTO_INPUT:
```

<!--
If automatic input is disabled, BIOS key interruption routine can be restored by additionally defining:
```
	CFG_HOOK_DISABLE_AUTO_INPUT:
	CFG_HOOK_KEEP_BIOS_KEYINT:
```
-->
