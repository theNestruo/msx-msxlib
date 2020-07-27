
# Before you continue...

This chapter gives enough base of MSXlib to allow you exploring the following chapters.


## The MSXlib VRAM buffers

For the NAMTBL and the SPRATR, MSXlib creates two RAM buffers (named: `namtbl_buffer` and `spratr_buffer`). It is important to know this buffers because most of the graphic modules of MSXlib do not work directly on VRAM but rather use these buffers.

MSXlib provides several routines to work with these buffers:
* `CLS_NAMTBL` and `CLS_SPRATR` to clear them
* `LDIRVM_NAMTBL` and `LDIRVM_SPRATR` to blit them
* `DISSCR_NO_FADE` and `ENASCR_NO_FADE` to disable and enable the screen, automatically hiding and showing the sprites

Having the SPRATR buffer is particularly useful, because your code will be faster (sprites attributes are a RAM read/write operation) and all of them will move in sync (and, optionally, with flickering):
```assembly
FRAME_LOOP:
	halt
	call	LDIRVM_SPRATR
	; (...)
```

Check all the available VRAM buffers-based routines in the source code `lib\msx\io\vram.asm`


## Assembly helper routines

The file `lib\asm\asm.asm` defines several assembly helper routines. This file contains some useful convenience routines that are used internally by MSXlib (and therefore it is included by default), but that can be useful outside.

This routines emulate non-existent instructions (such as `add hl, a`), provide array functionality (`a = hl[a]`), jump tables (`ON a GOTO ...`), and others.

Please check the source code for a complete list of routines. And don't worry if you don't understand the purpose of all of them; some of them are covered in the next chapters, and you don't need to use all of them!


## Compressed data unpacker

With a unpacker module present (and it is by default), some routines "double" with a packed data version (e.g.: `LDIRVM_CHRTBL` gets a packed data-based `UNPACK_LDIRVM_CHRTBL`) while some other routines change their behaviour to work with packed data **only** (e.g.: music replayers).

This may be confusing at first but, for the sake of simplicity, this guide assumes the depacker module is always present.


---
* Back to index: [MSXlib Development Guide](index.md)
* Previous chapter: [Getting started with MSXlib](chapter1.md)
* Next chapter: [MSXlib cookbook](chapter3.md)
