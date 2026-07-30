# Roadmap

The project advances by externally visible compatibility rather than by source
file count.

## M0 — ROM contract and build

Status: complete.

- produce a deterministic 32 KiB MSX1 main ROM;
- place metadata and ABI veneers at standardized addresses;
- implement a few self-contained port and memory-transfer primitives;
- display the source-controlled boot logo through a stackless Graphics II path;
- play a stackless PSG startup motif and expose an early boot-menu preview;
- validate the ROM layout on the host;
- document provenance rules and the compatibility matrix.

Exit criterion: `make test` passes from a clean checkout and every exposed
entry point is truthfully classified as implemented, partial, or stub.

## M1 — Reset, slots, RAM, and interrupts

Status: in progress.

The first M1 slice preserves the reset-selected ROM mapping, tests both
16 KiB pages of a slot RAM candidate, maps the accepted 32 KiB into
pages 2 and 3, establishes `SP=F380h`, clears the MAIN-ROM work area through
`FFFEh`, sets `BOTTOM`, `HIMEM`, and `BIOSSLT`, and initializes every hook
entry with `RET`. Host tests, primary and expanded openMSX layouts (including
a page-3-only decoy), and MSX1/MSX2 checks in 1983 cover this state.

The M1B slice implements and tests direct primary-slot register access and
`ENASLT` for non-expanded slot IDs on all four pages. Page 0 completes its
switch from a RAM helper; page 3 removes the return address from the old stack
before replacing that stack's slot. Expanded IDs currently fail closed without
changing the map. See `docs/abi/slot-calls.md`.

M1C adds primary-slot `RDSLT` and `WRSLT` on every page. The probe seeds the
physical RAM device with distinct page values, verifies reads and writes
through the public BIOS entries, requires documented register preservation,
and checks that every call restores the exact previous map. Expanded-slot
forms remain pending.

M1D adds returning primary-slot `CALSLT` calls for page 1 and page 2. The
called code can replace all normal result registers and flags; RainBIOS keeps
the old map in the call's page-3 stack frame and restores it exactly after
`RET`. Expanded slots and page-0/page-3 targets still fail closed.

M1E scans `4000h` and `8000h` in each non-BIOS primary slot for the public
`AB` header and invokes a nonzero page-1/page-2 `INIT` address. An original
BSD-3-Clause cartridge fixture reaches its loop, writes a proof marker to
RAM, and leaves the logo visibly rendered in both openMSX and 1983.

M1F enables the TMS9918 VBlank source and Z80 IM 1, preserves the normal
register set in `KEYINT`, runs `H.KEYI` and `H.TIMI`, acknowledges VDP status,
and increments `JIFFY`. The primary page-1/page-2 subset of inline `CALLF`
allows standard five-byte hooks to cross slots. An openMSX probe installs an
`H.TIMI` hook in another primary slot and checks interrupt frequency and exact
slot-map restoration.

M1G discovers version-1 RainBIOS payload descriptors in page-1 cartridges.
Checksum, version, type, service, entry, and RAM requirements are
validated before the first compatible payload is exposed to the boot menu.
Claimed but invalid descriptors fail closed and do not fall through to their
ordinary `INIT`.

M1H initializes `EXPTBL`/`SLTTBL`, discovers contiguous RAM in secondary
slots, and implements expanded `ENASLT`, `RDSLT`, `WRSLT`, page-1/page-2
`CALSLT`, and the corresponding `CALLF` path. Cartridge and RBP1 discovery
enumerate all four subslots of each expanded primary slot. Dedicated openMSX
fixtures cover physical selector state, all address pages, expanded
cartridge INIT, and expanded BBC BASIC menu launch; 1983 confirms boot with
MSX2 expanded-slot RAM.

- add page-0/page-3 `CALSLT` support if a compatible stack/trampoline contract
  can be established;
- add memory-mapper sizing and segment allocation beyond the reset segments;
- add keyboard and device processing to the initial IM 1 interrupt handler;
- run the original diagnostic cartridge on hardware;

Exit criterion: cold boot reaches the diagnostic cartridge on representative
MSX1 emulator configurations and at least one hardware configuration.

## M2 — MSX1 display and console

Status: in progress.

M2A corrects the published `WRTVDP` B=data/C=register contract, makes VDP
control-port pairs interrupt-atomic, initializes register shadows and the
current table-base work variables, and provides partial Screen 0/1/2 mode
setup. The console implements `POSIT`, printable `CHPUT`, backspace, carriage
return, line feed, wrapping, scrolling, and `CLS` in the text modes, plus
glyph rendering and scrolling in Graphics II. The project-owned font covers
printable ASCII. The public service probe and two opaque cartridge smoke tests
cover this slice.

M2B makes `INITGRP` produce deterministic empty Graphics II pattern, name,
colour, and sprite tables. The BBC BASIC payload uses the public BIOS VRAM
calls for its independently written `MODE 2/7`, `CLG`, `GCOL`, `MOVE`,
`DRAW`, `PLOT`, and `POINT` subset. A real stored program passes under C-BIOS
and RainBIOS in openMSX; 1983 independently confirms the rendered multicolour
frame. The interrupt path now preserves both normal and shadow Z80 registers
so cross-slot `H.TIMI` hooks cannot corrupt the interpreter.

- initialize TMS9918-compatible VDP state;
- finish base VRAM transfer, screen-mode, sprite, and color calls;
- add a freely redistributable character set with documented provenance;
- finish the remaining text control characters and cursor presentation;
- add host and emulator tests for port ordering and VRAM boundaries.

Exit criterion: diagnostic cartridges can display and update a text UI through
BIOS calls alone.

## M3 — Keyboard, PSG, and basic devices

Status: in progress.

M3A initializes the standard 40-byte key buffer and matrix work areas, scans
international rows 0-8 from `KEYINT`, translates new printable and editing-key
presses with Shift/Ctrl, and implements partial `CHSNS`/`CHGET` plus complete
buffer clearing through `KILBUF`. A physical-matrix openMSX probe covers
Shift+A and blocking Return input. The pinned BBC BASIC payload then passes
its editing, expression, program, error, timing, and timeout sequence with
zero ROM writes; 1983 independently renders its banner and prompt.

M3B implements the cassette motor plus long/short leader and framed-byte
input/output calls. Original fixtures confirm raw CAS input in openMSX and
1983, BBC BASIC `LOAD`/`RUN` in 1983, and a semantically decoded WAV recording
from BBC BASIC `SAVE` in openMSX. Standard CAS input is the current baseline;
slow sampled-WAV replay remains pending.

- complete auto-repeat, lock/dead-key state, function-key expansion, key click,
  and break handling;
- implement PSG initialization, joystick, trigger, and paddle calls;
- implement or explicitly classify printer and remaining basic-device calls;
- make interrupt frequency and locale selectable build properties.

Exit criterion: interactive cartridge diagnostics pass for keyboard, sound,
and controllers.

## M4 — Cartridge compatibility

Status: in progress.

M4A enables the descriptor-driven BBC BASIC menu entry. Space opens a truthful
ready/unavailable menu; option 1 maps the validated payload, supplies the
documented zeroed-register and `SP=F380h` state, and transfers without a return
address. Positive and corrupt-descriptor openMSX probes cover the gate and
entry state. The complete BBC BASIC smoke sequence passes through the menu,
and a standard `H.TIMI` test hook drives the same path in 1983 before its
rendered prompt is checked.

- extend primary header discovery to expanded cartridge slots;
- define and test startup register and work-area state;
- support common slot and mapper arrangements needed before cartridge code
  installs its own mapper;
- create a compatibility corpus of redistributable homebrew and original test
  ROMs.

Exit criterion: a published set of redistributable MSX1 cartridges boots and
passes a documented smoke-test matrix.

## M5 — MSX2 main BIOS and SUB-ROM

- add a distinct MSX2 main-ROM build with V9938 detection and dispatch;
- implement SUB-ROM discovery and inter-slot calling;
- implement bitmap modes, palette, commands, clock, and extended VRAM calls;
- validate 64 KiB and 128 KiB VRAM configurations.

Exit criterion: MSX2 diagnostics and the compatibility corpus pass on multiple
emulated machine layouts and real hardware.

## M6 — Completeness and optional system components

- close remaining main BIOS and SUB-ROM ABI gaps;
- characterize flags, clobbered registers, timing-sensitive I/O, and error
  behavior;
- scope independently implemented BASIC and disk firmware as separate
  components with their own tests and provenance;
- publish reproducible releases, symbols, compatibility results, and known
  deviations.

“Complete” means documented compatibility for the public interfaces and boot
behavior; it does not mean byte identity with any existing ROM.
