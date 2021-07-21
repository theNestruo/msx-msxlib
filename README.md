# MSXlib

MSXlib is a set of assembly libraries to create MSX videogame cartridges.

MSXlib is BIOS-based, and it is divided in several libraries: MSX-related core, MSX-related optionals, games core, genre-specific (such as platformers), and generic game optionals. These libraries can be used incrementally, but are designed to work together.

The [MSXlib Development Guide](doc/index.md) will help you start creating MSX videogame cartridges.

## External libraries

* [ayFX Replayer v1.31](http://www.z80st.es/downloads/code/) by SapphiRe
* CoolColors &copy; Fabio R. Schmidlin, 1997
* [Pletter 0.5c1](http://xl2s.eu.pn/pletter.html) &copy; XL2S Entertainment 2008
* [PT3 Replayer](http://www.z80st.es/downloads/code/) by Dioniso, MSX-KUN (ROM version), SapphiRe (asMSX version)
* [WYZPlayer 0.47c](https://github.com/AugustoRuiz/WYZTracker)
* [ZX0](https://github.com/einar-saukas/ZX0), [ZX1](https://github.com/einar-saukas/ZX1), and ~~[ZX7](https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/compress/zx7/z80)~~ by Einar Saukas (note: ZX7 is kept for backwards compatibily; please use ZX0 or ZX1 instead)

## External tools

* [PCXTOOLS v2.2](https://github.com/theNestruo/pcxtools) coded by theNestruo
* [Pletter 0.5c1](http://xl2s.eu.pn/pletter.html) &copy; XL2S Entertainment 2008
* [tniASM v0.45](http://tniasm.tni.nl/) is written by Patriek Lesparre, &copy; 2000-2013 by The New Image
* [Tiled](http://www.mapeditor.org/) &copy; 2008-2020 Thorbjørn Lindeijer.
* [Visual Studio Code](https://code.visualstudio.com/) &copy; 2020 Microsoft
* [ZX0](https://github.com/einar-saukas/ZX0), [ZX1](https://github.com/einar-saukas/ZX1), and ~~[ZX7](https://github.com/z88dk/z88dk/tree/master/src/zx7) (also, [here](http://www.worldofspectrum.org/infoseekid.cgi?id=0027996))~~  by Einar Saukas (note: ZX7 is kept for backwards compatibily; please use ZX0 or ZX1 instead)

## References

The _readme_ files of the external tools (such as tniASM, ZX0, etc.), and some technical documentation have been copied into the `ref` folder for your convenience; you can open _The MSX Red Book_ in an editor tab next to your code.

This techincal documentation contains:

* **The MSX Red Book** in text format, in ASCII format (by MSXHans 2001) and in [MarkDown format](https://github.com/gseidler/The-MSX-Red-Book) (by [Gustavo Seidler](https://github.com/gseidler))
* The **MSX2 Technical Handbook** in [MarkDown format](https://github.com/Konamiman/MSX2-Technical-Handbook) by [Néstor Soriano](https://github.com/Konamiman)
* **Portar Specifications** in text format and in HTML format (by Mayer of WC Hakkers)
* **Texas Instruments TMS9918A VDP** (by Sean Young)

## Author and last words

Coded by [theNestruo](https://github.com/theNestruo)
