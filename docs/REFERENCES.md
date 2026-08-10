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
  interface locations in `src/disk.asm`; later, the openMSX MSX2 machine
  layout in `configs/openMSX/C-BIOS_MSX2.xml` and the built `cbios_sub.rom`
  solely as open-source integration-fixture inputs; later, the `002Dh` MSX
  version byte value (`MODEL_MSX2 = 1`), the `EXBRSA` (`FAF8h`) system
  variable, and the `SUBROM`/`EXTROM`/`CHKSLZ` calling behavior at `015Ch`,
  `015Fh`, and `0162h` for the M5A/M5B MSX2 main-ROM builds; later, the
  SUB-ROM fixed-entry layout, `CHGMOD` register programming, the V9938 palette
  latch protocol, and the 16-bit VRAM access in `src/sub.asm`/`src/video.asm`
  for the M5C RainBIOS SUB-ROM; later, the `BLTVV`/`BLTVM`/`BLTMV` command
  register programming, the LMMC/LMCM CPU-transfer handshake, and the
  `REDCLK`/`WRTCLK` RTC port protocol in `src/sub.asm` for the M5D RainBIOS
  SUB-ROM slice
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
  - `configs/openMSX/C-BIOS_MSX2.xml`:
    `9cca145d7758860ff2334a26670ef88e03de03a39375fc98f7316f16c5c354c7`
  - `roms/cbios_sub.rom`:
    `95db258195d1dea673b3826a8ef3d4b747f87f93587ae66e137acd2e39c3c0f1`

The openMSX MSX1 and MSX2 machine configurations were later adapted as
integration-test fixtures in `tests/openmsx`. The MSX2 fixture executes the
official open-source C-BIOS SUB-ROM while RainBIOS supplies the MAIN-ROM under
test. The C-BIOS license and copyright notices are retained in
`LICENSES/CBIOS.txt`; this does not affect RainBIOS firmware implementation
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
  keyboard/character input, sections 5.1-5.4 universal controller I/O, and
  section 7 inter-slot call interfaces;
  Appendix 1 interrupt/VDP/mode/console and `PHYDIO` call contracts, including
  the MSX2 `CHGMOD` and R8-R23 `WRTVDP` interfaces; Appendix 4 MAIN-ROM
  work-area and hook listings; Appendix 8 control-character assignments; and
  the published cassette motor, leader, framed-byte, and tape-format behavior
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

M3C uses the published `GICINI`, `GTSTCK`, `GTTRIG`, `GTPAD`, PSG R7/R14/R15,
connector-pin, and `PADX`/`PADY` contracts. The direction tables, R15-preserving
port selection, mouse transaction, and conformance probe are original RainBIOS
work. No proprietary BIOS source, ROM data, or ROM disassembly was consulted.

M1G/M4A use the published normal cartridge header, primary-slot memory access,
five-byte hook, and interrupt contracts. The `RBP1` validation rules, menu
state, non-returning zero-register transfer, corrupt-descriptor fixture,
timed-input fixture, and emulator probes are original RainBIOS work.

## Proprietary source trees

The adjacent `msx-system` and `msxsyssrc20260412` trees were identified by
directory and metadata filenames only. Their source and documentation are not
implementation inputs. They remain quarantined under
`docs/DEVELOPMENT_POLICY.md`.

## 2026-08-10 — Opaque MSX-DOS 1 compatibility inputs

- Local-only files:
  - `MSXDOS.SYS`, 2,432 bytes, SHA-256
    `f65e3ac22f0c8eb842e1863fa885aeb8cef4e0ace02efff92e2bb311db2de469`;
  - `COMMAND.COM`, 6,656 bytes, SHA-256
    `6d192368235c039579322c623698febc8a77654c39c02f91d632abc5766e3a1d`;
  - NMS 8250 Disk ROM, 16,384 bytes, SHA-256
    `26cf5bbdde918cafb4605267dc415528424ed5b5dcd028076bf72157ed5c37cb`.
- Public interfaces observed: boot-sector transfer registers, fixed Disk-ROM
  entry points, documented DOS communication-area bytes and DPB, CPU register
  state at system/command entry, BDOS function numbers, and rendered output.
- Purpose: black-box comparison of the RainBIOS floppy boot path through the
  stock DOS banner and `A>` prompt on both RainBIOS system ROM generations.
- Distribution: no DOS or vendor ROM bytes are copied into or distributed by
  RainBIOS; the committed equivalent is an independently written fixture.
- RainBIOS use: observable behavior only. No vendor implementation was
  disassembled, copied, or used as a source-code input.

## 2026-07-30 — 1983 emulator

- Project: adjacent open-source `1983` MSX/MSX2 emulator
- Repository revision consulted:
  `fc85ab4e3dc23975e22b24c5e69244bd570c6aa5`
- License: GPL-2.0 in the repository `LICENSE`
- Tested binary self-identification: `git bf78cb4` (the local checkout)
- Tested binary SHA-256:
  `e776421f670a9eb0f1d4...` (a pinned `git 58e3590` build,
  `9baf58c8dff082a2d4bb...`, reproduces the same observable behavior, which
  confirmed the remaining test failures are stale expectations rather than
  emulator drift)
- Material consulted for disk validation: the documented NMS 8250 WD2793
  memory window in `TECHNICAL.md`, controller register behavior in
  `src/wd2793.c`, raw-image geometry behavior in `src/floppy.c`, and public
  register-level examples in `tests/test_wd2793.c`
- Material consulted for IDE validation: Sunrise cartridge address decoding
  and 16-bit data-latch behavior in `src/sunrise.c`, plus ATA task-file,
  `READ SECTORS`, DRQ, and transfer behavior in `src/ata.c`
- Material consulted for SD Mapper validation: page/subslot banking and SPI
  window behavior in `src/sd_mapper.c`, raw-card command/addressing behavior in
  `src/sdcard.c`, and public register-level examples in
  `tests/test_sd_mapper.c` and `tests/test_sdcard.c`
- Purpose: independent headless execution, CPU/VDP state reporting, final
  framebuffer capture, NMS 8250 floppy-path validation (read, write,
  format), and
  black-box Sunrise IDE / SD Mapper bootstrap validation for the RainBIOS MSX1
  ROM
- RainBIOS use: validation tool and documented hardware-behavior cross-check;
  no emulator implementation code copied

## 2026-08-01 — Nextor source compatibility cross-check

- Upstream repository: `https://github.com/Konamiman/Nextor.git`
- Revision: tag `v2.1.4`, commit
  `cd0a69c47bd6e39c194d1bb76877375eb9b346d7`
- Files consulted: `source/kernel/bank0/init.mac`,
  `source/kernel/bank0/dosboot.mac`, `source/kernel/bank0/B0.SYM.old`, and
  `source/kernel/drivers/SunriseIDE/sunride.asm`
- Purpose: confirm the public cartridge `INIT`/`H.RUNC` sequence, `F380h`
  allocation boundary, temporary-stack expectation, the expanded `CALSLT`
  fields patched after mapper allocation, the initialized boot-drive work byte,
  and Nextor's direct call to the original-BIOS keyboard decoder at `0D89h`
- RainBIOS use: behavioral cross-check only; no source or binary code copied

## 2026-08-01 — Opaque Sunrise IDE test input

- Local-only file: `Nextor-2.1.1.SunriseIDE.ROM`, 131,072 bytes, SHA-256
  `205af7f7893aa0328be23f66b3afe3132c7dee59cf4bbc493408475a201c7ad6`
- Public metadata used: `AB` extension header and INIT pointer `40F6h`
- Purpose: black-box cartridge presence and slot-routing input for the 1983
  Sunrise IDE model and Nextor cold-boot validation
- Distribution: the ROM is not copied into or distributed by RainBIOS
- RainBIOS use: header metadata and runtime behavior only; `INIT` and `H.RUNC`
  are executed as public cartridge interfaces and no implementation code was
  copied

## 2026-08-01 — Opaque SD Mapper V2 test input

- Local-only file: `SDM V2 Nextor2.1.1.rom`, 131,072 bytes, SHA-256
  `4c5e5a0015d8e4d0b2c837621b2f34a5fd594ee2c449b3af95e40ab6555f8c0d`
- Public metadata used: `AB` extension header and INIT pointer `40F6h`
- Purpose: black-box cartridge presence and slot-routing input for the 1983 SD
  Mapper V2 model
- Distribution: the ROM is not copied into or distributed by RainBIOS
- RainBIOS use: header metadata and runtime behavior only; `INIT` is executed
  as a public cartridge interface and no implementation code was copied

## 2026-08-01 — Opaque Nextor system test inputs

- Local-only files:
  - `NEXTOR.SYS`, SHA-256
    `e9d6bfcc1973630373a076a20bbd717378bbe0539c81d5639f4406dd290d60f6`
  - `COMMAND2.COM`, SHA-256
    `1bb7860631cd6257fefdbd996640bd345d7eab931758e7dc2725cdb02072067c`
- Purpose: build a local FAT16 image and validate the public cartridge
  `INIT`/`H.RUNC` path through the Nextor 2.12 banner and drive-A/drive-B prompts
- Distribution: neither file nor the generated image is copied into or
  distributed by RainBIOS
- RainBIOS use: black-box runtime behavior and rendered output only

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

## 2026-08-02 — MSX Assembly Page system-variable reference

- Page consulted: `https://map.grauw.nl/resources/msxsystemvars.php`
- Material consulted: the standardized V9938 register-shadow block at
  `FFE7h-FFF6h`, specifically `RG9SAV` at `FFE8h`
- Purpose: identify the apparent GeoBench boot-state delta correctly and avoid
  treating `FFE8h` as disk-kernel storage
- RainBIOS use: interface facts only

## 2026-08-02 — Memory-mapper sizing behavior

- Primary specification: the standard MSX memory-mapper interface where the
  four reserved ports `FCh`-`FFh` select a 16 KiB segment per page and the
  segment register masks the written value with `segments-1`
- Cross-check: the 1983 emulator's `mapper_segment_mask` in `src/msx.c`
  (revision `bf78cb4`, local build) confirms the power-of-two segment masking
  used by the boot-time sizing probe
- Purpose: define the page-2 marker probe that detects the mapper's segment
  count and publishes it in `MAPPER_SEGMENTS`
- RainBIOS use: externally observable hardware behavior only; the sizing
  routine and work-area byte are original RainBIOS work

## 2026-08-02 — openMSX memory-mapper fixture

- Material consulted: the openMSX `MemoryMapper` device configuration in the
  existing `tests/openmsx/RainBIOS_GeoBench.xml.in` (`<size>512</size>`)
- Purpose: build the `RainBIOS_M1_MAPPER.xml.in` fixture with a 128 KiB mapper
  for the sizing probe
- RainBIOS use: validation fixture only; no firmware code derived

## 2026-08-02 — Keyboard break, auto-repeat, and function-key contracts

- Primary specifications: MSX2 Technical Handbook Appendix 1 (`BREAKX`,
  `INIFNK`, `FNKSB`, `ERAFNK`, `DSPFNK`, `TOTEXT`) and Appendix 4 work-area
  list (`INTFLG` at `FC9Bh`, `FNKSTR` at `F87Fh`, `FNKFLG` at `FBCEh`,
  `CNSDFG`, `CLIKSW`, `SCNCNT`, `REPCNT`, `OLDKEY`, `NEWKEY`)
- Cross-checks: the MSX Assembly Page system-variables and BIOS references,
  and the open-source `msxsyssrc` `basekey` source for the `INTFLG` values
  (03h = Ctrl-STOP, 04h = STOP) and the `CNSDFG`/`FNKFLG` wording
- Purpose: define M3D's stop/break latch, auto-repeat counters, and function-key
  display/string behavior
- RainBIOS use: interface and externally observable behavior facts only; the
  scan, latch, repeat, and display routines are original RainBIOS work

## 2026-08-02 — openMSX keyboard matrix injection

- Material consulted: openMSX's built-in `keymatrixdown`/`keymatrixup`
  commands used by the existing keyboard probe
- Purpose: hold physical matrix rows to exercise STOP/CTRL, auto-repeat holds,
  and function-key display
- RainBIOS use: validation harness only

## 2026-08-05 — CHGCAP and CHGSND public BIOS-call contracts

- Primary specification: the public MSX BIOS calls reference (map.tni.nl),
  `CHGCAP` "Turn Caps-Lock light on/off" (`A=00` = lamp on, non-zero = lamp
  off) and `CHGSND` "Change status of 1 bit sound port"
- Cross-checks: the MSX2 Technical Handbook Appendix 4 work-area list (`CLIKSW`
  at `F3DBh`, `CAPST` at `FCABh`) already cited above, and the keyboard PPI
  port-C bit layout (bit 6 = lamp, bit 7 = click) from the MSX Technical Data
  Book
- Purpose: define the M3 basic-device `CHGCAP`/`CHGSND` externally observable
  behavior and register-preservation contract
- RainBIOS use: interface and externally observable behavior facts only; the
  implementations in `src/main_msx1.asm` are original RainBIOS work

## 2026-08-02 — Line-input and BEEP contracts

- Primary specification: MSX2 Technical Handbook Appendix 1 (`PINLIN`,
  `INLIN`, `QINLIN`, `BEEP`) and the `BUFFER`/`AUTFLG` work-area addresses
- Cross-check: the MSX Assembly Page BIOS reference for the same entries
- Purpose: define M3E's prompt/line-input buffer contract (`HL = BUFFER-1`,
  count in B, carry on a break) and the short beep
- RainBIOS use: interface and observable behavior facts only; the line-input
  and beep routines are original RainBIOS work

## 2026-08-03 — Mid-line editing and GICINI PLAY work area

- Primary specification: MSX2 Technical Handbook Appendix 1 (`GICINI`,
  `PINLIN`, `INLIN`) and Appendix 4 MAIN-ROM work-area listing; Chapter 5
  section 1 for the GICINI PSG register values and the "work area in which
  PLAY statement of BASIC is executed" wording; Appendix 4 `QUEUES`,
  `FRCNEW`, `PRSCNT`-`PLYCNT`, `VCBA`/`VCBB`/`VCBC`, `QUETAB`/`QUEBAK`, and
  `VOICAQ`/`VOICBQ`/`VOICCQ` addresses (MSX1 layout, so marked in the text)
- Cross-check: MSX Assembly Page BIOS reference for `GICINI`; MAP system-vars
  listing for the queue-table format; the Appendix 4 errata that `MUSICF` is
  `FB3Fh` and `PLYCNT` is `FB40h`
- Purpose: define M3H's cursor editing (left/right/Home/insert/Backspace/
  Delete with line redraw) and the `GICINI` PLAY statement work-area
  initialization (QUEUES -> QUETAB, FRCNEW = 255, cleared voice static data
  and voice queues)
- RainBIOS use: interface and observable behavior facts only; the editing
  and work-area initialization routines are original RainBIOS work

## 2026-08-03 — Text cursor movement

- Primary specification: MSX2 Technical Handbook Appendix 1 (`RIGHTC`,
  `LEFTC`, `UPC`, `TUPC`, `DOWNC`, `TDOWNC`), which describe the plain and
  scrolling cursor moves and the edge behavior at the start/end of the line
  and the top/bottom of the text screen
- Cross-check: the MSX Assembly Page BIOS reference for the same entries
- Purpose: define M2D's cursor work-variable updates (`CSRX`/`CSRY`, with
  `LINLEN` and `CRTCNT` as the bounds) and the one-row scroll of `TUPC`/
  `TDOWNC` at the boundary rows
- RainBIOS use: interface and observable behavior facts only; the cursor
  updates and the Screen 0/1/2 scroll-down helper are original RainBIOS work

## 2026-08-03 — VRAM transfer calls

- Primary specification: MSX2 Technical Handbook Appendix 1 (`RDVRM`,
  `WRTVRM`, `SETRD`, `SETWRT`, `FILVRM`, `LDIRMV`, `LDIRVM`) register
  contracts and the 14-bit TMS9918 VRAM address model
- Cross-check: the MSX Assembly Page BIOS reference for the same entries
- Purpose: define M2E's data-port behavior (read vs write pointer through the
  control port, address masking to 14 bits, block counts) and the boundary
  cases the VRAM probe asserts
- RainBIOS use: interface and observable behavior facts only; the transfer
  routines and the conformance probe are original RainBIOS work

## 2026-08-03 — Screen-mode switch calls

- Primary specification: MSX2 Technical Handbook Appendix 1 (`SETTXT`,
  `SETT32`, `SETGRP`), which describe switching the VDP to each screen mode
  using the mode work-area table addresses without re-initializing them
- Cross-check: the MSX Assembly Page BIOS reference for the same entries;
  the RainBIOS `INITXT`/`INIT32`/`INITGRP` register states as the reference
  for each mode's VDP programming
- Purpose: define M2F's mode-switch behavior (same registers as the
  initialize calls, `SCRMOD`/`LINLEN`/cursor updates, tables untouched)
- RainBIOS use: interface and observable behavior facts only; the switch
  routines and the screen-mode probe are original RainBIOS work

## 2026-08-03 — Sprite utility calls

- Primary specification: MSX2 Technical Handbook Appendix 1 (`CLRSPR`,
  `CALPAT`, `CALATR`, `GSPSIZ`), which define the sprite initialization
  (Y = 209/217, plane number, foreground colour, null pattern) and the
  pattern/attribute address contracts; Appendix 4 for `PATBAS`/`ATRBAS`
- Cross-check: the MSX Assembly Page BIOS reference for the same entries and
  the open-source C-BIOS 0.29a `src/video.asm` implementation: `GSPSIZ` is a
  non-mutating R1 query, `CALPAT` scales by 8/32, and 16x16 `CLRSPR` attributes
  advance pattern numbers by four while clearing the complete pattern table
- Purpose: correct M2G's `CLRSPR` table writes, `CALPAT` address scaling,
  `CALATR` (A*4), `GSPSIZ` query semantics, and preservation of R1 sprite bits
  across screen-mode initialization/switching
- RainBIOS use: public interface and observable behavior only; the RainBIOS
  implementation and expanded conformance probe remain original project work

## 2026-08-03 — GRPPRT graphics character print

- Primary specification: MSX2 Technical Handbook Appendix 1 (`GRPPRT`,
  008Dh), which defines printing a character on the graphic screen with the
  character code in A and no documented register changes
- Cross-check: the MSX Assembly Page BIOS reference for the same entry
- Purpose: define M2H's Screen 2 character print (project font, FORCLR colour
  cell, one 8-pixel cell cursor advance, CR/LF cursor movement)
- RainBIOS use: interface and observable behavior facts only; the print
  routine and the conformance probe are original RainBIOS work

## 2026-08-03 — CHPUT text control characters

- Primary specification: MSX2 Technical Handbook Appendix 1 (`CHPUT`) and
  Appendix 8, which assign the 09h tab, 0Bh cursor-up, and 0Ch form-feed
  control characters alongside the already-handled backspace, CR, and LF
- Cross-check: the MSX Assembly Page BIOS reference for `CHPUT`
- Purpose: define M2I's tab advance (next 8-column stop, wrap past the line
  end), cursor-up edge behavior, and form-feed clear-and-home
- RainBIOS use: interface and observable behavior facts only; the control
  handlers and the conformance probe are original RainBIOS work

## 2026-08-03 — MSX international character set

- Primary specification: Wikipedia "MSX character set" international variant
  table, giving the character for each byte code 0x80-0xA3
- Cross-check: the MSX2 Technical Handbook Appendix 4 work-area listing and
  the RainBIOS dead-key table, which emit the same lowercase accented codes
- Purpose: define M2J's font glyphs for all 36 international characters,
  including the 21 lowercase forms the dead-key path produces
- RainBIOS use: the glyph shapes are original project BSD-3-Clause work (per
  the `GLYPHS_5X7` header); the character-code assignments follow the
  published MSX international set

## 2026-08-03 — TMS9918 VDP-state initialization

- Primary specification: MSX2 Technical Handbook Appendix 1 (`DISSCR`,
  `ENASCR`, `WRTVDP`, `INITXT`, `INIT32`, `INITGRP`) and the TMS9918 R0-R7
  register layout (display-enable bit 6, mode bits, table bases)
- Cross-check: the MSX Assembly Page BIOS reference for the same entries
- Purpose: define M2K's boot VDP state, shadow/live register agreement, and
  the per-mode table bases and mode bytes the VDP-state probe asserts
- RainBIOS use: interface and observable behavior facts only; the register
  programming and the conformance probe are original RainBIOS work

## 2026-08-03 — CHGCLR color behavior

- Primary specification: MSX2 Technical Handbook Appendix 1 (`CHGCLR`,
  0062h) and the original MSX BIOS disassembly (per-mode R7: `(FORCLR<<4)|
  BAKCLR` in Screen 0, bare `BDRCLR` in Screens 1-3, and the Screen 1
  color-table fill with `(FORCLR<<4)|BAKCLR`); the TMS9918A R7 (TC in bits
  7-4, backdrop in bits 3-0) and Screen 1 color-table (foreground in the
  high nibble) layouts
- Cross-check: the MSX Assembly Page BIOS reference for `CHGCLR`; Appendix 4
  for `FORCLR`/`BAKCLR`/`BDRCLR`
- Purpose: define M2L's per-mode `CHGCLR` behavior and shadow update
- RainBIOS use: interface and observable behavior facts only; the `CHGCLR`
  routine and the color probe are original RainBIOS work

## 2026-08-03 — RDVDP and Screen 3 multicolor

- Primary specification: MSX2 Technical Handbook Appendix 1 (`RDVDP`,
  `INIMLT`, `SETMLT`) and Appendix 4 for `STATFL`, the MLT work-area bases,
  and the `SCRMOD`/`LINLEN` mode bytes
- Cross-check: the MSX Assembly Page BIOS reference for the same entries
- Purpose: define M2M's status-register mirror, the Screen 3 register and
  table-base programming, and the hidden-sprite/name-seed state
- RainBIOS use: interface and observable behavior facts only; the routines
  and the Screen 3 probe are original RainBIOS work

## 2026-08-03 — Emulator test-suite cleanup

- Scope: a batch of pre-existing openMSX/1983 test failures whose earlier
  attribution to 1983 binary drift was disproven by building the pinned
  `58e3590` revision and observing identical behavior
- Findings: the cartridge/tape runs on the extension stack (`F092h`) rather
  than the main stack (`F380h`); the payload work-area variables moved from
  `F393h`/`F394h` to `F301h`/`F302h`; `chget` and the BBC BASIC banner
  rendering relocated; the SD storage-boot page-2 slots and the external
  Arkano R1 settled differently as the firmware evolved
- Purpose: document that the fixes recalibrated stale test expectations to
  the current firmware rather than masking emulator drift, and that the
  remaining failures (`geobench-sunrise`, base `nextor` and
  `sd-empty-sunrise` screenshot hashes, `ide-boot`/`ide-menu` Sunrise IDE
  divergences) are separately tracked
- RainBIOS use: test-harness facts only; no firmware behavior was changed by
  the cleanup

## 2026-08-03 — Interrupt-driven controller snapshot and cassette motor

- Primary specifications: the MSX2 Technical Handbook Chapter 5 controller
  I/O (`GTSTCK`/`GTTRIG` selector and direction contracts) and the `STMOTR`
  cassette-motor contract
- Cross-check: the MSX Assembly Page BIOS reference for the same entries
- Purpose: define M1K's per-frame joystick matrix snapshot (captured in the
  IM 1 handler with PSG R15 preserved, read by `GTSTCK`/`GTTRIG`) and the
  ~2s cassette-motor auto-stop timer
- RainBIOS use: the public interface and hardware facts follow the published
  contracts; the snapshot capture and the auto-stop timer are original
  RainBIOS behavior (the standard BIOS does not snapshot controllers or
  auto-stop the cassette motor)

## 2026-08-03 — Floppy motor-off timer in the IM 1 handler

- Primary specification: the NMS 8250 WD2793 memory window
  (`FDC_DRIVE` at `7FFDh`, motor-on via the drive register bit) and the
  `disk_motor_off` write already used by the shared disk driver
- Cross-check: the RainBIOS disk driver (`src/disk_nms8250_driver.asm`),
  which turns the motor off by writing zero to the FDC drive register
- Purpose: define M1L's `DISK_MOTOR_TIMER`/`DISK_PRESENT` work bytes and the
  IM 1 handler's motor-off write at timer expiry, plus the `disk_motor_arm`
  helper for the disk ROM
- RainBIOS use: the FDC register facts follow the hardware window; the
  timer service and arm helper are original RainBIOS behavior

## 2026-08-02 — Dead-key and accented-character contracts

- Primary specifications: the MSX2 Technical Handbook Ch. 5 §3.2 `DEADST`
  work-area (`FCACh`: 1 = grave, 2 = acute, 3 = circumflex, 4 = umlaut) and
  the MSX1 Technical Handbook §5.2.5 dead-key functions (combining set
  a/e/i/o/u/y/space, fallback to the plain character)
- Cross-check: the MSX international character set (Wikipedia MSX character
  set, citing the Unicode MSX.TXT mapping) for the accented byte codes
- Purpose: define M3F's accent latch and combination table
- RainBIOS use: interface and externally observable behavior facts only; the
  latch, combination table, and scan integration are original RainBIOS work

## 2026-08-06 — International dead-key key and literal accent glyphs

- Primary specification: the open `msxsyssrc` international keyboard handler
  (`basekey/keyint.mac`) and its German/French/UK counterparts: the four
  accent glyphs `` ` ``/`'`/`^`/`"` come from the normal/shift scan tables and
  are literal characters, while a dedicated dead-key key (matrix row 2,
  column 5, value `0FFh` in every modifier table) latches `DEADST` as
  1 = grave, 2 = acute (Shift), 3 = circumflex (Code), 4 = umlaut (Shift+Code)
  and combines with the next a/e/i/o/u/y (valid-letter table `aeiouy`)
- Cross-checks: the MSX2 Technical Handbook Ch. 5 §3.2 `DEADST` wording already
  cited above, and C-BIOS `scancodes_uk.asm`/`main.asm` (UK shift table yields
  `022h` for Shift+the `'` key; the graph/code tables are unused)
- Purpose: correct M3F so the literal `'`, `` ` ``, `^`, `"` reach the key
  buffer on the first press (fixing `"` string literals in BBC BASIC) while
  accents stay available through the dedicated dead-key key
- RainBIOS use: interface and externally observable behavior facts only; the
  latch, combination table, and scan integration are original RainBIOS work

## 2026-08-02 — Key click and paddle contracts

- Primary specifications: MSX2 Technical Handbook Ch. 5 §3.2 `CLIKSW`
  (`F3DBh`, 0 = off, else on; click output on PPI port-C bit 7 through the
  speaker MIX) and §5.3 paddle use (`GTPDL`, paddle 1-12 returning 0-255; the
  paddle is a one-shot multivibrator whose pulse width is measured after
  firing the pin-8 trigger)
- Purpose: define M3G's click line drive and the no-paddle GTPDL neutral result
- RainBIOS use: interface and observable behavior facts only; the click
  counter and paddle measurement are original RainBIOS work

## 2026-08-02 — GeoBench MSX2 source compatibility cross-check

- Adjacent open-source repository revision:
  `f83b43feda2730d7c33fca9135f603c113ccc5db`
- License: BSD-3-Clause in `LICENSE`
- Files consulted: `kernel/msx_stub.asm`, `kernel/boot_msx.asm`,
  `kernel/assets.asm`, `lib/msx/screen7.asm`, `lib/msx/screen7_lut.inc`,
  `lib/msx/bank.asm`, `lib/msx/fs.asm`, `lib/msx/bios.inc`,
  `kernel/msx_launcher.asm`, `docs/MSX2.md`, and the generated MSX symbol maps
- Purpose: establish that the observed `81F0h` wait is GeoBench's resident
  V9938 frame-pacing routine after program startup, and that its loader invokes
  the public `CHGMOD 7` entry before applying its own R9 and sprite settings
- RainBIOS use: calling-contract and externally visible behavior cross-check;
  no GeoBench implementation code copied
- Relevant checksums:
  - `kernel/msx_stub.asm`:
    `1670eb36086be0b0fcdba355121e965898e61810bf139452d13ca57120ac17d7`
  - `kernel/boot_msx.asm`:
    `eb83571d8136bfc1351f23bbabd16a9fbff81813c9a6a1573db2048bb55d3bf1`
  - `lib/msx/screen7.asm`:
    `bea32afe352a2410083429b14db73ab03dbc38def5181674aeba00559474b83`
  - `kernel/assets.asm`:
    `96bcb9db012ad4850049aee1f664e26fca338acd42d9add124822d979029e62b`
  - `lib/msx/screen7_lut.inc`:
    `6c98f04164fa839f2946a667efadcedb11a20405eb74d30a52586724bc7f624d`
  - `lib/msx/bank.asm`:
    `19463241d47ce94c4001e236b1787710120a9333e84e045dc683a8c7eb1141f5`
  - `lib/msx/fs.asm`:
    `0359c1fbfa0aeb3551dd89737bbd2dcd11dfe1c1a66fc9f39a8fab679253bfcd`
  - `docs/MSX2.md`:
    `969562a84011d708982a308bb3a925c840978ac3820ae3d28529dd1ca92cd66d`

The local `QA/GBMSX.IMG` integration input is 33,554,432 bytes with SHA-256
`47d19058e4096a3f1de497e223d749bf0195cf3c10019c1be8b52a0b77630e8f`.
It is not a RainBIOS release artifact. The adjacent GeoBench worktree already
contained unrelated generated-file modifications and was kept read-only.

## 2026-08-02 — openMSX 21.0 GeoBench validation environment

- Installed distribution: Flatpak `org.openmsx.openMSX`, version 21.0
- Material consulted: the command manual's `screenshot`, emulated-time, and
  real-time callback interfaces; the stock `SunriseIDE_Nextor.xml` extension;
  and the bundled `_vdp_access_test.tcl` diagnostic helper
- Purpose: build a standard Sunrise IDE test environment, capture a rendered
  Screen 7 state only after the host renderer catches up, and distinguish
  GeoBench application startup from timing-sensitive VDP output
- RainBIOS use: validation configuration and observable emulator diagnostics
  only; no emulator implementation code copied
- Relevant checksums:
  - `SunriseIDE_Nextor.xml`:
    `9573e19557d1467db6fd5bb9cb996e7f21261057194fe7d37827d75ecd667a39`
  - `commands.html`:
    `6a5e5cf2eb3069da1448db973a1b4b6a5ae4f91c784b7e63ffaf555f4c8176b8`
  - `_vdp_access_test.tcl`:
    `8ff656ab0afbaf79bf6499c54b008a4506d4ea4a03bcea4cb1fe44cf7649c0f6`

The timing helper reports several sub-29-cycle VDP I/O sites in the current
GeoBench binary, including its status polling, Screen 7 transfer, text, and
sprite paths. Enabling the helper changes the rendered result, so the committed
openMSX acceptance target leaves it disabled and records only the unmodified
boot state. This diagnosis is not used to derive RainBIOS firmware code.

## 2026-08-02 — NMS 8250 `CHGMOD 7` black-box observation

- Environment: the attributed 1983 emulator's Philips NMS 8250 PAL profile,
  locally supplied authorized system firmware, SD Mapper V2, and the local
  GeoBench image
- Invocation: GeoBench calls the public main-BIOS `CHGMOD` entry with `A=7`
- Observable result: V9938 R0-R6 become
  `0Ah,20h,1Fh,80h,01h,F7h,1Eh`; R8-R23 become
  `08h,82h,00h,01h,00h,00h,00h,00h,0Fh,00h,00h,00h,00h,3Bh,05h,00h`,
  with R7 derived from the active colors and R1 display-enable restored later
- Purpose: define the minimum guarded Screen 7 handoff needed by the current
  compatibility target
- RainBIOS use: public hardware-register behavior only; no firmware bytes,
  internal control flow, disassembly, or decompilation were inspected

## 2026-08-02 — MSX controller and mouse interfaces
- Primary specifications:
  - *MSX Technical Data Book — Hardware/Software Specifications*, hardware
    pp. 25-28 and BIOS pp. 124-125, public scan already identified above
  - MSX2 Technical Handbook Chapter 5, sections 5.1-5.4:
    `https://konamiman.github.io/MSX2-Technical-Handbook/md/Chapter5a.html`
- Supplementary public interface references:
  - `https://map.grauw.nl/resources/msxbios.php#GTSTCK`
  - `https://map.grauw.nl/resources/msx_io_ports.php#psgioports`
  - `https://map.grauw.nl/resources/sound/generalinstrument_ay-3-8910.pdf`
- Material consulted: `GTSTCK` direction values and selectors; `GTTRIG`
  selectors and `00h`/`FFh` results; mouse `GTPAD` request/cache selectors;
  PSG GPIO direction bits; active-low connector inputs; and R15 connector,
  button-direction, pin-8, and Kana LED bits
- Purpose: define M3C's public controller behavior and hardware interface
- RainBIOS use: interface and hardware facts only

## 2026-08-02 — Open-source mouse protocol cross-checks

- openMSX 21.0 source distribution, GPL-2.0, files consulted:
  `src/input/Mouse.cc`, `src/input/JoystickDevice.hh`, `src/input/MSXJoystick.cc`,
  and `src/sound/MSXPSG.cc`
- MSXgl source revision:
  `946ce2b4448fb5a5c9900ccf1fdfbddfe2533a3c`, file
  `engine/src/mouse.c`, whose header attributes the mouse module under
  CC-BY-SA
- Material consulted: X-high/X-low/Y-high/Y-low nibble order, pin-8 edge
  progression, active-low button placement, timeout behavior, and working
  3.58 MHz Z80 settling-loop magnitudes
- Purpose: cross-check the public hardware protocol and choose conservative
  first/subsequent sample delays where the MSX specifications give no numeric
  settling interval
- RainBIOS use: protocol behavior and timing facts only; no implementation code
  copied

## 2026-08-02 — GeoBench MSX input source

- Adjacent open-source repository revision:
  `f83b43feda2730d7c33fca9135f603c113ccc5db`
- License: BSD-3-Clause in `LICENSE`
- Files consulted: `lib/msx/input.asm` and `docs/MSX2.md`
- Relevant checksums:
  - `lib/msx/input.asm`:
    `6ccaf39d360767f66b70d0fd7a0c6550d6fe189a05a73af68d535db05306f660`
  - `docs/MSX2.md`:
    `969562a84011d708982a308bb3a925c840978ac3820ae3d28529dd1ca92cd66d`
- Material consulted: public BIOS calls used for cursor, joystick, trigger, and
  mouse input; standard direction mapping; mouse opt-in behavior; and the
  documented `FFh,FFh` / `01h,01h` empty-port filters
- Purpose: identify why the rendered GeoBench desktop had no usable pointer and
  define an endpoint-compatible public BIOS test
- RainBIOS use: calling-contract and externally visible behavior cross-check;
  no GeoBench implementation code copied

## 2026-08-03 — Official ZX0 v2 compressor and Z80 decoder

- Upstream: `https://github.com/einar-saukas/ZX0`
- Revision: `ecde3a2ae05061fe06469ed46df81a33b7de7d86`
- License: BSD-3-Clause, reproduced in `LICENSES/ZX0.txt`
- Files imported unchanged: `src/zx0.c`, `src/zx0.h`, `src/compress.c`,
  `src/memory.c`, and `src/optimize.c`, stored under `tools/zx0/`
- Decoder used: upstream standard forward Z80 decoder, stored as
  `src/zx0_decompress.asm`
- Purpose: losslessly store the generated RainBIOS logo and menu tables below
  the `4000h` combined-ROM boundary
- RainBIOS use: the source-built host compressor emits `.zx0` streams; the
  68-byte decoder expands one table at a time to transient `C000h-D7FFh` RAM
  before the original RainBIOS VRAM upload path. Host tests decode every stream
  independently and require an exact round trip.
