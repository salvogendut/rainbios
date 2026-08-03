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
before replacing that stack's slot. At this stage expanded IDs failed closed;
M1H later added their supported forms. See `docs/abi/slot-calls.md`.

M1C adds primary-slot `RDSLT` and `WRSLT` on every page. The probe seeds the
physical RAM device with distinct page values, verifies reads and writes
through the public BIOS entries, requires documented register preservation,
and checks that every call restores the exact previous map. M1H later extended
these operations to expanded slots.

M1D adds returning primary-slot `CALSLT` calls for page 1 and page 2. The
called code can replace all normal result registers and flags; RainBIOS keeps
the old map in the call's page-3 stack frame and restores it exactly after
`RET`. Page-0/page-3 targets still fail closed; M1H later added expanded
page-1/page-2 calls.

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
slots, gives memory mappers an independent `3,2,1,0` 64 KiB page baseline,
publishes the RAM slot through `RAMAD0`-`RAMAD3`, and implements expanded
`ENASLT`, `RDSLT`, `WRSLT`, page-1/page-2 `CALSLT`, and the corresponding
`CALLF` path. Cartridge and RBP1 discovery enumerate all four subslots of each
expanded primary slot. Dedicated openMSX fixtures cover physical selector
state, all address pages, expanded cartridge INIT, and expanded BBC BASIC menu
launch; 1983 confirms boot with MSX2 expanded-slot RAM.

M1I extends `CALSLT`/`CALLF` to page-0 and page-3 targets. Page-0 targets
switch page 0 through the page-3 `CLPRIM` helper (primary and expanded, with
the selector restored on return); page-3 targets use the ordinary returning
path when they already occupy page 3, and otherwise install a return frame in
the target's writable page-3 RAM that restores the map, the selector, and the
caller's stack. The openMSX slot probes cover page-0, page-3 same-slot,
page-3 different-slot (primary and expanded), and the fail-closed cases.

M1J detects the memory-mapper segment count at boot with a page-2 marker
probe, publishes it in `MAPPER_SEGMENTS`, and restores the `3,2,1,0` baseline.
Machines without a mapper report one segment. The `test-openmsx-mapper` target
verifies the count and that a segment beyond the fixed 64 KiB baseline maps
distinct RAM.

- process broader interrupt sources (controllers, cassette, disk) in the IM 1
  handler; the keyboard scan itself is covered by M3A/M3D;
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

M2C adds partial `CHGCLR`, `SETMLT`, and `INIMLT` implementations. Screen 3
publishes its table bases, programs VDP R0-R6, hides sprites, initializes the
name and pattern planes, and applies the selected colors. A keyboard-driven
1983 diagnostics check verifies the resulting multicolor VDP state and a
nonblank rendered frame.

- initialize TMS9918-compatible VDP state;
- finish base VRAM transfer, screen-mode, sprite, and color calls;
- complete the remaining character set and keep its provenance documented;
- finish the remaining text control characters and cursor presentation;
- add host and emulator tests for port ordering and VRAM boundaries.

Exit criterion: diagnostic cartridges can display and update a text UI through
BIOS calls alone.

## M3 — Keyboard, PSG, and basic devices

Status: in progress.

M3A initializes the standard 40-byte key buffer and matrix work areas, scans
international rows 0-8 from `KEYINT`, translates new printable and editing-key
presses with Shift/Ctrl, toggles the standard `CAPST` lock (and its LED) on
CAPS presses, and implements partial `CHSNS`/`CHGET` plus complete buffer
clearing through `KILBUF`. A physical-matrix openMSX probe covers Shift+A,
blocking Return input, and both CAPS states. The pinned BBC BASIC payload then passes
its editing, expression, program, error, timing, and timeout sequence with
zero ROM writes; 1983 independently renders its banner and prompt.

M3B implements the cassette motor plus long/short leader and framed-byte
input/output calls. Original fixtures confirm raw CAS input in openMSX and
1983, BBC BASIC `LOAD`/`RUN` in 1983, and a semantically decoded WAV recording
from BBC BASIC `SAVE` in openMSX. Standard CAS input is the current baseline;
slow sampled-WAV replay remains pending.

M3C partially implements `GICINI` through the PSG hardware registers, including
the controller GPIO baseline, and implements cursor-key and two-port
joystick directions through `GTSTCK`, implements all documented `GTTRIG`
selectors, and implements the two-port mouse request/X/Y subset of `GTPAD`.
An openMSX probe covers all eight cursor directions, active and neutral
connector reads, Space, trigger register preservation, both mouse selectors,
the openMSX `01h,01h` empty-port coordinate signature, and PSG R15 state.

M3D completes the interactive keyboard path. The STOP key latches a break in
`INTFLG` (Ctrl-STOP = 3, STOP alone = 4) and clears pending input; `BREAKX`
tests the physical Ctrl-STOP matrix directly, and `ISCNTC`/`CKCNTC` consume
the latched break and return carry so disk kernels and Nextor can abort.
Held keys auto-repeat through `SCNCNT`/`REPCNT`, restarting the delay on any
new press. `INIFNK` seeds the ten default function-key strings in `FNKSTR`;
`FNKSB`, `ERAFNK`, `DSPFNK`, and `TOTEXT` manage the `CNSDFG` display flag,
render/erase the bottom text line, and force the text width. The openMSX
keyboard probe covers the break latch, both stop variants, buffer clearing,
the display-flag transitions, text-mode forcing, and auto-repeat.

M3E implements the prompt/line-input path. `PINLIN` reads keyboard input into
`BUFFER` until Return or a Ctrl-STOP break, returning `HL = BUFFER-1`, the
character count in `B`, and carry on a break; `INLIN` adds the `AUTFLG` echo
suppression and `QINLIN` prints the `? ` prompt. Backspace and Delete remove
the last character. `BEEP` emits a short PSG tone. The keyboard probe covers
plain, backspace-edited, prompted, and break-terminated lines plus the beep.

M3F implements international dead-key input. The accent glyphs latch
`DEADST` (grave, acute, circumflex, umlaut) and the next a/e/i/o/u/y combines
into the standard MSX accented characters, while non-combinable keys fall back
to the plain character and clear the latch. The keyboard probe covers
combining and fallback cases; the accented font glyphs remain M2 charset work.

M3G adds the audible key click and the paddle call. With `CLIKSW` nonzero a new
key press drives the 1-bit click line for a couple of frames. `GTPDL` reads
paddles 1-8 by firing the pin-8 trigger and measuring the one-shot low pulse on
the PSG port-A pin (0 with no paddle), restoring R15. The keyboard probe
checks the click bit, and the controller probe checks the no-paddle neutral
result.

- complete the remaining editing-key behavior (mid-line cursor editing);
- complete `GICINI` PLAY statement work-area initialization;
- implement touch-panel, light-pen, and trackball-detection calls;
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

- define and test startup register and work-area state;
- support common slot and mapper arrangements needed before cartridge code
  installs its own mapper;
- create a compatibility corpus of redistributable homebrew and original test
  ROMs.

Exit criterion: a published set of redistributable MSX1 cartridges boots and
passes a documented smoke-test matrix.

## M5 — MSX2 main BIOS and SUB-ROM

Status: not started. The MSX1 ROM can scan for the standard `CD` SUB-ROM
signature when providing a guarded partial Screen 7 `CHGMOD` handoff for
current Nextor/GeoBench compatibility testing, but it does not publish
`EXBRSA`, expose general SUB-ROM dispatch, or constitute an MSX2 main BIOS.

- add a distinct MSX2 main-ROM build with V9938 detection and dispatch;
- implement SUB-ROM discovery and inter-slot calling;
- implement bitmap modes, palette, commands, clock, and extended VRAM calls;
- validate 64 KiB and 128 KiB VRAM configurations.

Exit criterion: MSX2 diagnostics and the compatibility corpus pass on multiple
emulated machine layouts and real hardware.

## M6 — Completeness and optional system components

Disk bring-up now has safe hook-dispatching defaults, post-extension `H.STKE`
and `H.RUNC` sequencing, and an optional source-built NMS 8250 disk extension.
Its bounded read-only `PHYDIO` path handles arbitrary sectors and multi-sector
side/track crossings on 720 KiB media. Reproducible 1983 probes cover success,
no media, partial record-not-found counts, and write rejection without host
image changes. An openMSX controller test double injects stuck IRQ, stuck DRQ,
CRC, lost-data, and seek/not-found/not-ready faults to exercise the driver's
timeout and error-mapping branches. `DSKCHG` reports changed, unchanged, and
unknown states from the WD2793 drive register and status without ever starting
the motor, and `GETDPB` publishes the fixed F9 DPB without touching the
controller; both report error 12 for drives other than A and are validated by
1983 probes with and without a mounted image. Filesystem services, formatting,
drive B, other floppy controllers, writable media, and real-hardware timing
validation remain pending; M7 owns the implemented boot-sector paths.

- close remaining main BIOS and SUB-ROM ABI gaps;
- characterize flags, clobbered registers, timing-sensitive I/O, and error
  behavior;
- scope independently implemented BASIC and disk firmware as separate
  components with their own tests and provenance;
- add a read-only-safe, hook-dispatching disk baseline for `PHYDIO`, `FORMAT`,
  `ISFLIO`, `OUTDLP`, `GETVCP`, and `GETVC2` before adding writable media
  support;
- publish reproducible releases, symbols, compatibility results, and known
  deviations.

## M7 — Disk boot

Status: in progress.

The production NMS 8250 disk extension now installs a `H.RUNC` bootstrap hook.
At cold boot RainBIOS selects the disk device and the hook reads the boot
sector into `C000h`, validates the MSX-DOS `EBh`/`E9h` signature, and enters the
loader at `C000h+1Eh` with the cold-boot flag and carry set. A deterministic
720 KiB F9 boot fixture (a two-sector loader plus marker) is verified end to end
by 1983: the boot sector runs in page-3 RAM, calls `DSKIO` for a further
sector, and reaches a labelled spin; a separate probe confirms that a missing or
non-bootable medium falls back to the interactive menu with the RainBIOS stack
intact.

The Space-key boot menu now offers three options. Option 1 starts BBC BASIC,
option 2 re-enters the drive-A `H.RUNC` boot-sector path on demand (a valid
payload holds back the cold-boot auto-boot so the menu is reachable), and
option 3 boots Sunrise IDE and SD Mapper V2 cartridges through
RainBIOS's own page-0 ATA/SPI backends. The scan recognizes the shared
storage-ROM header, records its slot, and follows its standard `INIT`. A disk
kernel can install `H.RUNC` and take over cold boot; otherwise option 3 maps the
cartridge in page 1, probes its controller type, reads sector 0 into `C000h`,
validates `EBh`/`E9h`, and enters `C000h+1Eh`. The 1983 fixtures then read sector
1 directly through the selected controller and reach labelled pass loops;
no-medium cases restore the extension-owned pre-call map and return to the menu.

Local Sunrise IDE and SD Mapper cartridges plus a FAT16 image now complete the
standard path: cartridge `INIT`, disk-work-area allocation, `H.RUNC`,
`NEXTOR.SYS` 2.12, and the final prompt are verified end to end. SD coverage
includes card-A/card-B automatic boot, dual-card selection, and no-card menu
fallback. These paths also cover the pre-DOS stack, the mapper-compatible
expanded `CALSLT` frame, and Nextor's direct use of the original-BIOS keyboard
decoder at `0D89h`.

The GeoBench application layer is now an explicit three-target integration
matrix. Sunrise IDE and SD Mapper V2 in 1983 both require the complete Screen 7
desktop with R0=`0Ah`, R1=`62h`, `SCRMOD=7`, and mapper pages
`03h,02h,01h,00h`. The openMSX Sunrise target independently requires the
desktop segment to be mapped into page 1 with the same Screen 7 baseline and
active UI output, using an isolated image copy that must remain unchanged. The
sampled PC is diagnostic only because it can transiently be in a kernel or
frame-pacing routine. The current GeoBench image still performs timing-sensitive
VDP accesses in an unmodified openMSX run, so full openMSX desktop-geometry
parity remains open and is not claimed by that boot-state gate.

RainBIOS provides the firmware interfaces needed by disk systems; it will not
bundle or prescribe a DOS. Users supply the system of their choice, while the
test matrix uses the freely available Nextor as its primary compatibility
target.

- boot a real MSX-DOS 1 `MSXDOS.SYS`/`COMMAND.COM` disk through the loader
  contract (requires provenance-cleared DOS files);
- provide the documented loader inputs `HL`/`DE` (disk error handler and
  `ENAKRN` entry) once a real kernel consumes them;
- validate Sunrise and SD Mapper timing, card initialization, and electrical
  behavior on real hardware;
- close the timing-sensitive GeoBench/openMSX rendering gap and promote that
  boot-state test to the same full-desktop geometry gate used in 1983;
- filesystem services, formatting, floppy drive B, other controllers, writable
  media, and real-hardware timing validation remain pending.

“Complete” means documented compatibility for the public interfaces and boot
behavior; it does not mean byte identity with any existing ROM.
