# Getting started with MSXlib

MSXlib is composed of several groups of libraries (ASM files): MSX-related core, MSX-related optionals, games core, genre-specific (such as platformers), and generic game optionals.
This libraries can be used incrementally, but designed to work together.

This document will help you start using MSXlib using a serie of examples.


## Toolchain

MSXlib libraries syntax is [tniASM v0.45](http://tniasm.tni.nl/).

The binary files of the examples are created with [PCXTOOLS](https://github.com/theNestruo/pcxtools) and [Tiled](http://www.mapeditor.org/), and packed with [ZX7](https://github.com/z88dk/z88dk/tree/master/src/zx7).


## Chapters

### 1. [Minimal MSXlib cartridge](guide/00-minimal.md).
MSXlib will help you reduce the boilerplate code and obscure technical stuff, so you can simply focus on coding your game.
- [Minimal example](../games/examples/00minimal/minimal.asm): A "Hello, World!" in SCREEN 2.

### 2. [Generic MSXlib cartridge](guide/01-basic.md)

Start getting real benefits of using MSXlib.

- [Basic example](../games/examples/01basic/basic.asm): Basics on VRAM initialization helpers, VRAM buffers in RAM, and Cursors and joystick input.
- [Snake game example](../games/examples/02snake/snake.asm): A more elaborate example using wait routines, text printing and fading routines provided by MSXlib.


## Reference documentation

- MSX
	- [cartridge](ref/msx/cartridge.md): MSX cartridge (ROM) header, entry point and initialization
	- [hook](ref/msx/hook.md): Interrupt routine (`H.TIMI` hook)
	- I/O
		- [input](ref/msx/io/input.md): Input routines (BIOS-based)
		- [keyboard](ref/msx/io/keyboard.md): Keyboard input routines
		- [print](ref/msx/io/print.md): NAMTBL buffer text and block routines
		- [timing](ref/msx/io/timing.md): Timing and wait routines
		- [vram](ref/msx/io/vram-0.md) (1/2): VRAM routines (BIOS-based)
		- [vram](ref/msx/io/vram-1.md) (2/2): NAMBTL and SPRATR buffer routines (BIOS-based)
	- etc.
		- [fade](ref/msx/etc/fade.md): Additional NAMBTL and SPRATR buffer based routines
<!--
		- Timing
		- Print
-->

## Appendices

### A1. [MSXlib for non-MSXlib projects](guide/A1-non-msxlib.md)

Some parts of MSXlib can be included in any project without actually using MSXlib.

