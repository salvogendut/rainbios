# Reference log

This log records implementation inputs and makes the provenance boundary
reviewable.

## 2026-07-30 — Official C-BIOS 0.29a release tree

- Location used: adjacent `cbios-0.29a` release directory
- License: permissive two-clause license in `doc/cbios.txt`
- Material consulted: license and build documentation; public main-ROM
  entry-point layout in `src/main.asm`; later, `src/video.asm` solely as an
  open-source cross-check of published VDP input ordering and externally
  observable screen-mode behavior; later, `src/slot.asm` solely to cross-check
  the observable requirement that temporary secondary selections are mirrored
  in `SLTTBL` and restored afterward; later, the extension initialization and
  boot-call ordering in `src/main.asm` and the documented `RAMAD0`-`RAMAD3`
  interface locations in `src/disk.asm`
- Purpose: make the official release the canonical open-source cross-check for
  standardized interface addresses and build conventions
- Excluded: copying or adapting device or service implementation routines,
  including the C-BIOS disk driver
- RainBIOS use: interface and observable behavior facts only; no implementation
  code or assets copied
- Reference checksums:
  - `src/main.asm`:
    `9cd33476229cc202e36ef6fa3858931b136fb5e65d086c25c1407557fbbc12f9`
  - `doc/cbios.txt`:
    `b7c5b9fde2fd3b7bab292b8995581bc4f0f0315efe65ee49d934a1afd53099d8`
  - `doc/building.txt`:
    `0bf991b209a4dbe3bb418c8beb20983a6a27b3dd7c6838f6e992352e62b3dd94`
  - `src/video.asm`:
    `fa1b00b72dd6736a47873f7f38bbef289c8720fea4fe74b7962b79d1c808b5d4`
  - `src/slot.asm`:
    `552fefd09c228cf569ac1ccb916a355362ccc70b5c90bcd3cae1d46fee6d6144`
  - `src/disk.asm`:
    `5c2abd2accf995cb8f567d5527cb199a1a9170bc9131a47449f3d2ac757fe583`

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

## 2026-07-30 — MSX2 Technical Handbook

- Public English transcription:
  `https://konamiman.github.io/MSX2-Technical-Handbook/`
- Material consulted: Chapter 2 interrupt model; Chapter 3 slot
  initialization; Chapter 5 cartridge headers, section 3 international
  keyboard/character input, and section 7 inter-slot call interfaces;
  Appendix 1 interrupt/VDP/mode/console and `PHYDIO` call contracts; Appendix 4
  MAIN-ROM work-area and hook listings; Appendix 8 control-character
  assignments; and the published cassette motor, leader, framed-byte, and
  tape-format behavior
- Purpose: define the M1 slot-call register contract and the documented
  `F380h-FFCAh` work-area layout
- RainBIOS use: interface and behavioral facts only

The handbook identifies `BOTTOM`/`HIMEM`, `BIOSSLT`, `EXPTBL`, `SLTTBL`, and
the five-byte hook table, and documents that `FFFFh` is the expanded-slot
selection register whose read value is inverted. M1H uses those public facts
to initialize the tables and drive original RainBIOS selection/restoration
paths.

M1B uses the published `RSLREG`, `WSLREG`, and `ENASLT` inputs, outputs, and
clobber declarations. The page-switch implementation and its RAM helper are
original RainBIOS code covered by host and openMSX conformance probes.

M1C likewise uses the published `RDSLT` and `WRSLT` register contracts. Its
temporary map construction, page-0 helpers, restoration paths, and physical
RAM probe are original RainBIOS work.

M1D uses the published IX/IY `CALSLT` contract. M1E uses the documented
`41h,42h` cartridge signature, following little-endian INIT pointer, and
`RET`-or-retain-control behavior. The map-restoring call path, boot scanner,
diagnostic cartridge, RAM marker, and two-emulator probes are original
RainBIOS work.

M1H uses the handbook's expanded slot-ID encoding, inverted `FFFFh` read
behavior, and `EXPTBL`/`SLTTBL` contracts. C-BIOS `src/slot.asm` was consulted
after the original RainBIOS paths were written to confirm the externally
observable live-mirror behavior noted above; no instruction sequence was
copied. The bootstrap, selector construction, page-3 register-only
restoration, fixtures, and probes are original RainBIOS work.

M1F uses the published inline `CALLF` layout, IM 1 timer interrupt behavior,
`H.KEYI`/`H.TIMI` hook locations, and `JIFFY` counter. M2A uses the published
B=data/C=register `WRTVDP` contract; Screen 0/1/2 mode contracts; current
screen, table-base, color, line-length, and cursor work variables; and the
`CHPUT`, `CLS`, and `POSIT` interfaces. The handler, mode tables, console
implementation, font expansion, and conformance probe are original RainBIOS
work.

M3A uses the published active-low international keyboard matrix, the 40-byte
circular buffer pointers, `OLDKEY`/`NEWKEY` state, editing control characters,
and the `SNSMAT`, `CHSNS`, `CHGET`, and `KILBUF` contracts. The edge-triggered
scanner, translation tables, circular-buffer implementation, printable font
additions, and conformance probe are original RainBIOS work.

M3B uses the published PSG/PPI cassette wiring and `TAP*`/`STMOTR` contracts.
The adaptive input decoder, FSK output, CAS/WAV fixtures, BBC BASIC sequential
storage adapter, and emulator probes are original project work. No
proprietary BIOS source or ROM disassembly was consulted for this milestone.

M1G/M4A use the published normal cartridge header, primary-slot memory access,
five-byte hook, and interrupt contracts. The `RBP1` validation rules, menu
state, non-returning zero-register transfer, corrupt-descriptor fixture,
timed-input fixture, and emulator probes are original RainBIOS work.

## Proprietary source trees

The adjacent `msx-system` and `msxsyssrc20260412` trees were identified by
directory and metadata filenames only. Their source and documentation are not
implementation inputs. They remain quarantined under
`docs/DEVELOPMENT_POLICY.md`.

## 2026-07-30 — 1983 emulator

- Project: adjacent open-source `1983` MSX/MSX2 emulator
- Repository revision at latest test:
  `74c9148c68d421e4cf8c3be06b31bfe530858124`
- License: GPL-2.0 in the repository `LICENSE`
- Tested binary self-identification: `git 74c9148`
- Tested binary SHA-256:
  `458e672afa370fdf8fafd6293308d0c72001505fd9f554ec5a6e94551b5c74d1`
- Material consulted for disk validation: the documented NMS 8250 WD2793
  memory window in `TECHNICAL.md`, controller register behavior in
  `src/wd2793.c`, raw-image geometry behavior in `src/floppy.c`, and public
  register-level examples in `tests/test_wd2793.c`
- Purpose: independent headless execution, CPU/VDP state reporting, final
  framebuffer capture, and read-only NMS 8250 floppy-path validation for the
  RainBIOS MSX1 ROM
- RainBIOS use: validation tool and documented hardware-behavior cross-check;
  no emulator implementation code copied

## 2026-07-30 — Opaque cartridge smoke-test inputs

- Local-only files:
  - `Arkano.rom`, 32,768 bytes, SHA-256
    `b14d1d94a1cc23efff146e8ad62e4364047c9023bba47642a0daa67f51122bcc`
  - `diag.rom`, 32,768 bytes, SHA-256
    `496d77166f5d3195a47a7a8c70511860126bd0b45cd48f54928b51cc3114c3c8`
- Purpose: black-box confirmation that a game and a diagnostics UI can use the
  current public RainBIOS services
- Distribution: neither ROM is copied into or distributed by RainBIOS
- RainBIOS use: runtime behavior and rendered output only

The public `AB` header and INIT words were read to establish test metadata.
During that initial metadata check, one 32-byte prefix was printed for each
ROM, exposing 16 bytes beyond the header; those instruction bytes were not
analyzed or used. All subsequent work used public BIOS-entry breakpoints,
CPU/VDP state, and rendered screens. See `docs/CARTRIDGE_COMPATIBILITY.md`.

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
- Static core-audit revision:
  `f318ab09dcb30158843b2e6fba9386ed4956ca69`
- MSX link-layout revision:
  `0b5979efed97ac5e557a43daed0916acdcb5d5f1`
- MSX console P1 revision:
  `439b86aff3ba81eb4bc152852c98424f22f22004`
- RainBIOS descriptor revision:
  `b97a838020cc6ad053b8fa1cd1ec5efc00e0d975`
- MSX Graphics II revision:
  `88ebf44284db5951ad6cb433ca3ad7650d56bc92`
- MSX cassette storage revision:
  `186b2cc7fcbfa8bf21d1dfa7ce8987d4f0c4711f`
- MSX `POINT()` parsing revision:
  `6ddaa57afe51e45c0ebec88666c846b01841e05b`
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
Its subsequent static audit records a 12,492-byte core, a 768-byte aligned RAM
module, 26 required platform symbols, 21 direct symbolic writes confined to
RAM exports, and two intentional user-facing port instructions.
The link-layout revision relocates that unchanged core to `4100h-71CBh`,
places state at `8000h-82FFh`, and produces a nonfunctional 16 KiB layout ROM
with SHA-256
`b92d38754db7451e3e14acd0c1ae05efea2c50c99a2b920ee36e35bfc906be11`.
The current cartridge uses published MSX BIOS calls and work-area variables
for console, keyboard, cursor, timing, Graphics II, and sequential cassette
services. It places the unchanged core at `4400h-74C1h`, the independently
written graphics adapter at `74C2h-77AAh`, the cassette adapter at
`77ABh-794Eh`, fixed and adapter state at `8000h-8321h`, and user memory from
`8322h`. Its 16 KiB ROM has SHA-256
`29691e2ac6498988b15ef8e80687f902ae834fd886585bcc1f753a49e0434678`
and publishes RainBIOS payload descriptor v1 at `7FF0h-7FFFh`, requiring the
console, keyboard, timing, graphics, and cassette capability bits.
An openMSX smoke test exercises language, editing, error, clock, and timeout
paths with zero writes to the selected ROM window. The adjacent 1983 emulator
separately renders the banner and prompt, avoiding reliance on openMSX raw
screenshot capture.
The same pinned BBC BASIC binary now passes that complete smoke sequence under
RainBIOS with zero ROM writes. The 1983 test independently confirms the
blocking `CHGET` wait state, the page-1 cartridge mapping, Text 40 mode, and a
visible BBC BASIC banner and prompt.
The Graphics II revision replaces the imported graphics stubs with original
MSX code for `MODE 2/7`, `CLG`, `GCOL 0,c`, `MOVE`, `DRAW`, absolute `PLOT`
4/5/69, and `POINT`. Its stored example passes on public C-BIOS and RainBIOS
in openMSX with zero cartridge writes; 1983 separately confirms the rendered
multicolour frame. No proprietary BIOS source was consulted for this
milestone.
The cassette revision adds only original MSX platform code. A deterministic
CAS fixture loads and runs under RainBIOS in 1983, while openMSX records and
the host checker decodes BBC BASIC SAVE output. Slow sampled-WAV replay is
recorded as follow-up decoder work rather than claimed compatibility.

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

## 2026-08-01 — MSX Wiki disk-ROM and DPB pages

- Pages consulted:
  - `https://www.msx.org/wiki/Disk-ROM_Bios`
  - `https://www.msx.org/wiki/DPB`
- Material consulted: the `DSKCHG` and `GETDPB` entry contract and the full
  21-byte per-drive parameter block layout (`DRIVE`, `MEDIA`, `SECBIZ`,
  `DIRMSK`, `DIRSHFT`, `CLUSMSK`, `CLUSSHFT`, `FIRFAT`, `FATCNT`, `MAXENT`,
  `FIRREC`, `MAXCLUS`, `FATSIZ`, `FIRDIR`, `FATPT`)
- Purpose: fix the exact byte layout the disk ROM must publish at `HL+1..HL+18`
  and the caller/callee register expectations
- RainBIOS use: interface and behavioral facts only

## 2026-08-01 — RookieDrive FDD disk ROM and MSX-DOS 1 kernel source

- Upstream repository: `https://github.com/Konamiman/RookieDrive-FDD-ROM`
- Material consulted: `msx/bank0/kernel.asm` (downloaded 2026-08-01, 8,779
  lines), the public MSX-DOS 1 kernel implementation
- Material consulted in `kernel.asm`: the `DSKCHG` call site and its return
  handling (`B=FFh` forces FAT/data-buffer reload, `B=1` means unchanged,
  `B=0` means unknown), the `GETDPB` call site, and the 21-byte DPB ownership
  split (kernel maintains the `DRIVE` byte and the FAT pointer at `HL+19`)
- Purpose: cross-check the MSX-DOS 1 kernel's exact calling convention and
  DPB byte ownership before implementing RainBIOS `DSKCHG`/`GETDPB`
- RainBIOS use: interface and behavioral facts only; no code copied
