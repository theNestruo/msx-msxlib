
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

### 3. MSXlib cookbook
A cookbook that explains the MSXlib capabilities using examples and source code.

This chapter is subdivided in the following sections:

* [Texts and graphics](chapter3-1.md)
	* Loading the charset graphics
	* Printing text in screen
	* Printing numbers in screen
	* Putting sprites
	* Flickering sprites
	* Fading-in/out the screen
* [Player input](chapter3-2.md)
	* Waiting and "Push space key"
	* Reading cursors and joystick input
	* Reading the keyboard
* [Music and sound effects](chapter3-3.md)
	* Replaying music in the background
	* Playing sounds
* [Other recipes](chapter3-4.md)
	* Using page 0 ($0000-$3FFF) as a compressed data storage
	* Detecting a catridge in the secondary slot

### [Appendix A. MSXlib reference](appendixA.md)
Non-comprehensive reference for some MSXlib modules.

* MSXlib cartridge initialization sequence
* MSXlib interrupt routine (`H.TIMI` hook)


---
* Back to index: [MSXlib Development Guide](index.md)
* Previous chapter: [Before you continue...](chapter2.md)
