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

M1K services broader sources in the IM 1 handler. Each VBlank the handler
captures the active-low joystick matrix for both connectors into a work area
(preserving PSG R15), so `GTSTCK`/`GTTRIG` read a consistent interrupt
snapshot instead of live port access, and it counts down a cassette-motor
auto-stop timer that turns the motor off about two seconds after the last
start/activity, matching `STMOTR`'s off write. The services probe verifies the
snapshot capture and the auto-stop; the controller probe reads directions and
triggers from the captured state.

M1L completes the disk source in the IM 1 handler with a floppy motor-off
timer. The handler counts down `DISK_MOTOR_TIMER` and, at zero, writes the
FDC motor-off value to the drive register when `DISK_PRESENT` (set at boot
when a disk device is selected). The `disk_motor_arm` helper and the work
bytes let the NMS 8250 disk ROM keep the motor running briefly after an
access and hand the stop to the interrupt instead of stopping it inline. The
services probe verifies the armed timer clears after the timeout; the disk
ROM adoption of the arm helper remains a follow-up.

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

M2D implements the six text cursor-movement entries. `RIGHTC`/`LEFTC` move
`CSRX` within the current `LINLEN` (stopping at either edge), `UPC`/`DOWNC`
move `CSRY` within `CRTCNT` (stopping at the top and bottom rows), and
`TUPC`/`TDOWNC` scroll the text one row down or up when the cursor is already
on the boundary row, reusing the Screen 0/1/2 layouts of the `CHPUT` wrap
scroll. The cursor probe covers every move, both edges, and both scroll
directions against the seeded name table.

M2E completes and verifies the base VRAM transfer path. `RDVRM`/`WRTVRM`
read and write a byte through the data port after `SETRD`/`SETWRT` set the
14-bit pointer with the control-port pair interrupt-atomic; `FILVRM` fills a
block, `LDIRMV` copies VRAM to RAM, and `LDIRVM` copies RAM to VRAM. The VRAM
probe verifies the write/read round trip, the 14-bit address wrap at `4000h`,
the top boundary, a 256-byte fill, both block-copy directions, and that the
VDP registers remain readable after the data-port traffic.

M2F implements the three screen-mode switch entries. `SETTXT`, `SETT32`, and
`SETGRP` program the live VDP with the same registers and R1 shadow formula as
`INITXT`/`INIT32`/`INITGRP` and update `SCRMOD`/`LINLEN`/cursor, but leave the
name, pattern, colour, and sprite tables alone so a caller can switch modes
over an already-set-up screen. The screen-mode probe verifies that each switch
reproduces the corresponding initialize state and that a seeded VRAM byte
survives the switch.

M2G implements the sprite utilities. `CLRSPR` initializes all 32 sprites
(complete 2 KiB pattern table cleared, each attribute set to Y = 209/217,
X = 0, a pattern number stepping by 1/4 for 8x8/16x16, and the foreground
colour); `CALPAT` returns `PATBAS + A*8` or `PATBAS + A*32`; `CALATR` returns
`ATRBAS + A*4`; and `GSPSIZ` queries the current R1 sprite-size bit without
changing it, returning 8/carry-clear or 32/carry-set. Screen initialization
and switching preserve R1's sprite-size/magnification bits. The sprite probe
verifies both sizes, both address scales, mode preservation, and the complete
attribute/pattern clear. Arkanoid independently gates the 16x16 state in both
emulators.

M2H implements `GRPPRT`, the graphics-mode character printer. It renders the
character in A at the current cursor position using the project font and the
foreground colour (the same pattern and colour-cell path as the Screen 2
`CHPUT` branch), then advances the cursor by one 8-pixel cell with wrapping,
and moves the cursor for carriage return and line feed. The graphics print
probe verifies the rendered glyph bytes, the colour cell, the advance, and
the CR/LF cursor movement.

M2I completes the text control characters in `CHPUT`. Tab advances to the
next 8-column tab stop (wrapping to the next row past the line end), cursor
up moves one row without passing the top, and form feed clears the screen
and homes the cursor; these join the existing backspace, carriage return,
line feed, wrapping, and scrolling. The text-control probe verifies both tab
positions, the cursor-up edge, and the cleared-and-homed form feed.

M2J completes the character set. The project-owned 5x7 font now carries all 36
MSX international characters at 0x80-0xA3: the lowercase accented vowels and y
(which the M3 dead-key path produces, previously rendering as blanks), the
uppercase accented forms, the cedillas and ligatures, and the currency
symbols. The font probe dumps a sample of the accented glyphs from the live
pattern table and the checker compares them to the built font; host tests lock
the glyph bytes and provenance.

M2K verifies the TMS9918-compatible VDP-state initialization. The boot
publishes all eight register shadows and a consistent Graphics II state (the
live registers match the shadows, and the name/pattern/colour/sprite bases
plus `SCRMOD`/`LINLEN` are published); `DISSCR`/`ENASCR` toggle the R1 display
bit through the shadowed path, `WRTVDP` keeps the shadows in sync, and
`INITXT`/`INIT32`/`INITGRP` each end with live registers equal to their
shadows and the correct table bases and mode bytes. The VDP-state probe locks
in the boot, display-toggle, shadow-write, and per-mode states.

M2L completes the color behavior. `CHGCLR` now follows the original BIOS
per-mode convention: Screen 0 sets R7 to `(FORCLR<<4)|BAKCLR`, Screens 1-3 set
R7 to the bare `BDRCLR`, and Screen 1 additionally fills its 32-byte color
table with `(FORCLR<<4)|BAKCLR`, all through the shadowed `WRTVDP` path. The
color probe verifies the boot state and each mode's R7, color table, and
shadow.

M2M verifies the last M2 partials. `RDVDP` reads VDP status register zero and
mirrors it in `STATFL`; `INIMLT` programs the TMS9918 for Screen 3 multicolor
(publishing the MLT table bases, hiding sprites, seeding the six-band name
table, and clearing the pattern plane to the background); and `SETMLT`
re-programs the same R0-R6 state from the work-area bases. The Screen 3 probe
locks in the status mirror, the mode bytes and register programming, the
published bases, and the hidden-sprite state.

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
suppression and `QINLIN` prints the `? ` prompt. `BEEP` emits a short PSG tone.
The keyboard probe covers plain, backspace-edited, prompted, and
break-terminated lines plus the beep.

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

M3H completes the editing-key behavior inside `PINLIN`/`INLIN`: the cursor
moves left and right, Home returns to the start, typing inserts at the cursor,
Backspace removes the character before it, and Delete removes the character
under it, redrawing the line from its saved start position after each edit.
`GICINI` now initializes the full PLAY statement work area in addition to the
PSG hardware: `QUEUES` points at the queue table, `FRCNEW` is 255, and the
voice static data and the three voice queues are cleared (`MUSICF`/`PLYCNT`
zero). The keyboard probe covers the mid-line insert/Backspace/Delete/Home
sequence, cursor-right append, and the initialized `GICINI` work area.

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

Issue #60 adds the pinned payload to the upper half of the ordinary 32 KiB
MAIN-ROM. Every build rebuilds the exact companion artifact, verifies its
digest, and embeds a ZX0-compressed `RBC1` container. RainBIOS reconstructs the
payload in page-1 RAM at launch. External cartridges retain their normal first
opportunity; storage retains priority over the internal copy; a clean storage
return leads to a bounded Space-key window and then automatic BASIC. A
returning ordinary game/application `INIT` suppresses that automatic fallback
because such cartridges may continue through hooks. A compatible external
payload remains the upgrade override. Dedicated 1983 and openMSX probes cover
the no-cartridge automatic path.

- define and test startup register and work-area state;
- support common slot and mapper arrangements needed before cartridge code
  installs its own mapper;
- create a compatibility corpus of redistributable homebrew and original test
  ROMs.

Exit criterion: a published set of redistributable MSX1 cartridges boots and
passes a documented smoke-test matrix.

## M5 — MSX2 main BIOS and SUB-ROM

Status: in progress (first slice).

M5A produces a distinct MSX2 main-ROM build (`build/rainbios_msx2.rom`) from the
same source with `-DMSX2=1`. It sets the `002Dh` generation byte to `01`,
detects a live V9938 through the standard `CD` SUB-ROM scan, publishes the
discovered slot in `EXBRSA` (`FAF8h`), loads a V9938 R8-R23 shadow baseline, and
extends the public `WRTVDP` to shadow registers 8-23. The 1983 `msx2` model and
an openMSX V9938 fixture both boot the ROM with the rendered boot logo, the
correct generation byte, `EXBRSA=83h`, and `RG8SAV=08h`. This is a fixed-address
front-end slice; it does not publish general SUB-ROM dispatch, `EXTROM`, bitmap
modes, palette, commands, clock, or extended VRAM calls, and the MSX1 ROM's
guarded Screen 7 handoff remains its own path.

M5B adds the standard SUB-ROM calling contract to the MSX2 build: `SUBROM`
(`015Ch`), `EXTROM` (`015Fh`), and `CHKSLZ` (`0162h`). `EXTROM` calls the SUB-ROM
routine at IX through the mapper-compatible expanded `CALSLT` frame using the
slot in `EXBRSA`, preserving the caller's alternate registers and interrupt
state; `SUBROM` implements the documented `push IX`/`jp SUBROM` wrapper;
`CHKSLZ` scans primary and expanded slots for the `CD` signature and republishes
`EXBRSA` with carry set when found. Dedicated 1983 and openMSX probes call all
three entries into a known SUB-ROM fixture and verify the called routine's
effect, `EXBRSA=83h`, and the carry result. The MSX1 ROM keeps its `015F`
compatibility return and remains byte-identical. Bitmap modes, palette, VDP
commands, clock, and extended VRAM that run *inside* the SUB-ROM remain
follow-up M5 work.

M5C adds a RainBIOS-owned SUB-ROM (`src/main_msx2_sub.asm`, built as
`build/rainbios_msx2_sub.rom`). It carries the standard `CD` header and the
documented SUB-ROM fixed-entry layout and provides the extended VDP services
through the `EXTROM` dispatch: `CHGMOD` for bitmap screens 5/6/7/8 with
table-base work-area publication and a full bitmap clear, the palette calls
`INIPLT`/`RSTPLT`/`GETPLT`/`SETPLT` over the V9938 latch with a VRAM palette
store, `WRTVDP`/`VDPSTA`, and 16-bit `WRTVRM`/`RDVRM` covering the full
128 KiB range. Dedicated 1983 and openMSX probes call all three entry groups
and validate the observable VDP registers, work area, VRAM, and palette.

M5D adds the VDP command transfers and the real-time clock to the SUB-ROM.
`BLTVV` copies a VRAM rectangle through the LMMM command, `BLTVM`/`BLTMV`
move pixels between RAM and VRAM through the LMMC/LMCM CPU-transfer handshake
(reading/writing R44 and status 7 with the mode's pixel packing), and
`REDCLK`/`WRTCLK` read and write RTC registers through the `B4h`/`B5h` ports.
Dedicated 1983 and openMSX probes call all five entries and validate the
copied VRAM bytes, the BLTMV header/pixels, and the RTC round trip.

M5E validates the firmware on a 64 KiB VRAM machine (`test-openmsx-msx2-64k`),
reusing an openMSX fixture with a 64 KiB V9938, CHGMOD Screens 5/8, and
even-address 16-bit WRTVRM/RDVRM round trips across the full 64 KiB range.
Note that openMSX's V9938 64 KiB model has a known inaccuracy for CPU VRAM
access to odd addresses (openMSX issue #1157), so the 64 KiB gate exercises
the even-address range; the 128 KiB gates already cover every address.

The disk-file transfer commands (`BLTVD`/`BLTDV`/`BLTMD`/`BLTDM`) are left as
documented safe returns and screen 10-12 remains out of scope. A real disk-file
implementation streams whole files through the DOS API (BDOS open/create/set
DTA/random block I/O/close) and therefore needs the machine to boot a disk
system such as Nextor. De-risking found that the RainBIOS MSX2 build does not
yet boot a cartridge/Nextor storage layer: the boot scan finds the Sunrise
cartridge (IDE_SLOT is published) but on the MSX2 model it does not take over
(its bank-windowed header is not recognized), whereas the NMS 8250 reference
boots Nextor end to end. Wiring MSX2 storage boot is therefore separate
M6/M7 work and a prerequisite for these entries; until then they stay safe
returns, matching the C-BIOS reference.

- add a distinct MSX2 main-ROM build with V9938 detection and dispatch;
- implement SUB-ROM discovery and inter-slot calling;
- implement bitmap modes, palette, commands, clock, and extended VRAM calls;
- validate 64 KiB and 128 KiB VRAM configurations.

Exit criterion: MSX2 diagnostics and the compatibility corpus pass on multiple
emulated machine layouts and real hardware.

## M6 — Completeness and optional system components

Status: in progress.

The combined-ROM feasibility slice is implemented. ZX0-compressed boot/menu
tables and the directly addressable font fit below `4000h`; the upper bank
holds an `RBC1` stream generated from the exact 16 KiB interpreter and expands
it into page-1 RAM at launch. The build asserts the boundary, validates the
container and reconstructed markers, and retains the companion ROM as a
separate artifact. The initial lower-bank reserve was only 440 bytes, so a simpler
lower-entropy logo was added; it reduced the compressed logo tables from 3,922
bytes to 917 bytes. The current menu copy leaves a 3,247-byte reserve;
continuing size gates are still required before substantial new page-0 work.
Human-readable component notices are complete; public release remains gated
on branding permission or a rename, a machine-readable component manifest,
broader emulator regression coverage, and real hardware.

A machine-readable component manifest (`components.json`) now declares the
combined ROM's components with SPDX-style license identifiers, source
identity (including the pinned external commits), and the dependency lock for
the embedded payload. `check-manifest` and the host suite validate the
manifest against the built artifacts: every referenced license and source
file exists, external components pin a repository and commit, the manifest and
`THIRD_PARTY_NOTICES.md` agree on license citations, and the combined ROM's
`RBC1` container carries the same compressed payload whose uncompressed digest
matches `deps/bbcbasic-z80-msx.lock.json`. A full SPDX JSON export remains a
follow-up; the manifest format is chosen to be translatable to SPDX later.

The lower-bank headroom is now a host-suite gate:
`test_lower_bank_preserves_headroom_ceiling` fails if the last non-`FF` byte
of the lower bank rises above `3600h` (reserve below `0xA00` bytes) or falls
below `3000h`, so substantial new page-0 work must be a deliberate, documented
step rather than an accidental boundary erosion.

The stub BIOS entries are characterized and gated: `test-1983-stubs` calls
all 25 callable stub entries (SYNCHR, CHRGTR, OUTDO, GETYPR, INITIO, STRTMS,
LPTOUT, LPTSTT, CNVCHR, LFTQ, PUTQ, the SCALXY..CHGSND group, and CALBAS)
through CALSLT with known register inputs and verifies the documented
safe-return contract — `scf; ret` sets carry and preserves A/BC/DE/HL. NMI
(0066h) is excluded: it is an interrupt return (`retn`), not a callable stub.

The partial ABI entries with explicitly named flag/clobber gaps are now
characterized: `test-1983-abi-clobber` verifies DCOMPR's compare contract
(carry when HL<DE, zero when equal, carry clear when HL>DE, BC preserved) and
a WRTPSG/RDPSG round trip through the PSG ports. Their notes in
`docs/abi/main-bios.csv` are updated.

The text and function-key entries are characterized by `test-1983-fnkey`:
POSIT positions the cursor to (H, L) in CSRX/CSRY, ERAFNK clears CNSDFG and
erases the bottom text row, DSPFNK sets CNSDFG and moves the cursor to the
last row, FNKSB toggles per CNSDFG, and TOTEXT forces the text mode and
preserves the function-key display state. Their notes in `docs/abi/main-bios.csv`
are updated. Remaining partial entries whose flags or clobber behavior are
still unprobed (keyboard and slot primitives among others) are follow-up
characterization work.

A reproducible release bundle is now produced by `make release` (and
`check-release` validates it). It assembles the production ROMs, their symbol
files, `components.json`, `THIRD_PARTY_NOTICES.md`, and the license texts into
`build/release/<git-describe>/` with a `SHA256SUMS` file and `RELEASE-NOTES.md`
naming the source commit. `make test` rebuilds and validates the bundle, so
the shipped ROM digests always match the freshly built outputs. The bundle now
also carries an SPDX 2.3 JSON document (`rainbios.spdx.json`) generated from
the component manifest: each component becomes a Package with its SPDX license
expression, external components pin the source repository and commit as the
download location and version, the production ROMs appear as files with their
SHA-256 digests, and the Zlib-style interpreter notice is declared as an
extracted license. The SPDX document is validated by the host suite alongside
the manifest. A public GitHub release remains gated on branding permission or
a rename; the local bundle is the reproducible distribution artifact.

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
- preserve independently testable BASIC and disk component boundaries even
  when the BASIC payload is aggregated into the main ROM;
- preserve the restored lower-bank reserve as firmware grows;
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

The Space-key boot menu now offers `START BASIC`, `BOOT FLOPPY`, and
`BOOT IDE OR SD` beneath `RainBIOS (c) salvogendut 2026`. Option 1 starts the
selected BASIC payload. Option 2 re-enters the drive-A `H.RUNC` boot-sector
path on demand (a valid payload holds back the cold-boot auto-boot so the menu
is reachable), and option 3 boots Sunrise IDE and SD Mapper V2 cartridges
through RainBIOS's own page-0 ATA/SPI backends. The scan recognizes the shared
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
  media, and real-hardware timing validation remain pending;
- restore the Sunrise IDE bootstrap 1983 gates: `test-1983-ide-boot` observes
  the CPU reaching unused ROM padding instead of the fixture pass label, and
  `test-1983-ide-menu` does not return the no-medium fallback to the RainBIOS
  menu stack; the SD Mapper paths pass.

“Complete” means documented compatibility for the public interfaces and boot
behavior; it does not mean byte identity with any existing ROM.
