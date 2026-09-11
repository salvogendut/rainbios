<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Third-party notices

RainBIOS's combined main ROMs (`build/rainbios_msx1.rom` and
`build/rainbios_msx2.rom`) are aggregates containing separately licensed
components. The same main-ROM bytes are also embedded in
`build/rainbios_omega.rom`; its Sub-ROM and disk-ROM regions contain original
RainBIOS BSD-3-Clause code. This file does not replace the component license
texts.

| ROM region / repository path | Component | Source identity | License notice |
| --- | --- | --- | --- |
| `0000h-3FFFh`, except generated logo data and ZX0 decoder | Original RainBIOS firmware, font, and menu tables | This repository | [`LICENSE`](LICENSE) (BSD-3-Clause) |
| Generated logo pattern/name/color data below `4000h` | RainBIOS boot logo | `src/logo-simple.png` converted by `tools/png_to_screen2.py` | [`LICENSES/CC0-1.0.txt`](LICENSES/CC0-1.0.txt) |
| `src/zx0_decompress.asm`, `tools/zx0/` | ZX0 v2 compressor and standard forward Z80 decoder | ZX0 commit `ecde3a2ae05061fe06469ed46df81a33b7de7d86` | [`LICENSES/ZX0.txt`](LICENSES/ZX0.txt) (BSD-3-Clause) |
| `4000h-7FFFh`, imported interpreter modules | R. T. Russell Z80 interpreter core, altered/ported for MSX | David Given's [CP/Mish `third_party/bbcbasic` subtree](https://github.com/davidgiven/cpmish/tree/master/third_party/bbcbasic), preserved and ported in `bbcbasic-z80-msx` commit `e198bb17666d3e001a2f1468cf583beeadb37397` | [`LICENSES/BBCBASIC-Z80.txt`](LICENSES/BBCBASIC-Z80.txt) (Zlib-style notice) |
| `4000h-7FFFh`, MSX cartridge, console, graphics, storage, state, and descriptor adapters | Independently written MSX platform layer | Same pinned companion commit | [`LICENSES/BBCBASIC-MSX-BSD-3-Clause.txt`](LICENSES/BBCBASIC-MSX-BSD-3-Clause.txt) |

The companion payload is rebuilt from the pinned source checkout on every
normal RainBIOS build and copied unchanged into the combined ROM. Its current
expected SHA-256 is
`e64ba3c3e72bf562d835cebfbb274283b3f0bb4bc0997123d6a00fdd38ceaa67`.

The RainBIOS MSX port derives from the BBC BASIC source subtree published in
David Given's CP/Mish project. The original BBC BASIC for Z80 was written by
R. T. Russell and is documented on Russell's
[`BBC BASIC for Z80` page](http://www.rtrussell.co.uk/bbcbasic/z80basic.html).

The permissive source licenses do not grant RainBIOS permission to use the
`BBC BASIC` name. The upstream project's naming permission is expressly not
transferable to derived or forked works. Public releases must obtain suitable
permission or rename the port and its on-screen identity while retaining
accurate source attribution.
