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
| MSX1 main BIOS | `make` | `build/rainbios_msx1.rom` | Active, partial BIOS |
| NMS 8250 disk ROM | `make nms8250-disk-rom` | `build/rainbios_nms8250_disk.rom` | Read-only PHYDIO + DSKCHG/GETDPB + H.RUNC boot hook implemented |
| BBC BASIC payload | Built in sibling repository | `../bbcbasic-z80-msx/build/msx-console/bbcbasic_msx_console.rom` | Integrated optional payload |
| MSX2 main BIOS | Not yet available | Planned 32 KiB ROM | M5 pending |
| MSX2 SUB-ROM | Not yet available | Planned 16 KiB ROM | M5 pending |

The main BIOS and disk ROM remain separate components. `make all` builds only
the main BIOS; the model-specific disk ROM is explicitly optional.

## Current Main BIOS Status

The main BIOS currently provides:

- deterministic reset, 32 KiB RAM discovery, stack/work-area initialization,
  and a project-owned Graphics II boot UI;
- primary and expanded slot discovery and control, including `RDSLT`, `WRSLT`,
  `ENASLT`, page-1/page-2 `CALSLT`, and inline `CALLF`;
- exact normal-register inputs into cross-slot calls and exact restoration of
  primary/secondary mappings after returning calls;
- a mapper-compatible expanded `CALSLT` frame whose saved page-2/page-3
  selectors may be patched by a disk kernel before restoration;
- a fixed 64 KiB memory-mapper baseline of segments `3,2,1,0` and publication
  of the discovered RAM slot through `RAMAD0`-`RAMAD3`;
- IM 1 VBlank handling, standard `H.KEYI`/`H.TIMI` hooks, keyboard buffering,
  and `JIFFY`;
- partial Screen 0/1/2 setup, a guarded register-only V9938 Screen 7 handoff,
  text and Graphics II console output, scrolling, VRAM primitives, and
  project-owned printable glyphs;
- international keyboard scanning and partial character-input services;
- cassette motor, leader, framed-byte input/output, and BBC BASIC sequential
  cassette storage;
- cartridge discovery in primary and expanded slots, RainBIOS payload
  descriptors, and menu launch of the optional BBC BASIC payload;
- safe disk BIOS defaults, disk hook dispatch, extension `H.STKE` processing,
  and guarded `H.RUNC` disk bootstrap context.

The main BIOS is not a complete MSX BIOS. `docs/abi/main-bios.csv` is the source
of truth for which fixed entries are implemented, partial, or stubs.

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

## Nextor SD Mapper GeoBench Boot (Resolved)

GeoBench (`GBMSX.IMG`) now reaches its Screen 7 desktop under RainBIOS + SD
Mapper V2 in the 1983 emulator.

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
- **Verification**: an uninstrumented 2,501-frame run with the adjacent 1983
  binary (`git 58e3590`) and local GeoBench image reports `vdp_r0=0A`,
  `vdp_r1=62`, mapper `03,02,01,00`, and renders the GeoBench
  desktop. The final PC may be `81F2h` because the desktop intentionally waits
  there for the next V9938 retrace edge.

### GeoBench pointer input follow-up

GeoBench's open-source MSX input layer calls `GTSTCK 0` for cursor keys,
`GTSTCK 1` for joystick port 1, `GTTRIG 0/1` for activation, and, when mouse
input is enabled, `GTPAD 12/13/14` for signed relative motion. The old neutral
stubs therefore explained why every pointer path was immobile even though the
desktop rendered correctly.

Branch `issue-18-mouse-support` now provides those public contracts. The
openMSX controller probe verifies direction values 0-8, an active connector,
Space, neutral triggers, both mouse request/cache groups, the openMSX
`01h,01h` empty-port coordinate signature, strict R7 port directions, and
seeded PSG R15 preservation. Mouse buttons continue through `GTTRIG`;
touch-panel, light-pen, explicit
trackball-detection, and paddle protocols remain outside this slice. `GICINI`
now initializes the PSG hardware and controller baseline atomically; its public
entry enables interrupts on return while cold boot uses a private DI body. It
remains ABI-partial because PLAY statement work-area initialization is not part
of this issue.

Current verification on this branch: 139 host tests pass; the openMSX
controller, keyboard, services, and startup-audio probes pass; Sunrise Nextor
and SD Mapper card A, card B, and dual-card paths pass; the adjacent 1983 PSG
and MSX component tests pass; and an uninstrumented 2,502-frame GeoBench run
still renders the Screen 7 desktop with R0=`0Ah`, R1=`62h`, and mapper pages
`03,02,01,00`. The automated openMSX mouse case verifies idle requests and
button lines; deterministic non-zero host-motion injection remains a test
harness gap rather than a committed test. A separate temporary focused-X11
endpoint probe injected host motion `(+80,-40)` into openMSX's mouse pluggable
and observed `GTPAD` request/X/Y bytes `FFh,28h,ECh`, exactly matching the
pluggable's 2:1 host scaling and RainBIOS's positive-right/positive-down BIOS
sign convention.

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

Core requirements are GNU Make, Python 3.9+, Pillow 10+, and RASM 3.x.

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
```

The default emulator paths expect the adjacent open-source 1983 checkout:

```text
../1983/1983
../1983/1983-models.conf
```

The tested 1983 revision is recorded in `docs/REFERENCES.md`.

openMSX is installed as a Flatpak on the current workstation. Use:

```sh
make test-openmsx-slots test-openmsx-expanded-slots test-openmsx-services \
  test-openmsx-disk-fault \
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
| M1 reset/slots/RAM/interrupts | In progress | Page-0/page-3 `CALSLT`, mapper sizing/allocation, broader interrupt devices, hardware test |
| M2 MSX1 display/console | In progress | Remaining VDP, sprite, color, control-character, cursor, and boundary behavior |
| M3 keyboard/PSG/basic devices | In progress | Repeat/locks/function keys, break, advanced pointing devices, printer classification |
| M4 cartridge compatibility | In progress | Startup-state contracts, mapper arrangements, redistributable compatibility corpus |
| M5 MSX2 main BIOS/SUB-ROM | Not started | Separate MSX2 ROMs, V9938, SUB-ROM calls, bitmap modes, palette, clock |
| M6 completeness/optional components | In progress | ABI gaps, behavior characterization, releases, and broader disk functionality |
| M7 disk/IDE boot | In progress | Real DOS files, documented loader inputs, hardware validation |

## Recommended Next Work

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
| `src/main_msx1.asm` | Main BIOS, reset, slots, hooks, devices, console |
| `src/disk_nms8250_rom.asm` | Optional production disk-ROM shell |
| `src/disk_nms8250_driver.asm` | Shared read-only WD2793 PHYDIO implementation |
| `src/ide_nms8250_driver.asm` | Page-0 Sunrise ATA / SD Mapper SPI bootstrap |
| `docs/abi/main-bios.csv` | Truthful fixed-entry implementation status |
| `docs/abi/nms8250-disk-rom.md` | Disk component ABI and limitations |
| `docs/ROADMAP.md` | Authoritative milestone plan |
| `docs/DEVELOPMENT_POLICY.md` | Source-isolation and provenance rules |
| `docs/REFERENCES.md` | Exact implementation/test references |
| `docs/TESTING.md` | Host, openMSX, 1983, and external-input test matrix |
| `tools/make_test_disk.py` | Deterministic raw DSK fixture generator |
| `tools/make_ide_image.py` | Deterministic raw IDE boot fixture generator |
| `tools/check_nextor_screenshot.py` | Exact Nextor banner/prompt screenshot gate |
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

## Engineering Notes

- Prefer the smallest correct change and keep production behavior separate from
  test callbacks.
- Use `apply_patch` for manual edits and preserve unrelated worktree changes.
- Keep generated artifacts under `build/`; do not commit ROMs, DSK images,
  screenshots, or symbol files.
- `rainbios-old.png` is an untracked local backup and must not be committed or
  modified.
- Update ABI and roadmap claims whenever behavior changes.
- Treat emulator implementation details as validation inputs, not code to copy.
- Do not add backward-compatibility behavior without a concrete shipped or
  persisted-data requirement.
