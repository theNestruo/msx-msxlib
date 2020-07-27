
# MSXlib Development Guide

MSXlib is a set of assembly libraries to create MSX videogame cartridges.

MSXlib is BIOS-based, and it is divided in several libraries: MSX-related core, MSX-related optionals, games core, genre-specific (such as platformers), and generic game optionals. These libraries can be used incrementally, but are designed to work together.

## Index

### 1. [Getting started with MSXlib](chapter1.md)
The "Getting started with MSXlib" chapter will help you start creating MSX videogame cartridges.

* Preconditions
* Toolchain
* First run
* The minimal MSX cartridge
* The minimal MSXlib cartridge
* A not-so-minimal MSXlib cartridge

### 2. [Before you continue...](chapter2.md)
This chapter gives some bases of MSXlib that are used in most of the modules. It is convenient to know them prior to exploring the following chapters.

* The MSXlib VRAM buffers
* Assembly helper routines
* Compressed data unpacker

### 3. [MSXlib cookbook](chapter3.md)
A cookbook that explains the MSXlib capabilities using examples and source code.

* Loading the charset graphics
* Waiting and "Push space key"
* Reading cursors and joystick input
* Reading the keyboard
* Printing text in screen
* Printing numbers in screen
* Putting sprites
* Flickering sprites
* Fading-in/out the screen
* Replaying music in the background
* Playing sounds
* Using page 0 ($0000-$3FFF) as a compressed data storage

### [Appendix A. MSXlib reference](appendixA.md)
Non-comprehensive reference for some MSXlib modules.

* MSXlib cartridge initialization sequence
* MSXlib interrupt routine (`H.TIMI` hook)


---
* Back to index: [MSXlib Development Guide](index.md)
* Previous chapter: [Before you continue...](chapter2.md)
