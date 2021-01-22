[![C/C++ CI](https://github.com/theNestruo/pcxtools/workflows/C/C++%20CI/badge.svg)](https://github.com/theNestruo/pcxtools/actions)
[![CodeFactor](https://www.codefactor.io/repository/github/thenestruo/pcxtools/badge)](https://www.codefactor.io/repository/github/thenestruo/pcxtools)

# PCXTOOLS: PNG2MSX, PNGSPR[+] and TMX2BIN
`PNG2MSX` and `PNG2SPR[+]` are free command line tools to convert PNG images to TMS9918 (MSX-1 VDP) format (i.e. CHRTBL/CLRTBL/NAMTBL-ready values, and SPRTBL/SPATBL-ready values).

`TMX2BIN` is a free command line tool to convert Tiled maps to binary.

## Deprecation notice
~~`PCX2MSX[+]`~~ and ~~`PCX2SPR[+]`~~ have been replaced by `PNG2MSX` and `PNG2SPR[+]`, will not be further maintained, and may be removed in future versions.

## Usage
Exit code will be zero if ok and non-zero if there was an error. This allows using this programs in makefiles, command chains, etc.

### PNG2MSX, PNG2SPR, and PNG2SPR+
From command line, type:
* `PNG2MSX [options] charset.png`
* `PNG2MSX [options] charset.png [extra.png ...]`
* `PNG2MSX [options] charset.png -n [screen.png ...]`
* `PNG2SPR [options] sprites.png`
* `PNG2SPR+ [options] sprites.png`

`charset.png`, `extra.png`, `screen.png`, and `sprites.png` are the name of the input PNG file(s).

Please note that:
* Extra pixels (width or height not multiple of 8 or 16) will be ignored (this behaviour differs to the original PCX2MSX)

The output files will have the same name as the input file plus an additional extension (.chr, .clr, .nam, .spr[.asm] or .spat[.asm]). If files exist with the same name, they will be overwritten.

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
    Doesn't write output files. Useful to just validate input PNG files
* `-e` index color by euclidean distance (this is the default)
* `-g` index color by weighted distance

### PNG2MSX, and PNG2SPR[+]
* `-i` inverted
    Flips bitmap vertically.
* `-m` mirrored
    Flips bitmap horizontally.

### PNG2MSX
* `-il` ignore line on color collision
    Continue processing the file even if collisions are found. Offending lines will be have 0x00 both as pattern and color.
    Can be useful in combination with `-d` to check all the collisions at once.
* `-hl` force higher color to be foreground
* `-lh` force lower color to be foreground
* `-f<0..7>` force bit <n> to be foreground (set) on patterns
* `-b<0..7>` force bit <n> to be background (reset) on patterns
    These four options allow some control on how patterns are created, and which color is foreground and which one is background.
    Can be useful if colors are going to be set programatically (e.g.: fonts colored with FILVRM) or to improve compression results.
* `-n<00..ff>` generate NAMTBL [starting at value <n>]
    Generates NAMTBL.
    If various PNG files are provided, NAMTBL is generated from the additional files, mapped against blocks of the first PNG file.
    If optional index value is specified, name table will be generated to load the character definition after that index (e.g.: tileset loaded without overwriting ASCII font).
    Usually to be used in combination with `-rm` and/or `-rr`.
* `-bb<00..ff>` blank block at position <nn>
    A blank block (pattern = 0x00, color = 0x00) will be generated at specified position. Removed blocks will have this index in the name table.
    Usually to be used in combination with -n and/or rm (e.g.: to keep ASCII 0x20 " " as the blank block)
* ` -rr` remove repeated tiles
    Only the first copy of identical tiles will be kept.
    Usally to be used in combination with `-n`.
    If various PNG files are provided, blocks removed from the first file will be also removed from the additional files (e.g.: related tilesets: on/off, day/night...)
* `-rm<0..f>` remove solid tiles of <n> color
    Removes all the solid tiles composed entirely of pixels of the specified color (hexadecimal).
    If various PNG files are provided, blocks removed from the first file will be also removed from the additional files (e.g.: related tilesets: on/off, day/night...)

### PNG2SPR only
* `-8` generate 8x8px sprites
    Output is adjusted so it can be used in 8x8px sprites modes
* ` -h` generate half sprites (8x16px, 16b per sprite)
    Processing order is adjusted so multicolored sprites are grouped by half sprites (8px width, 16px height)
* `-hl` lower colors will have higher priority planes (default)
* `-lh` higher colors will have higher priority planes
    These two options allow some control on how the colors get ordered (namely, to avoid the flickering routines make flicker the brigther colors)

### PNG2SPR+ only
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

### TMX2BIN only
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

## Palettes
For each pixel, the color index is computed by looking for the lowest either euclidean or weigthed color distance, depending of the options.

As the MSX palette is not well defined, with several emulators using slightly different palettes, and the MSX2 palette does not exactly match the MSX palette, Four different palettes are used in a best effort to cover all the use cases and get the right color for every developer:

<table>
<tr>
    <th>Index</th>
    <th>TMS9918 palette<sup>1</sup></th>
    <th>TMS9219 palette<sup>2</sup></th>
    <th>TOSHIBA palette<sup>3</sup></th>
    <th>V9938 palette<sup>2</sup></th>
    <th>Name</th>
</tr><tr>
    <td>1</td>
    <td style="background:#000000"><cc>000000</cc></td>
    <td style="background:#000000"><cc>000000</cc></td>
    <td style="background:#000000"><cc>000000</cc></td>
    <td style="background:#000000"><cc>000000</cc></td>
    <td>Black</td>
</tr><tr>
    <td>2</td>
    <td style="background:#0AAD1E"><cc>0AAD1E</cc></td>
    <td style="background:#23CB32"><cc>23CB32</cc></td>
    <td style="background:#66CC66"><cc>66CC66</cc></td>
    <td style="background:#24DA24"><cc>24DA24</cc></td>
    <td>Medium green</td>
</tr><tr>
    <td>3</td>
    <td style="background:#34C84C"><cc>34C84C</cc></td>
    <td style="background:#60DD6C"><cc>60DD6C</cc></td>
    <td style="background:#88EE88"><cc>88EE88</cc></td>
    <td style="background:#6DFF6D"><cc>6DFF6D</cc></td>
    <td>Light green</td>
</tr><tr>
    <td>4</td>
    <td style="background:#2B2DE3"><cc>2B2DE3</cc></td>
    <td style="background:#544EFF"><cc>544EFF</cc></td>
    <td style="background:#4444DD"><cc>4444DD</cc></td>
    <td style="background:#2424FF"><cc>2424FF</cc></td>
    <td>Dark blue</td>
</tr><tr>
    <td>5</td>
    <td style="background:#514BFB"><cc>514BFB</cc></td>
    <td style="background:#7D70FF"><cc>7D70FF</cc></td>
    <td style="background:#7777FF"><cc>7777FF</cc></td>
    <td style="background:#486DFF"><cc>486DFF</cc></td>
    <td>Medium blue</td>
</tr><tr>
    <td>6</td>
    <td style="background:#BD2925"><cc>BD2925</cc></td>
    <td style="background:#D25442"><cc>D25442</cc></td>
    <td style="background:#BB5555"><cc>BB5555</cc></td>
    <td style="background:#B62424"><cc>B62424</cc></td>
    <td>Dark red</td>
</tr><tr>
    <td>7</td>
    <td style="background:#1EE2EF"><cc>1EE2EF</cc></td>
    <td style="background:#45E8FF"><cc>45E8FF</cc></td>
    <td style="background:#77DDDD"><cc>77DDDD</cc></td>
    <td style="background:#48DAFF"><cc>48DAFF</cc></td>
    <td>Cyan</td>
</tr><tr>
    <td>8</td>
    <td style="background:#FB2C2B"><cc>FB2C2B</cc></td>
    <td style="background:#FA5948"><cc>FA5948</cc></td>
    <td style="background:#DD6666"><cc>DD6666</cc></td>
    <td style="background:#FF2424"><cc>FF2424</cc></td>
    <td>Medium red</td>
</tr><tr>
    <td>9</td>
    <td style="background:#FF5F4C"><cc>FF5F4C</cc></td>
    <td style="background:#FF7C6C"><cc>FF7C6C</cc></td>
    <td style="background:#FF7777"><cc>FF7777</cc></td>
    <td style="background:#FF6D6D"><cc>FF6D6D</cc></td>
    <td>Light red</td>
</tr><tr>
    <td>10</td>
    <td style="background:#BDA22B"><cc>BDA22B</cc></td>
    <td style="background:#D3C63C"><cc>D3C63C</cc></td>
    <td style="background:#CCCC55"><cc>CCCC55</cc></td>
    <td style="background:#DADA24"><cc>DADA24</cc></td>
    <td>Dark yellow</td>
</tr><tr>
    <td>11</td>
    <td style="background:#D7B454"><cc>D7B454</cc></td>
    <td style="background:#E5D26D"><cc>E5D26D</cc></td>
    <td style="background:#CCCC88"><cc>CCCC88</cc></td>
    <td style="background:#DADA91"><cc>DADA91</cc></td>
    <td>Light yellow</td>
</tr><tr>
    <td>12</td>
    <td style="background:#0A8C18"><cc>0A8C18</cc></td>
    <td style="background:#23B22C"><cc>23B22C</cc></td>
    <td style="background:#55AA55"><cc>55AA55</cc></td>
    <td style="background:#249124"><cc>249124</cc></td>
    <td>Dark green</td>
</tr><tr>
    <td>13</td>
    <td style="background:#AF329A"><cc>AF329A</cc></td>
    <td style="background:#C85AC6"><cc>C85AC6</cc></td>
    <td style="background:#BB55BB"><cc>BB55BB</cc></td>
    <td style="background:#DA48B6"><cc>DA48B6</cc></td>
    <td>Magenta</td>
</tr><tr>
    <td>14</td>
    <td style="background:#B2B2B2"><cc>B2B2B2</cc></td>
    <td style="background:#CCCCCC"><cc>CCCCCC</cc></td>
    <td style="background:#CCCCCC"><cc>CCCCCC</cc></td>
    <td style="background:#B6B6B6"><cc>B6B6B6</cc></td>
    <td>Gray</td>
</tr><tr>
    <td>15</td>
    <td style="background:#FFFFFF"><cc>FFFFFF</cc></td>
    <td style="background:#FFFFFF"><cc>FFFFFF</cc></td>
    <td style="background:#EEEEEE"><cc>EEEEEE</cc></td>
    <td style="background:#FFFFFF"><cc>FFFFFF</cc></td>
    <td>White</td>
</tr>
</table>

<sup>1</sup> TI TMS9918 palette, according Wikipedia (https://en.wikipedia.org/wiki/Texas_Instruments_TMS9918#Colors)

<sup>2</sup> TI TMS9219 and V9938 palettes from hap's meisei emulator

<sup>3</sup> TOSHIBA palette from reidrac's MSX Pixel Tools (https://github.com/reidrac/msx-pixel-tools)

Transparent pixels are indexed from the following values:

<table>
<tr>
    <th>Index</th>
    <th>RGBA value</th>
    <th>Description</th>
    <th>Name</th>
</tr><tr>
    <td>0</td>
    <td><cc>??????00</cc></td>
    <td>Actually transparent (any color with alpha channel = 0)</td>
    <td>Transparent</td>
</tr><tr>
    <td>0</td>
    <td style="background:#FF00FF"><cc>FF00FF</cc></td>
    <td>Fuchsia (traditional color used to denote transparency)</td>
    <td>Transparent</td>
</tr><tr>
    <td>0</td>
    <td style="background:#404040"><cc>404040</cc></td>
    <td>Dark gray (was used in the old PCS2MSX reference files)</td>
    <td>Transparent</td>
</tr>
</table>

## Version history
* 07/12/2020 v3.0-alpha
    * `PNG2MSX` initial version, forked from `PCX2MSX+`
    * `PNG2SPR[+]` initial versions, forked from `PCX2SPR[+]`
* 15/06/2019 v2.3
    * More standard Z80 Syntax in .asm output of `PCX2SPR+`
* 25/03/2018 v2.2
    * -lh and -hl options in `PCX2SPR`
* 30/12/2016 v2.1
    * Fixed segmentation fault in `PCX2SPR+` when outputting ASCII assembly code
* 28/12/2016 v2.0
    * `PCX2SPR+` outputs ASCII assembly code
    * `TMX2BIN` integrated into PCXTOOLS
* 22/05/2014 v1.99c
    * `PCX2SPR+` algorithm completely rewritten
* 13/04/2013 v1.99b
    * `PCX2SPR+` suboptimal solutions fixed
* 28/03/2013 v1.99
    * `PCX2SPR+` initial version
* 21/12/2013 v1.0
    * `PCX2MSX+` forked from `PCX2MSX` with: offset to NAMTBL options, blank block option, and multiple PCX file management
* 09/10/2013 v0.99
    * Removed -ps option (now, palette detection is automatic)
    * `PCX2MSX` with NAMTBL options
* 15/06/2013 v0.9
    * First merged version of `PCX2MSX` and `PCX2SPR`

## Future plans
* [*] Improve source code.
* `PCX2MSX[+]` Improve NAMTBL options (banks, etc.).
* `PCX2MSX[+]` Output NAMTBL as assembly.
* `TMX2BIN` metatiles with different width and height.
* `TMX2BIN` Multiple layers.

## Author and last words
Coded by [theNestruo](theNestruo@gmail.com)

* Original `PCX2MSX` was coded by Edward A. Robsy Petrus [25/12/2004]. `PCX2MSX` is inspired by that original version, but is not related with it in any other way.
* [Tiled](http://www.mapeditor.org/) (c) 2008-2020 Thorbjørn Lindeijer.
* [LodePNG](https://lodev.org/lodepng/) (c) 2005-2019 by Lode Vandevenne.
* Test graphics extracted from the original freeware version of [Ninja Senki](http://ninjasenki.com/) (c) 2010 Jonathan Lavigne.
* `PNG2SPR+` demo sprites extracted from [Sydney Hunter and the Caverns of Death](http://www.studiopinagames.com/sydney.html) (c) 2011 Keith Erickson / Studio Piña

Greetings to: Robsy, Iban Nieto, Jon Cortázar
