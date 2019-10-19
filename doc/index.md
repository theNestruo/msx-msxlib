# Getting started with MSXlib

MSXlib is composed of several groups of libraries (ASM files): MSX-related core, MSX-related optionals, games core, genre-specific (such as platformers), and generic game optionals.
This libraries can be used incrementally, but designed to work together.

This document will help you start using MSXlib using a serie of examples.


## Toolchain

MSXlib libraries syntax is [tniASM v0.45](http://tniasm.tni.nl/).

The binary files of the examples are created with [PCXTOOLS](https://github.com/theNestruo/pcxtools) and [Tiled](http://www.mapeditor.org/), and packed with [ZX7](https://github.com/z88dk/z88dk/tree/master/src/zx7).


## Chapters

[Minimal MSXlib cartridge](guide/00-minimal.md): MSXlib will help you reduce the boilerplate code and obscure technical stuff, so you can simply focus on coding your game.
> - [Minimal example](../games/example/00minimal/00minimal.asm)

### [Generic MSXlib cartridge](guide/01-basic.md)

> Start getting real benefits of using MSXlib.
> - [Basic example](../games/example/01basic/01basic.asm)
> - [Snake game example](../games/example/02snake/02snake.asm)

## Appendices

### [MSXlib for non-MSXlib projects](guide/A1-non-msxlib.md)

Some parts of MSXlib can be included in any project without actually using MSXlib.


<!--
## Reference documentation

Cartridge
Hook
Input
VRAM
...
-->
