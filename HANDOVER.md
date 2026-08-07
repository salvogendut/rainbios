# RainBIOS Handover

## Project

RainBIOS is an independent, open-source firmware project for MSX and MSX2
computers. The repository currently produces a deliberately incomplete 32 KiB
MSX1 main BIOS and an optional 16 KiB read-only disk extension for the Philips
NMS 8250 WD2793 layout.

The compatibility target is externally visible behavior, not byte identity
with proprietary firmware. Public specifications, original tests, authorized
black-box observations, and attributed compatible open-source references are
valid inputs. Never inspect, disassemble, decompile, or derive implementation
code from proprietary ROMs or the quarantined adjacent source trees. Read
`docs/DEVELOPMENT_POLICY.md` and update `docs/REFERENCES.md` whenever a new
implementation reference is consulted.

The default development branch is `main`; use a focused feature branch for
changes. Before starting new work, run `git status --short --branch`; do not
discard unrelated changes in a dirty worktree.

## Artifacts

| Artifact | Build command | Output | Status |
| --- | --- | --- | --- |
| MSX1 main BIOS + BASIC | `make` | `build/rainbios_msx1.rom` | Active, partial BIOS with a compressed source-built payload container in the upper half |
| NMS 8250 disk ROM | `make nms8250-disk-rom` | `build/rainbios_nms8250_disk.rom` | Read-only PHYDIO + DSKCHG/GETDPB + H.RUNC boot hook implemented |
| Standalone BASIC payload | Rebuilt by `make` in sibling repository | `build/payload/bbcbasic_msx_console.rom` | Pinned byte-exact source-built component; compressed into the combined ROM and restored exactly at runtime |
| MSX2 main BIOS | First slice built | `build/rainbios_msx2.rom` | Distinct 32 KiB build sharing the MSX1 source: MSX2 ID byte, V9938 CD-scan detection, EXBRSA publication, R8-R23 shadow baseline and WRTVDP dispatch |
| MSX2 SUB-ROM | Services + command/clock slices built | `build/rainbios_msx2_sub.rom` | Self-contained 16 KiB extended-VDP ROM: CHGMOD Screens 5/6/7/8, palette, WRTVDP/VDPSTA, 16-bit WRTVRM/RDVRM, BLTVV/BLTVM/BLTMV block transfers, REDCLK/WRTCLK. Disk-file transfers, screens 10-12 pending |

The main BIOS and disk ROM remain separate components. `make all` builds only
the combined main BIOS; the model-specific disk ROM is explicitly optional.
Every normal main-ROM build verifies and tests the pinned adjacent
`../bbcbasic-z80-msx` checkout, rebuilds its 16 KiB payload from source, checks
its digest, compresses it with ZX0, and embeds that stream in an `RBC1`
container. No cached-payload fallback exists.

## Current Main BIOS Status

The main BIOS currently provides:

- a distinct MSX2 main-ROM build from the same source with `-DMSX2=1`
  (`make msx2-main-rom`), publishing the MSX2 generation byte, a live V9938
  `CD` scan, `EXBRSA`, a V9938 R8-R23 shadow baseline, extended-register
  `WRTVDP` dispatch, and the standard `SUBROM`/`EXTROM`/`CHKSLZ` SUB-ROM calling
  entries;
- a RainBIOS-owned MSX2 SUB-ROM (`make msx2-sub-rom`,
  `build/rainbios_msx2_sub.rom`) with the standard `CD` header and fixed-entry
  layout, providing bitmap Screens 5/6/7/8 via `CHGMOD`, the palette calls
  `INIPLT`/`RSTPLT`/`GETPLT`/`SETPLT`, `WRTVDP`/`VDPSTA`, 16-bit
  `WRTVRM`/`RDVRM`, the block transfers `BLTVV`/`BLTVM`/`BLTMV`, and the clock
  calls `REDCLK`/`WRTCLK`; the disk-file transfer commands and bitmap modes
  10-12 remain pending M5 work;
- deterministic reset, 32 KiB RAM discovery, stack/work-area initialization,
  and a project-owned Graphics II boot UI;
- primary and expanded slot discovery and control, including `RDSLT`, `WRSLT`,
  `ENASLT`, `CALSLT` for page-0/page-1/page-2/page-3 targets, and inline
  `CALLF`;
- exact normal-register inputs into cross-slot calls and exact restoration of
  primary/secondary mappings after returning calls;
- a mapper-compatible expanded `CALSLT` frame whose saved page-2/page-3
  selectors may be patched by a disk kernel before restoration;
- a fixed 64 KiB memory-mapper baseline of segments `3,2,1,0`, boot-time
  detection of the mapper's segment count published in `MAPPER_SEGMENTS`, and
  publication of the discovered RAM slot through `RAMAD0`-`RAMAD3`;
- IM 1 VBlank handling, standard `H.KEYI`/`H.TIMI` hooks, keyboard buffering,
  and `JIFFY`; the handler also captures the per-frame joystick matrix
  snapshot for `GTSTCK`/`GTTRIG` and drives the ~2s cassette-motor and
  floppy-motor auto-stop timers;
- partial Screen 0/1/2/3 setup, a guarded register-only V9938 Screen 7 handoff,
  text and Graphics II console output, scrolling, VRAM primitives (`RDVRM`/
  `WRTVRM`/`SETRD`/`SETWRT`/`FILVRM`/`LDIRMV`/`LDIRVM`), text cursor movement
  (`RIGHTC`/`LEFTC`/`UPC`/`TUPC`/`DOWNC`/`TDOWNC`), and project-owned
  printable glyphs;
- international keyboard scanning, auto-repeat, Ctrl-STOP break handling
  (`BREAKX`/`ISCNTC`/`CKCNTC`), function-key strings and display
  (`INIFNK`/`FNKSB`/`ERAFNK`/`DSPFNK`/`TOTEXT`), prompt/line input
  (`INLIN`/`PINLIN`/`QINLIN`) with mid-line cursor editing, dead-key accents
  via the dedicated dead-key key (grave/acute/circumflex/umlaut) while the
  accent glyphs themselves stay literal (`'`, `` ` ``, `^`, `"`),
  key click (`CLIKSW`), `BEEP`, paddle input (`GTPDL`), PSG/PLAY work-area
  initialization (`GICINI`), and partial character-input services;
- cassette motor, leader, framed-byte input/output, and BBC BASIC sequential
  cassette storage;
- cartridge discovery in primary and expanded slots, RainBIOS payload
  descriptors, menu launch of external or built-in BASIC, and automatic
  built-in fallback after clean storage returns;
- ZX0-compressed boot/menu tables expanded one at a time through transient
  `C000h-D7FFh` RAM, leaving the public font directly addressable and 3,247
  bytes free below the hard `4000h` lower-bank boundary;
- safe disk BIOS defaults, disk hook dispatch, extension `H.STKE` processing,
  and guarded `H.RUNC` disk bootstrap context.

The main BIOS is not a complete MSX BIOS. `docs/abi/main-bios.csv` is the source
of truth for which fixed entries are implemented, partial, or stubs.

## Embedded BASIC Status

Issue #60 implements the embedded-payload development slice. The normal 32 KiB
image dedicates `4000h-7FFFh` to an `RBC1` container: the exact pinned
companion ROM is compressed to 11,764 bytes at build time, stored from `4008h`,
and expanded into page-1 RAM before launch. The current simpler CC0 boot logo
leaves `3351h-3FFFh` as 3,247 bytes of guarded lower-bank padding. The font
stays raw for `CGTABL`, while the menu and logo tables are also losslessly
ZX0-compressed and expanded into transient RAM before VRAM upload.

External cartridge `INIT` retains first chance. A valid external payload is
the deliberate upgrade override; otherwise existing disk/IDE/SD paths run
before the built-in copy. If those paths return cleanly, RainBIOS validates the
internal `RBC1` container, allows Space for 180 frames, maps contiguous RAM
into page 1, expands the source-built image, checks its `AB` and `RBP1`
markers, and launches it from the RAM slot. Firmware cannot
recover from arbitrary third-party code that never returns or corrupts system
state.

The Screen 1 menu title is `RainBIOS (c) salvogendut 2026`; its three actions
are labelled `START BASIC`, `BOOT FLOPPY`, and `BOOT IDE OR SD`. Option 2 is
the drive-A floppy disk-ROM path, while option 3 is the direct Sunrise/SD
fallback. BASIC's startup `INITXT` clears and homes the text screen; `ERAFNK`
now clears the function-key row directly without moving that cursor, keeping
the sign-on banner at the top.

The new no-cartridge probes pass in 1983 and openMSX, including the rendered
prompt, simple arithmetic, page-1 RAM slot state, decompressed
header/descriptor bytes, and zero writes to the ROM page. The broader internal
graphics, cassette, mixed-storage, and
hardware matrix remains to be promoted. Public release is also blocked on
permission to use the `BBC BASIC` name or a distinct rename. Human-readable
combined notices are present in `THIRD_PARTY_NOTICES.md` and `LICENSES/`; the
machine-readable component manifest is `components.json`, validated by the
`check-manifest` target and the host suite. See `docs/EMBEDDED_BASIC.md`.

## Current Floppy Status

The completed floppy work has two layers.

The main BIOS layer:

- installs safe defaults for `H.PHYD`, `H.FORM`, `H.ISFL`, and `H.OUTD`;
- dispatches public disk-related BIOS entries through those hooks;
- preserves PHYDIO AF/BC/DE/HL inputs across `CALLF`/`CALSLT` dispatch;
- publishes mapper and RAM-slot state required by disk extensions;
- invokes `H.STKE` after extension initialization;
- normally gives a non-empty `H.RUNC` hook the standard cold-boot handoff while
  preserving a nonzero multi-kernel `DEVICE` count;
- retains a previously installed public `H.PHYD` boot path when an empty SD
  Mapper would otherwise displace a bootable floppy controller.

The optional NMS 8250 disk-ROM layer:

- is built from `src/disk_nms8250_rom.asm` and the shared
  `src/disk_nms8250_driver.asm`;
- derives its full slot ID from `IYH`, advertises one drive in `DRVINF`, and
  installs `H.PHYD` without retaining boot control;
- supports drive A, media ID `F9h`, 80 tracks, two sides, nine 512-byte sectors
  per side, and logical sectors 0 through 1439;
- supports multi-sector reads across sector, side, track, and page-2/page-3 RAM
  boundaries;
- validates the entire logical and destination ranges before touching the
  controller;
- allows a cold motor approximately one second to spin up, requests verified
  seeks, uses the WD2793 read settling delay, and bounds all IRQ/DRQ waits;
- returns standard errors for write protection, no media, data errors, seek
  errors, record-not-found, bad parameters, and timeouts;
- returns B as the exact number of fully completed sectors on runtime failure;
- rejects writes before issuing a WD2793 write command;
- reports medium change state from the WD2793 drive register and controller
  status without ever starting the motor or issuing a command;
- publishes the fixed F9 DPB and preserves the kernel-owned drive and FAT
  pointer bytes;
- installs an `H.RUNC` bootstrap hook that reads the boot sector into `C000h`,
  validates the MSX-DOS `EBh`/`E9h` signature, and enters the loader at
  `C000h+1Eh` with `A = 0` and carry set, or returns so the interactive menu
  continues.

The Space-key boot menu invokes the same bootstrap on demand: option 2 runs the
drive-A boot-sector path, while option 3 uses RainBIOS's own Sunrise ATA or SD
Mapper SPI backend to load sector 0 at `C000h` and enter `C000h+1Eh`. The
storage-ROM scan records the cartridge slot and enters its standard `INIT` from
a temporary stack below `F100h`. A non-empty `H.RUNC` normally gets the first
cold-boot handoff; the standalone empty-SD case first tries a preserved
`H.PHYD` drive-A path. Otherwise runtime register probing chooses the direct
controller backend, and failures restore the extension-owned pre-call map and
return to the menu.

The local Nextor targets build a 32 MiB FAT16 image from external `NEXTOR.SYS`
and `COMMAND2.COM`. `test-1983-nextor` runs Sunrise cartridge `INIT`/`H.RUNC`
and reaches `A:\>`. `test-1983-nextor-sd` independently covers SD card A-only,
card B-only, and a dual-card chooser selecting B, with exact Nextor 2.12 prompt
screenshots. `test-1983-sd-menu` verifies the no-card return to RainBIOS's
Space-key menu path, while `test-1983-sd-empty-floppy` proves that an empty SD
Mapper does not suppress a bootable production floppy.
`test-1983-sd-empty-sunrise` also preserves the two-kernel `DEVICE` count and
boots Sunrise as drive C when the empty mapper owns drives A/B. The expanded
`CALSLT` frame accepts Nextor's post-allocation selector patches. The
compatibility entry at `0D89h` supplies the international-keyboard result
expected by Nextor's undocumented original-BIOS probe; the public `FILVRM`
vector jumps to its relocated body.

The formal component contract is `docs/abi/nms8250-disk-rom.md`.

The RainBIOS disk ROM loads and runs an MSX-DOS-style boot sector but does not
itself provide FAT or DOS services. Nextor now boots through Sunrise and SD
Mapper cartridges, while a provenance-cleared MSX-DOS 1 system, formatting,
floppy drive B, writes, non-NMS controllers, and real-hardware timing remain
pending.
Destination buffers must remain within `8000h-EFFFh` while the extension
occupies page 1.

## GeoBench Boot Status

GeoBench (`GBMSX.IMG`) is user-confirmed to boot under RainBIOS through both
Sunrise IDE and SD Mapper V2. That claim now has three explicit integration
targets instead of relying on an ordinary Nextor prompt. The two 1983 targets
require the full rendered Screen 7 desktop through Sunrise and SD Mapper. The
openMSX Sunrise target requires GeoBench's desktop segment to be active in
page 1 with Screen 7 and visible UI output. The
instantaneous PC is diagnostic only because capture can occur in a kernel or
frame-pacing routine. The target does not yet claim the same exact desktop
geometry because the current GeoBench image contains timing-sensitive VDP
access sites under openMSX.

### Fixed and verified

- `BIOSSLT` was computed as `0x83` instead of `0x00`: the pre-DOS scratch-area
  clear (`ld hl,#f300 / ld (hl),#c9 / ld de,#f301 / ld bc,#007f / ldir`) advanced
  the main `DE`/`BC`, so the later `ld a,d / and #03 / ld (BIOSSLT),a` used a
  clobbered slot map. The clear now runs inside `exx/exx`, and the BIOSSLT write
  is verified as `val=00`.
- The four joystick/paddle entries (`GTSTCK` `00D5h`, `GTTRIG` `00D8h`, `GTPAD`
  `00DBh`, `GTPDL` `00DEh`) initially became neutral stubs so Nextor's boot
  input scan could complete. Issue #18 replaces the first three with cursor,
  joystick, trigger, and two-port mouse behavior; only paddle timing remains a
  neutral stub.
- **Root cause correction**: `FFE8h` is the documented V9938 `RG9SAV` mirror,
  not a disk flag, and the `80h`/`82h` NT-bit difference was not causal. The
  recurring `81F0h` path is GeoBench's open-source `msx_wait_tick` frame-pacing
  routine, proving that the application had already started; it was not an SD
  Mapper loader loop.
- **Screen 7 `CHGMOD` handoff**: GeoBench calls public `CHGMOD 7`, but the MSX1
  ROM previously rejected every mode above 3 and left V9938 R0=`00h` while the
  application populated bitmap VRAM. `CHGMOD 7` now scans for a live standard
  `CD` SUB-ROM signature as a V9938 guard without publishing `EXBRSA`, and a
  partial register setup produces R0=`0Ah` and maintains R8-R23 at the standard
  `FFE7h-FFF6h` shadow addresses without changing the MSX1 `WRTVDP` contract.
- **Rejected experiment removed**: forcing R1=`60h` before every disk handoff
  made the GeoBench bitmap visible but broke the ordinary Nextor text prompt by
  clearing M1. The guarded `CHGMOD 7` path now establishes R1 only when Screen 7
  is actually requested.
- **Verification**: `test-1983-geobench-sunrise` and
  `test-1983-geobench-sd` run the adjacent 1983 binary (`git 58e3590`) for
  2,502 frames, report R0=`0Ah`, R1=`62h`, `SCRMOD=7`, mapper
  `03h,02h,01h,00h`, and require the complete GeoBench desktop. The Sunrise
  run ends with slot `FCh`; the SD Mapper run ends with slot `A8h`.
- **Independent openMSX boot gate**: `test-openmsx-geobench-sunrise` uses a
  C-BIOS 0.29a open-source SUB-ROM, a 512 KiB mapper, the standard
  `SunriseIDE_Nextor` extension, and a fresh private copy of `GBMSX.IMG`. It
  observes the desktop segment mapped into page 1, R0=`0Ah`, R1=`62h`,
  `SCRMOD=7`, raw mapper readback `E3h,E2h,E1h,E0h`, active UI colours, and a
  byte-identical image after exit. The sampled PC may be in the desktop or a
  transient kernel/frame-pacing path and is retained as diagnostic output.
- **openMSX visual boundary**: enabling openMSX's
  `toggle_vdp_access_test` diagnostic identifies multiple too-fast VDP I/O
  sites in the current GeoBench binary and changes its rendered result. The
  committed test does not enable that helper. Full desktop-geometry parity in
  an unmodified openMSX run remains a real follow-up, not a hidden relaxation
  of the 1983 screenshot gate.
- **Issue #62 regression correction**: M3 keyboard work had made `BREAKX`
  execute `DI` without restoring the caller's interrupt state and had used the
  wrong matrix masks for STOP and Control. Nextor calls this entry immediately
  before an interrupt-driven `HALT`, so the disabled state stalled Sunrise and
  SD storage boot. `BREAKX` now preserves interrupt state and uses row 7 mask
  `10h` plus row 6 mask `02h`; STOP translation and repeat filtering use the
  same corrected matrix positions. The current local GeoBench image boots
  through Sunrise and SD Mapper in 1983 and through Sunrise in openMSX.
- **Embedded-page storage correction**: exposing the standalone interpreter's
  raw upper-page bytes allowed storage firmware probes to treat data near
  `7D00h-7FFFh`, including the `RBP1` descriptor, as ROM metadata. The combined
  ROM now stores a compact `RBC1`/ZX0 stream at `4000h`, leaves the probe-heavy
  upper tail erased, and reconstructs the exact verified interpreter into
  page-1 RAM only when BASIC is selected.
- **Ordinary cartridge correction**: a returning game/application `INIT` now
  suppresses automatic BASIC fallback. This prevents the delayed internal
  payload launch from replacing page 1 while cartridges such as Arkanoid keep
  running through hooks or interrupt-driven code. The regression gate requires
  a full gameplay board, not merely nonblank output, in both emulators.
- **Arkanoid sprite correction**: the first issue-62 gate was insufficient: it
  accepted R1=`E0h` and therefore missed the half-width paddle shown by the
  user. The compatible state is R1=`E2h` (16x16 sprites). `INITXT`/`INIT32`/
  `INITGRP` and the SET variants now preserve R1's sprite-size/magnification
  bits; `GSPSIZ` is a non-mutating query; `CALPAT` scales by 8/32; and 16x16
  `CLRSPR` attributes step pattern numbers by four while clearing the complete
  2 KiB pattern table. Both emulator gates require `E2h`, and openMSX captures
  on a completed video frame to avoid partial-raster screenshots.

### GeoBench pointer input status

GeoBench's open-source MSX input layer calls `GTSTCK 0` for cursor keys,
`GTSTCK 1` for joystick port 1, `GTTRIG 0/1` for activation, and, when mouse
input is enabled, `GTPAD 12/13/14` for signed relative motion. The old neutral
stubs therefore explained why every pointer path was immobile even though the
desktop rendered correctly.

PR #19 merged the `issue-18-mouse-support` implementation into `main`, which
now provides those public contracts. The
openMSX controller probe verifies direction values 0-8, an active connector,
Space, neutral triggers, both mouse request/cache groups, the openMSX
`01h,01h` empty-port coordinate signature, strict R7 port directions, and
seeded PSG R15 preservation. Mouse buttons continue through `GTTRIG`;
touch-panel, light-pen, explicit
trackball-detection, and paddle protocols remain outside this slice. `GICINI`
now initializes the PSG hardware and the full PLAY statement work area
(`QUEUES` -> queue table, `FRCNEW` = 255, cleared voice static data and voice
queues) atomically; its public entry enables interrupts on return while cold
boot uses a private DI body.

Current verification: 256 RainBIOS host tests and all 20 companion tests pass.
The dedicated embedded no-cartridge probes pass in 1983 and openMSX, including
the clean top-of-screen BASIC banner. The openMSX
controller, keyboard, cursor, VRAM, screen-mode, sprite, GRPPRT, text-control,
font, VDP-state, color, Screen 3, services (including the IM 1 controller
snapshot and the cassette/floppy motor auto-stops), and startup-audio probes
pass; Sunrise Nextor
and SD Mapper card A, card B, and dual-card paths pass; the adjacent 1983 PSG
and MSX component tests pass; both 2,502-frame 1983 GeoBench storage paths
render the Screen 7 desktop, and the openMSX Sunrise boot-state gate passes.
The automated openMSX mouse case verifies idle requests and
button lines; deterministic non-zero host-motion injection remains a test
harness gap rather than a committed test. A separate temporary focused-X11
endpoint probe injected host motion `(+80,-40)` into openMSX's mouse pluggable
and observed `GTPAD` request/X/Y bytes `FFh,28h,ECh`, exactly matching the
pluggable's 2:1 host scaling and RainBIOS's positive-right/positive-down BIOS
sign convention.

The earlier "1983 binary drift" explanation for a batch of failing tests was
tested and disproven: building the pinned `58e3590` revision reproduces the
same behavior as the local checkout, so the failures were stale test
expectations that drifted from the evolved firmware. A cleanup pass fixed the
cartridge/tape extension-stack SP validators, the payload probe addresses and
marker bytes, the BBC BASIC PC window and banner screenshot regions, the
external Arkano VDP R1 expectation, and the SD storage-boot page-2 slot
expectations. The former list of “five remaining failures” is stale: GeoBench
was subsequently user-confirmed through both Sunrise and SD Mapper with
RainBIOS, and issue #60 does not reinstate that list as current truth.

The current local `../geobench/QA/GBMSX.IMG` has SHA-256
`c826c90ee7eb02261ed1e8fa5c3600c1c86ac356ad3cba16a7f4c78bd0e22e60`.
Earlier handover text blamed this image for a storage stall; issue #62
disproved that explanation by booting the same bytes with a known-good
RainBIOS revision and bisecting the failure to `BREAKX`. Do not reinstate the
old `47d19058...` fixture claim without a separate provenance decision.

A follow-up isolated `Xvfb`/fluxbox run confirmed that XTest motion reaches
openMSX's X11 event layer, but openMSX 21.0 does not forward that synthetic
motion into the emulated mouse accumulator in this setup: `GTPAD` remains
`FFh,00h,00h`. Do not turn that path into a committed movement test. A future
non-zero automated probe needs an openMSX replay/device test double or a
headless 1983 input-injection interface rather than desktop automation.

The temporary emulator traces under `/tmp/opencode/1983-test` are no longer an
implementation input. Do not disassemble the opaque SD Mapper or system ROMs;
future investigation must remain at public interfaces and observable state.

## Floppy Test Design

The production disk shell and all test shells include the same shared driver.
Test-only ROMs add `H.RUNC` callbacks and terminal pass/failure labels; no test
behavior is compiled into `build/rainbios_nms8250_disk.rom`.

`tools/make_test_disk.py` creates deterministic 720 KiB raw images. Every
sector records its LBA and independent markers. A separate one-sided geometry
creates a deterministic record-not-found after one successful sector.
`tests/cartridges/disk_boot_sector.asm` is assembled at `C000h` and packed by
`tools/make_boot_disk.py` into a bootable fixture whose sector 0 carries the
`EBh` signature and a loader that reads sector 1 through `DSKIO`, verifies the
`RB01` marker, and spins at a labelled address.

Coverage includes:

- the production `H.RUNC` bootstrap: a bootable fixture reaches a pass marker in
  page-3 RAM (`test-1983-disk-boot-production`), and a missing or non-bootable
  medium returns to the interactive menu with the RainBIOS stack intact
  (`test-1983-disk-boot-fallback`);
- an empty SD Mapper alongside the production disk ROM leaves `H.PHYD`
  available, allowing a bootable floppy to reach the same pass marker
  (`test-1983-sd-empty-floppy`);

- the menu disk-boot path: a valid payload holds back the cold-boot auto-boot,
  the Space-key menu selects option 2, and the same fixture boots
  (`test-1983-disk-boot-menu`), while option 3 without an IDE cartridge returns
  to the menu (`test-1983-disk-menu-stub`);

- production `H.PHYD` and `DRVINF` registration;
- invalid drive, media ID, zero count, logical range, and buffer range;
- valid write rejection with a byte-identical read/write-mounted host image;
- an 11-sector read from LBA 8 through LBA 18, crossing side and track;
- a transfer crossing `BFFFh/C000h` with guard bytes;
- a direct seek to LBA 731;
- the final two logical sectors;
- no-media error 2 with zero completed sectors;
- record-not-found error 8 with exactly one completed sector;
- `GETDPB` error 12 for drives other than A;
- `GETDPB` publishing the exact 18-byte F9 DPB at `HL+1` while preserving the
  kernel drive byte, the FAT pointer, DE, and HL;
- `DSKCHG` error 12 for drives other than A;
- `DSKCHG` reporting a changed medium (`B=FFh`) on the first call after mount
  and an unchanged medium (`B=01h`) on the next call;
- `DSKCHG` reporting an unknown state (`B=00h`) without an error when the drive
  has no media, with `GETDPB` still publishing the DPB.

The 1983 emulator models controller state and raw media but idealizes motor,
seek, and per-byte DRQ timing. Passing emulator tests does not prove real
hardware timing or polarity.

A separate openMSX fault-injection fixture redirects the shared driver to a RAM
controller double at `#e000` (`FDC_BASE`), so a write watchpoint can program
WD2793 STATUS/TRACK/LINES between the driver's own reads. It covers error paths
a raw DSK image cannot reach: stuck seek IRQ, seek not-ready timeout and
not-ready, seek CRC, record-missing, verify, stuck read DRQ, stuck read IRQ,
early IRQ, read CRC, lost data, not-found, not-ready, and an inconsistent
status. A clean seek+read control runs first; each fault scenario asserts the
exact error code the driver must return, and any mismatch parks the cartridge
on a named `disk_fault_fail_*` loop that the probe turns into a FAIL report.
See `tests/openmsx/disk_fault_probe.tcl`.

## Build And Validation

Core requirements are GNU Make, a C99 compiler, Python 3.10+, Pillow 10+,
RASM 3.x, external `zmac`/`ld80`, and the pinned adjacent
`../bbcbasic-z80-msx` checkout. Every `make` and `make test` rebuilds that
checkout's payload from source. Override the legacy tools when they are not on
`PATH`:

```sh
make test BBC_ZMAC=/path/to/zmac BBC_LD80=/path/to/ld80
```

Run host validation:

```sh
make test
```

Run the focused 1983 disk suite:

```sh
make test-1983-disk-baseline
make test-1983-disk-boot
make test-1983-disk-read
make test-1983-disk-no-media
make test-1983-disk-dskchg-getdpb
make test-1983-disk-dskchg-no-media
make test-1983-disk-partial-error
make test-1983-disk-write-guard
make test-1983-nms8250-disk-rom
make test-1983-ide-boot
make test-1983-ide-menu
make test-1983-sd-boot
make test-1983-sd-menu
make test-1983-sd-empty-floppy
make test-1983-sd-empty-sunrise
make test-1983-nextor
make test-1983-nextor-sd
make test-1983-geobench-sunrise
make test-1983-geobench-sd
make test-1983-embedded-basic
make test-1983-msx2
make test-1983-msx2-subrom
make test-1983-msx2-subrom-services
make test-1983-msx2-subrom-cmdclock
```

The default emulator paths expect the adjacent open-source 1983 checkout:

```text
../1983/1983
../1983/1983-models.conf
```

The tested 1983 revision is recorded in `docs/REFERENCES.md`. Keep generated
GeoBench media identities explicit: the currently present changed local image
does not reproduce the accepted baseline and must not be used to attribute a
new failure to issue #60.

openMSX is installed as a Flatpak on the current workstation. Use:

```sh
make test-openmsx-audio test-openmsx-slots test-openmsx-expanded-slots \
  test-openmsx-mapper test-openmsx-services test-openmsx-vram \
  test-openmsx-keyboard \
  test-openmsx-controller \
  test-openmsx-embedded-basic test-openmsx-bbcbasic-quote \
  test-openmsx-payload-state test-openmsx-printer test-openmsx-gtpad \
  test-openmsx-msx2 \
  test-openmsx-msx2-subrom \
  test-openmsx-msx2-services \
  test-openmsx-msx2-cmdclock \
  test-openmsx-msx2-64k \
  test-openmsx-disk-fault test-openmsx-geobench-sunrise \
  OPENMSX='flatpak run org.openmsx.openMSX'
```

The Flatpak may print an ALSA sequencer permission warning; the headless test
reports still validate successfully. The Flatpak runs `-command` and `-script`
in separate Tcl interpreters, so the disk-fault runner generates a wrapper
script that defines `disk_fault_output`, `disk_fault_pass`, and
`disk_fault_fails` before sourcing the probe.

Before committing, also run:

```sh
git diff --check
```

## Roadmap

The authoritative roadmap is `docs/ROADMAP.md`. Its current high-level status
is:

| Milestone | Status | Remaining focus |
| --- | --- | --- |
| M0 ROM contract/build | Complete | Preserve deterministic build and truthful ABI metadata |
| M1 reset/slots/RAM/interrupts | In progress | Hardware cartridge test; disk ROM now adopts the motor-arm helper |
| M2 MSX1 display/console | In progress | Port-ordering and VRAM-boundary hardening done (`test-openmsx-vram` wrap/crossing/full-wraparound tests + interrupt-atomicity host tests); MSX2-only modes out of scope |
| M3 keyboard/PSG/basic devices | In progress | Printer calls and touch-panel GTPAD implemented (`test-openmsx-printer`, `test-openmsx-gtpad`); light-pen/trackball detection unemulable in openMSX; remaining: selectable frequency/locale |
| M4 cartridge compatibility | In progress | Payload-launch, cartridge-INIT, and page-2 INIT (mapper-style) arrangements gated; the redistributable compatibility corpus is deferred (TBD) |
| M5 MSX2 main BIOS/SUB-ROM | Complete | MSX2 main-ROM build with V9938 detection, EXBRSA, R8-R23 shadows, and SUBROM/EXTROM/CHKSLZ calling; RainBIOS SUB-ROM with Screens 5-8, palette, WRTVDP/VDPSTA, 16-bit VRAM, BLTVV/BLTVM/BLTMV transfers, and REDCLK/WRTCLK. 64 KiB VRAM validated (openMSX). Disk-file entries remain documented safe returns pending MSX2 storage boot |
| M6 completeness/optional components | In progress | Restore ROM headroom, finish embedded-payload regression/release gates, ABI gaps, broader disk functionality. Machine-readable component manifest (`components.json`) with `check-manifest`; lower-bank headroom size gate; all 21 callable BIOS stub entries gated by `test-1983-stubs`; DCOMPR/PSG clobber and flag contracts gated by `test-1983-abi-clobber`; function-key/text contracts gated by `test-1983-fnkey`; keyboard buffer contracts gated by `test-1983-kbd`; reproducible release bundle (`make release`) with SPDX 2.3 JSON export |
| M7 disk/IDE boot | In progress | Real DOS files, documented loader inputs, hardware validation |

## Recommended Next Work

The simpler boot logo leaves 3,247 bytes of page-0 headroom and passes the 1983
rendered-boot gate; the host suite now gates that headroom (the lower-bank last
non-`FF` byte must stay within `3000h`-`3600h`). Issue #62 now covers the
Arkanoid application-cartridge
gate, corrected keyboard/`BREAKX` semantics, compressed internal payload, and
GeoBench through 1983 Sunrise/SD plus openMSX Sunrise. The next embedded-payload
priority is to promote the existing external-payload graphics, cassette,
scrolling, and editing workloads to the internal mapping, then run the wider
storage-precedence matrix. Add the combined machine-readable component
manifest and resolve `BBC BASIC` branding before any public combined-ROM
release.

The GeoBench storage boot matrix is now automated. The next emulator
compatibility slice is to close the narrower openMSX rendering gap: reproduce
the current image's timing-sensitive VDP writes without enabling openMSX's
diagnostic helper, correct the responsible public-interface timing in the
appropriate open-source component, and then promote
`test-openmsx-geobench-sunrise` from a boot-state gate to the same exact
desktop-geometry gate used by both 1983 targets. Do not weaken the 1983 gates
or treat a timing-altered diagnostic run as acceptance evidence.

The M5 first slice now produces a distinct MSX2 main-ROM build
(`build/rainbios_msx2.rom`) via `make msx2-main-rom`. It is validated by
`test-1983-msx2` (1983 `msx2` model with the C-BIOS SUB-ROM: generation byte,
`EXBRSA=83h`, `RG8SAV=08h`, rendered boot frame) and `test-openmsx-msx2`
(openMSX V9938 fixture with the C-BIOS SUB-ROM). The M5 second slice adds the
standard SUB-ROM calling contract: `SUBROM` (`015Ch`), `EXTROM` (`015Fh`), and
`CHKSLZ` (`0162h`), validated by `test-1983-msx2-subrom` and
`test-openmsx-msx2-subrom` which call all three entries into a fixture SUB-ROM
and observe the called routine's effect, the republished `EXBRSA=83h`, and the
CHKSLZ carry. The M5 third slice adds the RainBIOS-owned SUB-ROM
(`make msx2-sub-rom`, `build/rainbios_msx2_sub.rom`), validated by
`test-1983-msx2-subrom-services` and `test-openmsx-msx2-services`, which call
`EXTROM` into `CHGMOD` Screens 5/6/7/8, the palette routines, and 16-bit
`WRTVRM`/`RDVRM` and check the observable VDP registers, work area, VRAM, and
palette. The M5 fourth slice adds the VDP command transfers and the clock:
`BLTVV` (LMMM), `BLTVM`/`BLTMV` (LMMC/LMCM CPU transfers), and
`REDCLK`/`WRTCLK`, validated by `test-1983-msx2-subrom-cmdclock` and
`test-openmsx-msx2-cmdclock`, which call `EXTROM` into all five entries and
check the copied VRAM bytes, the BLTMV header/pixels, and the RTC round trip.
The M5 fifth slice validates 64 KiB VRAM with `test-openmsx-msx2-64k`
(openMSX fixture with a 64 KiB V9938): CHGMOD Screens 5/8 and even-address
16-bit WRTVRM/RDVRM round trips across the full 64 KiB range. openMSX's
V9938 64 KiB model is known to mishandle CPU VRAM access to odd addresses
(openMSX issue #1157), so the 64 KiB gate exercises the even-address range;
the 128 KiB gates cover every address. The disk-file transfer entries
(`BLTVD`/`BLTDV`/`BLTMD`/`BLTDM`) remain documented safe returns: a real
implementation streams whole files through the DOS API (BDOS
open/create/set-DTA/random block I/O/close) and needs the machine to boot a
disk system such as Nextor. De-risking showed the RainBIOS MSX2 build does not
yet boot a cartridge/Nextor storage layer (the Sunrise cartridge is found by
the boot scan but does not take over on MSX2, unlike the NMS 8250 reference);
that storage boot is separate M6/M7 work and a prerequisite for these entries.
Screen 10-12 remains out of scope (V9958). Keep the guarded Screen 7 handoff
in the MSX1 ROM independent until the MSX2 build actually replaces it.

The immediate floppy priority is real NMS 8250-compatible hardware validation.
`docs/HARDWARE_TEST.md` is the concrete checklist; its primary risks are DRQ
service rate against the DD byte-cell window (item 13) and the LINES polarity
assumptions (items 2-3):

1. Confirm drive-select, motor, and side-register polarity.
2. Measure whether the ROM DRQ loop services a real double-density byte stream
   without lost data.
3. Confirm the approximately one-second spin-up delay and verified seek behavior.
4. Record the machine/controller revision and observed timing in the
   compatibility documentation.

The emulator-backed controller fault-injection slice is complete: the openMSX
test double exercises the timeout, status-mapping, and error-return branches
that raw DSK images cannot reach. Real hardware can now be used to confirm that
the injected polarity assumptions (LINES bit 6 as inverted IRQ) match the NMS
8250.

The read-only `DSKCHG`/`GETDPB`, floppy bootstrap, Sunrise/SD Mapper direct
bootstraps, and Sunrise/SD Mapper Nextor paths are complete. The SD path covers
single-card automatic selection, a dual-card A/B chooser, no-card menu fallback,
and coexistence with a bootable floppy. Nextor is the primary disk compatibility
target; broaden versions, adapters, and user-supplied media without downloading
or bundling a DOS. Other user-supplied systems, filesystem services, floppy
drive B, formatting, and writes remain separate milestones with their own tests
and provenance.

Broader project work can instead return to the unfinished M1-M4 items in
`docs/ROADMAP.md`; do not imply that floppy support makes the main BIOS complete.

## Key Files

| Path | Purpose |
| --- | --- |
| `src/main_msx1.asm` | Main BIOS, reset, slots, hooks, devices, console; `-DMSX2=1` builds the MSX2 variant |
| `src/main_msx2_sub.asm` | Self-contained MSX2 SUB-ROM: bitmap Screens 5-8, palette, WRTVDP/VDPSTA, 16-bit VRAM, block transfers, clock |
| `src/zx0_decompress.asm` | BSD-3-Clause forward ZX0 decoder used for boot/menu tables |
| `components.json` | Machine-readable component manifest (SPDX-style) for the combined ROM and siblings |
| `tests/test_component_manifest.py` | Host validation of the component manifest against built artifacts |
| `tests/cartridges/stub_probe.asm` | Probe for the BIOS stub safe-return contract |
| `tools/run_1983_stub_probe.py` | 1983 runner validating the stub probe markers |
| `tools/make_release_bundle.py` | Assembles the reproducible release bundle under `build/release/` |
| `tools/check_release_bundle.py` | Validates a release bundle against the build outputs |
| `tests/test_release_bundle.py` | Host validation of the produced release bundle |
| `tools/export_spdx.py` | Generates the SPDX 2.3 JSON document from `components.json` |
| `tests/test_spdx_export.py` | Host validation of the SPDX document against the manifest and ROMs |
| `tests/cartridges/abi_clobber_probe.asm` | Probe for DCOMPR flag/clobber and WRTPSG/RDPSG contracts |
| `tools/run_1983_abi_clobber_probe.py` | 1983 runner validating the ABI clobber probe markers |
| `tests/cartridges/fnkey_probe.asm` | Probe for POSIT/ERAFNK/DSPFNK/FNKSB/TOTEXT contracts |
| `tools/run_1983_fnkey_probe.py` | 1983 runner validating the function-key probe markers |
| `tests/cartridges/kbd_probe.asm` | Probe for CHSNS/CHGET/KILBUF and CHGCAP/CHGSND contracts |
| `tools/run_1983_kbd_probe.py` | 1983 runner validating the keyboard probe markers |
| `src/disk_nms8250_rom.asm` | Optional production disk-ROM shell |
| `src/disk_nms8250_driver.asm` | Shared read-only WD2793 PHYDIO implementation |
| `src/ide_nms8250_driver.asm` | Page-0 Sunrise ATA / SD Mapper SPI bootstrap |
| `docs/abi/main-bios.csv` | Truthful fixed-entry implementation status |
| `docs/abi/controllers.md` | Keyboard, joystick, trigger, and mouse contracts |
| `docs/abi/nms8250-disk-rom.md` | Disk component ABI and limitations |
| `docs/ROADMAP.md` | Authoritative milestone plan |
| `docs/EMBEDDED_BASIC.md` | Combined-ROM design, measured layout, boot policy, licensing, and release gates |
| `docs/DEVELOPMENT_POLICY.md` | Source-isolation and provenance rules |
| `docs/REFERENCES.md` | Exact implementation/test references |
| `docs/TESTING.md` | Host, openMSX, 1983, and external-input test matrix |
| `tools/make_test_disk.py` | Deterministic raw DSK fixture generator |
| `tools/make_ide_image.py` | Deterministic raw IDE boot fixture generator |
| `tools/run_1983_embedded_basic.py` | No-cartridge combined-ROM launch probe for 1983 |
| `tools/run_1983_msx2.py` | MSX2 main-ROM boot probe for 1983 (ID byte, EXBRSA, R8-R23) |
| `tools/run_1983_msx2_subrom.py` | MSX2 SUB-ROM calling probe for 1983 (SUBROM/EXTROM/CHKSLZ) |
| `tools/run_1983_msx2_subrom_services.py` | MSX2 SUB-ROM bitmap/palette/VRAM probe for 1983 |
| `tools/run_1983_msx2_cmdclock.py` | MSX2 SUB-ROM block-transfer/clock probe for 1983 |
| `tools/check_msx2_probe.py` | openMSX MSX2 boot report validator |
| `tools/check_msx2_subrom_probe.py` | openMSX MSX2 SUB-ROM calling report validator |
| `tools/check_msx2_services_probe.py` | openMSX MSX2 SUB-ROM services report validator |
| `tools/check_msx2_cmdclock_probe.py` | openMSX MSX2 SUB-ROM command/clock report validator |
| `tools/check_msx2_64k_probe.py` | openMSX MSX2 64 KiB VRAM report validator |
| `tests/openmsx/msx2_probe.tcl` | openMSX MSX2 boot state and screenshot probe |
| `tests/openmsx/msx2_subrom_probe.tcl` | openMSX MSX2 SUB-ROM calling probe |
| `tests/openmsx/msx2_services_probe.tcl` | openMSX MSX2 SUB-ROM bitmap/palette/VRAM probe |
| `tests/openmsx/msx2_cmdclock_probe.tcl` | openMSX MSX2 SUB-ROM block-transfer/clock probe |
| `tests/openmsx/RainBIOS_MSX2_CMDCLOCK.xml.in` | openMSX MSX2 SUB-ROM command/clock fixture |
| `tests/openmsx/msx2_64k_probe.tcl` | openMSX MSX2 64 KiB VRAM probe |
| `tests/openmsx/RainBIOS_MSX2_64K.xml.in` | openMSX MSX2 64 KiB VRAM fixture |
| `tests/cartridges/subrom_64k_probe.asm` | 64 KiB VRAM probe cartridge |
| `tests/openmsx/embedded_basic_probe.tcl` | No-cartridge combined-ROM launch and ROM-write probe for openMSX |
| `tools/check_nextor_screenshot.py` | Exact Nextor banner/prompt screenshot gate |
| `tools/check_controller_probe.py` | Controller and mouse report validator |
| `tools/check_geobench.py` | GeoBench runtime, mapper, Screen 7, and rendered-output validator |
| `tools/run_1983_geobench.py` | Shared Sunrise/SD Mapper GeoBench runner for 1983 |
| `tools/run_1983_disk_baseline.py` | Symbol-based disk integration runner |
| `tools/run_1983_disk_boot.py` | Production/fallback disk runner, including mixed SD Mapper configurations |
| `tools/run_1983_ide_boot.py` | Symbol-based Sunrise IDE integration runner |
| `tools/run_openmsx_disk_fault.py` | Symbol-based openMSX fault-injection runner |
| `tests/cartridges/disk_phydio_rom.asm` | General read and validation probe |
| `tests/cartridges/disk_no_media_rom.asm` | No-media probe |
| `tests/cartridges/disk_dskchg_getdpb_rom.asm` | DSKCHG/GETDPB probe with a mounted image |
| `tests/cartridges/disk_dskchg_no_media_rom.asm` | DSKCHG/GETDPB probe without media |
| `tests/cartridges/disk_partial_error_rom.asm` | Partial-transfer accounting probe |
| `tests/cartridges/disk_production_init_input.asm` | Production hook/drive registration probe |
| `tests/cartridges/disk_fault_rom.asm` | Controller fault-injection cartridge |
| `tests/openmsx/disk_fault_probe.tcl` | openMSX WD2793 controller test double |
| `tests/openmsx/controller_probe.tcl` | Public controller and mouse BIOS probe |
| `tests/openmsx/RainBIOS_M1_MAPPER.xml.in` | Memory-mapper sizing fixture |
| `tests/openmsx/mapper_probe.tcl` | Mapper segment-count and beyond-64 KiB probe |
| `tools/check_mapper_probe.py` | Mapper sizing report validator |
| `tests/openmsx/RainBIOS_GeoBench.xml.in` | Open-source V9938/mapper GeoBench machine fixture |
| `tests/openmsx/geobench_probe.tcl` | openMSX GeoBench state and screenshot probe |

## Engineering Notes

- Prefer the smallest correct change and keep production behavior separate from
  test callbacks.
- Use `apply_patch` for manual edits and preserve unrelated worktree changes.
- Keep generated artifacts under `build/`; do not commit ROMs, DSK images,
  generated emulator captures, or symbol files. Curated screenshots may live
  under `screenshots/` when their provenance and license sidecars are tracked.
- Update ABI and roadmap claims whenever behavior changes.
- Treat emulator implementation details as validation inputs, not code to copy.
- Do not add backward-compatibility behavior without a concrete shipped or
  persisted-data requirement.
