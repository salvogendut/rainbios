# Reference log

This log records implementation inputs and makes the provenance boundary
reviewable.

## 2026-07-30 — Official C-BIOS 0.29a release tree

- Location used: adjacent `cbios-0.29a` release directory
- License: permissive two-clause license in `doc/cbios.txt`
- Material consulted: license and build documentation; public main-ROM
  entry-point layout in `src/main.asm`
- Purpose: make the official release the canonical open-source cross-check for
  standardized interface addresses and build conventions
- Excluded: device and service routine implementations
- RainBIOS use: interface facts only; no implementation code or assets copied
- Reference checksums:
  - `src/main.asm`:
    `9cd33476229cc202e36ef6fa3858931b136fb5e65d086c25c1407557fbbc12f9`
  - `doc/cbios.txt`:
    `b7c5b9fde2fd3b7bab292b8995581bc4f0f0315efe65ee49d934a1afd53099d8`
  - `doc/building.txt`:
    `0bf991b209a4dbe3bb418c8beb20983a6a27b3dd7c6838f6e992352e62b3dd94`

The openMSX MSX1 machine configuration was later adapted as an integration
test fixture in `tests/openmsx`. Its license and copyright notices are retained
in `LICENSES/CBIOS.txt`; this does not affect firmware implementation
provenance.

## 2026-07-30 — C-BIOS-XRX local fork

- Upstream family: C-BIOS
- Local revision: `e542299fa73f9a4cc655347f5df2390a692217f2`
- License: permissive two-clause license reproduced in its `README.md`
- Material consulted: project README, build documentation, main-ROM public
  entry-point layout, system-variable declarations, and locale/model constants
- Purpose: confirm toolchain options, standardized interface addresses, ROM
  metadata locations, and the license of available open-source prior art
- Excluded: device and service routine implementations
- RainBIOS use: interface facts only; no implementation code or assets copied

The official `cbios-0.29a` tree above supersedes this fork as the canonical
C-BIOS reference.

## 2026-07-30 — MSX Technical Data Book

- Title: *MSX Technical Data Book — Hardware/Software Specifications*
- Publisher information: Sony Corporation; produced by ASCII Corporation;
  copyright 1984 Microsoft Corporation
- Public scan consulted:
  `https://download.file-hunter.com/Manuals/msx_technical_data_book.pdf`
- Material consulted: MSX1 hardware ports, BIOS entry-point reference, and
  section 5.5 “ID Bytes”
- Purpose: primary specification for the M0 ROM interface and metadata
- RainBIOS use: interface and behavioral facts only

Section 5.5 assigns the BASIC version to the high nibble of byte `002Ch`.
RainBIOS therefore uses `11h` for an international keyboard and international
BASIC identifier. C-BIOS 0.29a emits `02h` for that configuration; that
open-source implementation difference is not copied.

## Proprietary source trees

The adjacent `msx-system` and `msxsyssrc20260412` trees were identified by
directory and metadata filenames only. Their source and documentation are not
implementation inputs. They remain quarantined under
`docs/DEVELOPMENT_POLICY.md`.

## 2026-07-30 — 1983 emulator

- Project: adjacent open-source `1983` MSX/MSX2 emulator
- Repository revision at latest test:
  `c9828586fcadf912f2d685c9f8d1f71eba665fda`
- Tested binary self-identification: `git c982858`
- Tested binary SHA-256:
  `f12aa243a65667bef09830642e9fa17a70f20355d6da60b7e1388170d086a952`
- Purpose: independent headless execution, CPU/VDP state reporting, and final
  framebuffer capture for the RainBIOS MSX1 ROM
- RainBIOS use: validation tool only; no emulator implementation code copied

## 2026-07-30 — BBC BASIC (Z80) from CP/Mish

- Original interpreter author: R. T. Russell
- Open-source source tree:
  `https://github.com/davidgiven/cpmish/tree/d70c643a5db24007ad6533f92b701fd714a99b7f/third_party/bbcbasic`
- CP/Mish snapshot:
  `d70c643a5db24007ad6533f92b701fd714a99b7f`
- Source subtree Git object:
  `e9d0ae3c5f53fbd78379aa0d3f38d13f31c823f6`
- RainBIOS port repository:
  `https://github.com/salvogendut/bbcbasic-z80-msx`
- Initial port revision:
  `87384ff4f2f554ff71494100c3fc431b9bb71f1b`
- Reproducible CP/M baseline revision:
  `f926bd6fb40ed6ca17da1ecae27274a7fac956f0`
- Preserved-history tag: `upstream-cpmish-d70c643`
- License: permissive notice in the imported `COPYING`; new MSX port files
  use BSD-3-Clause
- Material consulted: `COPYING`, `README.dg`, the CP/M build description,
  module/link layout, and the machine-adapter jump-table interface
- Purpose: select an interpreter which can be bundled as an open-source
  RainBIOS payload and establish its MSX port boundary
- RainBIOS use: dependency metadata and architecture planning; interpreter
  implementation stays in the separate port repository

The preserved branch contains the 18 commits which touched the BBC BASIC
subtree, with authors, dates, messages, blobs, and ordering retained. Its tip
tree is byte-for-byte identical to the CP/Mish subtree named above. Neither
`zmac` nor `ld80` was preinstalled. Exact CP/Mish tool sources were
built in a disposable directory and reproduced a 15,616-byte CP/M image with
SHA-256
`8f65a0a83d2231384b5a7f79035c2b97d748d238a924a116a84214c004cbe8f6`.
The port repository now contains a standalone build driver and records the
historical licensing uncertainty around `zmac`; the tool is not vendored.

## 2026-07-30 — SE BASIC IV 4.2 Cordelia

- Project: Source Solutions SE BASIC IV
- Official site: `https://source-solutions.github.io/sebasic4/`
- Upstream repository: `https://github.com/source-solutions/sebasic4`
- Adjacent read-only checkout revision:
  `55dfdf889f3d24bd4d26e2ecc9e20d8975dd6f07`
- License: GPL-3.0-or-later in source headers; repository `LICENSE` contains
  GPL version 3
- Material consulted: `README.md`, build script, top-level BASIC/boot assembly,
  restart/startup module, memory-layout data, and direct-I/O inventory
- Purpose: determine whether SE BASIC IV can be a separately licensed
  boot-menu payload and estimate its MSX porting boundary
- RainBIOS use: architecture and planning only; no SE BASIC code or binary data
  copied or linked
- Relevant checksums:
  - `basic/basic.asm`:
    `afc49c826ec6bc47f3ea19a81f661b39fbb22b9e181b451506e75b77ece0ef1f`
  - `basic/basic.inc`:
    `6a4d9d6708f22d650410ed24149e316d737de1c5d6725b4c4ca5f5586a1f421e`
  - `boot/boot.asm`:
    `89ada73648330ce80d2aa91b06de6d823ff72769ac273c11460a13bce402dc9d`

This revision builds a 16 KiB `basic.rom`, a 7 KiB RAM segment, and a separate
16 KiB platform boot ROM. The interpreter uses absolute addresses from
`0000h` through `5BB9h` and Spectrum-family paging/video hardware. A working
MSX payload would therefore require a source-level port, not a binary wrapper.
BBC BASIC is now the selected first payload; SE BASIC remains an optional
future experiment, and the adjacent upstream checkout is to remain unmodified.
