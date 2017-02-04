# PCXTOOLS: PCX2MSX[+], PCX2SPR[+] and TMX2BIN
`PCX2MSX[+]` and `PCX2SPR[+]` are free command line tools to convert PCX images to TMS9918 (MSX-1 VDP) format (i.e. CHRTBL/CLRTBL/NAMTBL and SPRTBL/SPATBL-ready values).

`TMX2BIN` is a free command line tool to convert Tiled maps to binary.

## Usage
Exit code will be zero if ok and non-zero if there was an error. This allows using this programs in makefiles, command chains, etc.

### PCX2MSX[+] and PCX2SPR[+]
From command line, type:
* `PCX2MSX [options] pcxFilename`
* `PCX2MSX+ [options] pcxFilename [pcxFilename...]`
* `PCX2SPR [options] pcxFilename`
* `PCX2SPR+ [options] pcxFilename`

`pcxFilename` is the name of the input PCX file. The next restrictions apply to the input file:
* Must be well formed (0x0A signature, RLE encoded).
*  Must have 8bpp color depth.

Please note that:
* Pixels with color index greater than 15 will be ignored
* Extra pixels (width or height not multiple of 8 or 16) will be ignored (this behaviour differs to the original PCX2MSX)

The output files will have the same name as `pcxFilename` plus an additional extension (.chr, .clr, .nam, .spr[.asm] or .spat[.asm]). If files exist with the same name, they will be overwritten.

### TMX2BIN
From command line, type:
* `TMX2BIN [options] tmxFilename`

`tmxFilename` is the name of the input TMX file. The next restrictions apply to the input file:
+ Must be well formed (XML identifier followed by `<map>` tag).
+ All the XML file lines must be shorter than 1024b.
+ It should have at least one layer. Extra layers, if present, will be ignored.
+ The layer must have its data encoded as "csv". Other Tiled encoding methods, such as XML or Base64, are not supported.
+ Tilesets with more than 256 tiles are not supported. Values greater than 255 will cause a warning, as each value is meant to be stored in one byte.

## Options
Order of options is non important. Unknown options will be silently ignored. If there are mutually exclusive options, is undefined which one will be taked into account.

### Common options
* `-v` verbose execution
    By default, only exceptional output (warnings and error) is written. Use `-v` to see the differents parts of the process
* `-d` dry run
    Doesn't write output files. Useful to just validate input PCX files

### PCX2MSX[+] and PCX2SPR[+] 
* `-i` inverted
    Flips bitmap vertically.
* `-m` mirrored
    Flips bitmap horizontally.

### PCX2MSX[+]
* `-il` ignore line on color collision
    Continue processing the file even if collisions are found. Offending lines will be have 0x00 both as pattern and color.
    Can be useful in combination with `-d` to check all the collisions at once.
* `-f<0..7>` force bit <n> to be foreground (set) on patterns
* `-b<0..7>` force bit <n> to be background (reset) on patterns
* `-hl` force higher color to be foreground
* `-lh` force lower color to be foreground
    This four options allow some control on how patterns are created, and which color is foreground and which one is background.
    Can be useful if colors are going to be set programatically (e.g.: fonts colored with FILVRM) or to improve compression results.

### PCX2MSX+ only
* `-n<00..ff>` generate NAMTBL [starting at value <n>]
    Generates NAMTBL.
    If various PCX files are provided, NAMTBL is generated from the additional files, mapped against blocks of the first PCX file.
    If optional index value is specified, name table will be generated to load the character definition after that index (e.g.: tileset loaded without overwriting ASCII font).
    Usually to be used in combination with `-rm` and/or `-rr`.
* `-bb<00..ff>` blank block at position <nn>
    A blank block (pattern = 0x00, color = 0x00) will be generated at specified position. Removed blocks will have this index in the name table.
    Usually to be used in combination with -n and/or rm (e.g.: to keep ASCII 0x20 " " as the blank block)
* `-rm<0..f>` remove solid tiles of <n> color
    Removes all the solid tiles composed entirely of pixels of the specified color (hexadecimal).
    If various PCX files are provided, blocks removed from the first file will be also removed from the additional files (e.g.: related tilesets: on/off, day/night...)
* ` -rr` remove repeated tiles
    Only the first copy of identical tiles will be kept.
    Usally to be used in combination with `-n`.
    If various PCX files are provided, blocks removed from the first file will be also removed from the additional files (e.g.: related tilesets: on/off, day/night...)

### PCX2SPR only
* `-8` generate 8x8px sprites
    Output is adjusted so it can be used in 8x8px sprites modes
* ` -h` generate half sprites (8x16px, 16b per sprite)
    Processing order is adjusted so multicolored sprites are grouped by half sprites (8px width, 16px height)

## PCX2SPR+ only
* `-w<16..255>` sprite width (default: 16px)
    Sprite width inside the spritesheet.
* `-h<16..255>` sprite height (default: 16px)
    Sprite height inside the spritesheet.
* `-x<0..255>` X offset (default: center)
    X offset for horizontal coordinates for SPATBL.
    Default is center of the sprite (i.e.: half width).
    Negative coordinates may appear if non-zero X offset is used.
* `-y<0..255>` Y offset (default: middle)
    Y offset for vertical coordinates for SPATBL.
    Default is center of the sprite (i.e.: half width).
    Negative coordinates may appear anytime.
* `-p<0..4> attribute padding size (default: 1b)`
    Padding size, in bytes, to be append after each sprite group.
    Default is 1 byte (enough for a marker value byte).
* `-t<00..ff>` terminator byte (default: 0xD0 (SPAT_END))
    First padding byte value.
    If default value 0xD0 (SPAT_END) is used, pattern number will be reset after each sprite group; this is recommended for large spritesheets.
* `-b` binary spat output (default: asm)
    Save SPATBL as binary file.
    Default is the more versatile ASCII assembly code file.

## TMX2BIN only
* `-t<0..255>` reorganize data as metatiles of <0..255>x<0..255> bytes
    If not provided, the output data will be the same as it is in the TMX file.
    If a metatile size is provided, the data will be scanned from left to right and from top to bottom in blocks of the specified size.
    E.g.: Given a TMX with:
    ```
    123456
    7890ab
    cdefgh
    ijklmn
    ```
    The default output will be ` 123456 7890ab cdefgh ijklmn` (spaces added for clarity).
    A metatile size of 2 will output `1278 3490 56ab cdij efkl ghmn` (6 metatiles of 2x2 bytes).
    If the width and/or height of the TMX data is not multiple of the specified size, extra data will be silently ignored.
    Thus, a metatile size of 3 will output: `123789cde 4560abfgh` (2 metatiles of 3x3 bytes, rest of data ignored).

## Version history
* 30/12/2016 v2.1
    Fixed segmentation fault in `PCX2SPR+` when outputting ASCII assembly code
* 28/12/2016 v2.0
    `PCX2SPR+` outputs ASCII assembly code
    `TMX2BIN` integrated into PCXTOOLS
* 22/05/2014 v1.99c
    `PCX2SPR+` algorithm completely rewritten
* 13/04/2013 v1.99b
    `PCX2SPR+` suboptimal solutions fixed
* 28/03/2013 v1.99
    `PCX2SPR+` initial version
* 21/12/2013 v1.0
    `PCX2MSX+` forked from `PCX2MSX` with: offset to NAMTBL options, blank block option, and multiple PCX file management
* 09/10/2013 v0.99
    Removed -ps option (now, palette detection is automatic)
    `PCX2MSX` with NAMTBL options
* 15/06/2013 v0.9
    First merged version of `PCX2MSX` and `PCX2SPR`

## Future plans
* [*] Improve source code.
* `PCX2MSX[+]` Improve NAMTBL options (banks, etc.).
* `PCX2MSX[+]` Output NAMTBL as assembly.
* `TMX2BIN` metatiles with different width and height.
* `TMX2BIN` Multiple layers.

## Author and last words
Coded by [theNestruo](theNestruo@gmail.com)

* Original `PCX2MSX` was coded by Edward A. Robsy Petrus [25/12/2004]. `PCX2MSX` is inspired by that original version, but is not related with it in any other way.
* [Tiled](http://www.mapeditor.org/) (c) 2008-2016 Thorbjørn Lindeijer.
* Test graphics extracted from the original freeware version of [Ninja Senki](http://ninjasenki.com/) (c) 2010 Jonathan Lavigne.
* `PCX2SPR+` demo sprites extracted from [Sydney Hunter and the Caverns of Death](http://www.studiopinagames.com/sydney.html) (c) 2011 Keith Erickson / Studio Piña

Greetings to: Robsy, Iban Nieto, Jon Cortázar
