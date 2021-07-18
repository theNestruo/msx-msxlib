
# Getting started with MSXlib

This chapter will help you start creating MSX videogame cartridges.


## Preconditions

In order to use MSXlib, entry level Z80 assembly is required.

A basic knowledge of the MSX system architecture and capabilities is desirable: screen modes, graphics limitations, sprites, etc. Advanced topics, such as slots/subslots, and memory addressing are not required; for starters, most ROMs will be at most 32KB, so the memory map will be as simplest as possible: BIOS-ROM-ROM-RAM.


## Toolchain

Assembly files are plain text. You can use any text editor to edit them: [Visual Studio Code](https://code.visualstudio.com/) (recommended), [Sublime Text](https://www.sublimetext.com/), [Notepad++](https://notepad-plus-plus.org/), [vim](https://www.vim.org/), etc.

To assemble the source code, you need a Z80 assembler. Z80 assembly is not an standard language, and most (if not all) assemblers have dialect-specific features and variations. MSXlib libraries syntax is [tniASM v0.45](http://tniasm.tni.nl/), so it's the recommended assembler. You can use a different assembler (asMSX, Glass, sjASM and derivatives, YAZD/YAZA, etc.), but in most cases (if not all) that will require you to tweak MSXlib source code.

Binary files (i.e.: charset graphics, sprites, screen definitions, etc.) can be generated using MSX-specific tools (such as [nMSXtiles](https://github.com/pipagerardo/nMSXtiles), [MSX Tiles devtool](https://github.com/mvac7/MSXTILESdevtool), or [spriteSX devtool](https://github.com/mvac7/spriteSXdevtool)), or use a command line interface converter (such as [PCXTools](https://github.com/theNestruo/pcxtools) or [MSX Pixel Tools](https://github.com/reidrac/msx-pixel-tools)). Either way, you should end up having binary .chr and .clr files (for the charset definition) and .spr files (for sprite pattern definitions).

For compressing data, you'll need a packer with a Z80 depacker implementation available. Currently, [ZX0](https://github.com/einar-saukas/ZX0) (default and recommended), [ZX1](https://github.com/einar-saukas/ZX1), [ZX7](https://github.com/z88dk/z88dk/tree/master/src/zx7), and [Pletter 0.5c1](http://www.xl2s.tk/) are natively supported in MSXlib.

The binary files of the examples have been created with PCXTools and [Tiled](http://www.mapeditor.org/), and packed with ZX0.

To assemble a cartridge, you need to prepare the binary files, pack them, and then execute the assemble. To alleviate this workflow, MSXlib recommends using a `makefile`. You'll need `make`; it is most likely already installed in Linux and MacOS, but in Windows you may need to install [mingw-w64](http://mingw-w64.org/doku.php/download/mingw-builds) (or similar software) or use the Windows Subsystem for Linux (WSL). Alternatively, you can create a .bat/.sh script to do the job.


## First run

Note: this section assumes you are using Visual Studio Code. If you are using different tooling, skips the steps accordingly.

Download MSXlib and open it. Visual Studio Code will suggest some extensions; install [Z80 Macro-Assembler](https://marketplace.visualstudio.com/items?itemName=mborik.z80-macroasm) at least.

From a command line console, type `make -f examples.makefile`. That will run the default target of the examples makefile, and the output should be similar to this (blank lines added for legibility):

```
C:\dev\msx-msxlib>make -f examples.makefile

tniasm.exe games\examples\00minimal\minimal.asm games\examples\00minimal\minimal.rom
Preprocessing...
Pass 1...
Pass 2...
Generating Output...
Finished in 0.14 seconds.

pcx2msx+.exe -lh games\examples\shared\charset.pcx

zx0.exe games\examples\shared\charset.pcx.chr
ZX0 v1.2: Optimal data compressor by Einar Saukas
File compressed from 2048 to 1065 bytes! (delta 2)

zx0.exe games\examples\shared\charset.pcx.clr
ZX0 v1.2: Optimal data compressor by Einar Saukas
File compressed from 2048 to 405 bytes! (delta 2)

pcx2spr.exe games\examples\shared\sprites.pcx

zx0.exe games\examples\shared\sprites.pcx.spr
ZX0 v1.2: Optimal data compressor by Einar Saukas
File compressed from 1024 to 713 bytes! (delta 2)

tmx2bin.exe games\examples\shared\screen.tmx games\examples\shared\screen.tmx.bin

zx0.exe games\examples\shared\screen.tmx.bin
ZX0 v1.2: Optimal data compressor by Einar Saukas
File compressed from 768 to 68 bytes! (delta 3)

tniasm.exe games\examples\01basic\basic.asm games\examples\01basic\basic.rom
Preprocessing...
Pass 1...
Pass 2...
Generating Output...
Finished in 0.17 seconds.

tniasm.exe games\examples\02snake\snake.asm games\examples\02snake\snake.rom
Preprocessing...
Pass 1...
Pass 2...
Generating Output...
Finished in 0.06 seconds.

(...)
```

If there are errors, most likely cause is that the required tools are not available in the path. Either modify your path to include them, or edit the `config.makefile` file to prepend the proper path for each tool in the `# tools` section. If you prefer to keep your MSXlib installation self-contained, you can create a `bin` folder with all the required tools and edit the `config.makefile` file accordingly.

What happened here? The default target of the examples makefile (`default: compile`) tries to compile the example .rom files (`ROMS`, i.e.: `minimal.rom`, `basic.rom`, `snake.rom`, etc.). Each of this files depends on it own source code, the MSXlib source code, and shared data. As the shared data files do not exist (yet), they are created from the .pcx source images following the rules defined in the makefile. Once the dependencies are satisfied, the source code is assembled.

If you opted for the makefile-less path, your script should be similar to this:

```bat
REM Shared binaries 1/2: binaries
pcx2msx+.exe -lh games\examples\shared\charset.pcx
pcx2spr.exe games\examples\shared\sprites.pcx
tmx2bin.exe games\examples\shared\screen.tmx games\examples\shared\screen.tmx.bin

REM Shared binaries 2/2: packs the binaries
zx0.exe games\examples\shared\charset.pcx.chr
zx0.exe games\examples\shared\charset.pcx.clr
zx0.exe games\examples\shared\sprites.pcx.spr
zx0.exe games\examples\shared\screen.tmx.bin

REM Assembly
tniasm.exe games\examples\00minimal\minimal.asm games\examples\00minimal\minimal.rom
tniasm.exe games\examples\01basic\basic.asm games\examples\01basic\basic.rom
tniasm.exe games\examples\02snake\snake.asm games\examples\02snake\snake.rom
```

If you are using Visual Studio Code, the `.vscode\tasks.json` can be used to define tasks to run the makefile (or any other task). MSxlib already provides this file with the build task bound to `Ctrl+Shift+B` (Tasks: Run Build Task). Besides the convenience of running the build with a keystroke, the main advantage is that the problem matcher will integrate any assembler error with the Problems view, making it easy to navigate to source code errors.


## The minimal MSX cartridge

Let's create a minimal MSX cartridge; this will serve a as base for further explanations:

```assembly
; -----------------------------------------------------------------------------
; ROM (pages 1 and 2)
	org	$4000, $7fff

; MSX cartridge (ROM) header
	db	"AB"		; ROM Catridge ID ("AB")
	dw	CARTRIDGE_INIT	; INIT
	dw	$0000		; STATEMENT
	dw	$0000		; DEVICE
	dw	$0000		; TEXT
	ds	$4010 - $, $00	; Reserved

; Cartridge entry point
CARTRIDGE_INIT:
	;
	; YOUR CODE (ROM) GOES HERE
	;
	ret

; Padding to a 16kB boundary with $FF (RST $38)
	ds	($ OR $1fff) -$ +1, $ff ; (8kB boundary to allow 8kB or 24kB ROMs)
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; RAM (8kB, page 3)
	org	$e000, $f380

	;
	; YOUR VARIABLES (RAM) START HERE
	;
; -----------------------------------------------------------------------------
```

What does this source code do?

The first `org` directive makes the assembler to start "writing code" at $4000, which is the start of the page 1, just after the BIOS (page 0). At that address, it writes the standard MSX cartridge header so the game starts at boot at the address specified as `INIT`: `CARTRIDGE_INIT`.

The code section does nothing but `ret`-urning to MSX-BASIC.

It is a good practice (or, at least, it is usual) to fill the gap until the end of the ROM (the next 8kB boundary) with $FF (`RST $38`).

Then, the second `org` directive points to $E000, within the page 3, where the MSX is guarateed to have RAM (even in 8kB RAM models). Therefore, you can declare your variables here.

Of course, this rom is not particularly interesting, but at least it is a starting point. Try changing the `ret` with a `jr $` and the cartridge will stop there without returning to MSX-BASIC. Voilà! You have a place to write code that actually executes!

> Symbolic constants for MSX BIOS entry points, MSX system variables, VRAM addresses and symbolic constants, PPI (Programmable Peripheral Interface) ports, and some special ASCII codes are already available by including `lib/msx/symbols.asm`:
> ```assembly
> include "lib/msx/symbols.asm"
> ```
> This file does not add any code to your project, but allows you to type `call ENASCR` (instead of the more obscure `call $0044`). It can also be used as a reference.
>
> For a complete list of the defined symbolic constants, please refer to the actual contents of the file.


## The minimal MSXlib cartridge

If you started to play around with the minimal MSX cartridge, you have probably discovered that you need to initailize things (such as BASIC `COLOR 15,0,0` and `SCREEN 2,2,0`). This initialization phase tends to become a bunch of boilerplate code that you will be copying from game to game... Let's create a minimal MSXlib cartridge:

```assembly
; MSX symbolic constants
	include	"lib/msx/symbols.asm"

; -----------------------------------------------------------------------------
; ROM

; MSX cartridge (ROM) header, entry point and initialization
	include "lib/msx/cartridge.asm"

; Game entry point
INIT:
	;
	; YOUR CODE (ROM) GOES HERE
	;
	ret

	include	"lib/msx/rom_end.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; RAM

; MSXlib core and game-related variables
	include	"lib/ram.asm"

	;
	; YOUR VARIABLES (RAM) START HERE
	;

	include	"lib/msx/ram_end.asm"
; -----------------------------------------------------------------------------
```

It doesn't look very different from the minimal MSX cartridge, but the obscure directives (the orgs and the padding) are gone... But, if you assemble and execute the ROM, it will give you a black screen instead of MSX-BASIC! Actually, the file `lib/msx/cartridge.asm` includes the cartridge header and performs some initialization for you. Without other MSXlib modules present, this initialization comprises:
* Initializes the interrupt mode and the stack pointer
* Ensures the CPU is in Z80 mode when running in a MSX turbo R or superior
* Initializes the screen with the ASM equivalent to BASIC `COLOR 15,0,0` and `SCREEN 2,2,0`
* Disables the screen
* Zeroes all the used RAM
* Initializes the PSG to silence
* Saves the refresh rate in Hertzs (50Hz/60Hz) reported by the BIOS into `frame_rate`, and the number of frames per tenth into `frames_per_tenth`
* Jumps to the `INIT` label

So, when the execution reaches `INIT`, everything is conveniently initialized for you.

> By default, MSXlib will create an 8kB/16kB cartridge. If you want to force an specific cartridge size, or if your cartridge is larger than 16kb, you can specify the target cartridge size. If your cartridge target size is larger than 16kb (typically, 32kB), this will cause the initialization to the search for page 2 slot/subslot:
> ```assembly
> CFG_INIT_ROM_SIZE:	equ 32
> include "lib/msx/cartridge.asm"
> ```
> The supported cartridge target sizes are: 8kB, 16kB, 24kB, 32kB, and 48kB.

At this point, the cartridge is init, the RAM zeroed, the screen mode is 2 with 16x16 unmagnified sprites, the keyboard click is muted, and the screen is disabled.

Please note that the screen is disabled after the initialization! This is intentional and actually convenient (to load the game charset, for example), but don't forget to `call ENASCR`.

The `lib/msx/rom_end.asm` include marks the end of the ROM, and MSXlib automatically pads the remaining space to the next 8kB boundary.

For the RAM part, always start including `lib/ram.asm`. This will define the RAM start ($E000 by default), and include the variables MSXlib requires depending on the includes you are using. Your variables can be declared after that. Don't forget to include `lib/msx/ram_end.asm` after your variables. This include lets MSXlib know where the RAM ends (to zero it during initialization).

> If your RAM requirements are 16kB instead of 8kB, define the following for the initialization to check the availability of 16kB, and to make the RAM start at the beginning of the page 2 ($c000) instead of at $e000:
> ```assembly
> CFG_INIT_16KB_RAM:
> include "lib/msx/cartridge.asm"
> ```

If you want to actually "see something", please check the [minimal MSXlib cartridge example](../games/examples/00minimal/minimal.asm) that writes the classical "Hello, World!" sentence in SCREEN 2.


## A not-so-minimal MSXlib cartridge

The minimal MSXlib cartridge described in the previous section reduces the boilerplate code and lets you focus on your code, but doesn't provide any help with that code. You are still stuck with the MSX BIOS... Let's create a not-so-minimal MSXlib cartridge:

```assembly
; -----------------------------------------------------------------------------
; ROM

; MSXlib helper: default configuration
	include	"lib/rom-default.asm"

; Game entry point
INIT:
	;
	; YOUR CODE (ROM) GOES HERE
	;
	ret

	include	"lib/msx/rom_end.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; RAM

; MSXlib core and game-related variables
	include	"lib/ram.asm"

	;
	; YOUR VARIABLES (RAM) START HERE
	;

	include	"lib/msx/ram_end.asm"
; -----------------------------------------------------------------------------
```

Without other MSXlib modules present, this initialization comprises:

Not much has changed. It's actually quite similar to the previous minimal example. But `lib/rom-default.asm` is actually a convenience shortcut to include the general purpose core libraries of MSXlib with sensible defaults. Namely:
* Includes `lib/msx/symbols.asm`.
* Includes the cartridge header and initialization, which now sets up the MSXlib hook to read input (and disables BIOS key interruption)
* Includes the NAMTBL and SPRATR buffer routines, fade-in/out routines, text routines, logical coordinates sprites routines, timing routines, and pause routines.
* Includes generic Z80 assembly convenience routines.
* Includes ZX0 decoder as the unpacker routine, and reserves a buffer of 2048 bytes for it.

The cartridge initialization described in the previous section included the statement "without other MSXlib modules present". In MSXlib, modules designed to work cohesively automatically detect each other. `lib/msx/cartridge.asm` is one of them, hence the initialization of the MSXlib hook. Also, `lib/ram.asm` automatically reserves space for the variables required by the active MSXlib modules. `lib\msx\unpack\unpack_zx0.asm` allows other modules to work with compressed data.

The game entry point must be named `INIT`.

> Please note that BIOS key interruption gets disabled by MSXlib by default, so variables depending on it (such as `TRGFLG` byte, or the `OLDKEY` and `NEWKEY` matrices) can no longer be used.


## Congratulations!

You are in the starting line to develop MSXlib based games!


---

* Back to index: [MSXlib Development Guide](index.md)
* Next chapter: [Before you continue...](chapter2.md)
