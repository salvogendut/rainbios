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

The active development branch is `1-missing-feature-floppies-support`. Before
starting new work, run `git status --short --branch`; do not discard unrelated
changes in a dirty worktree.

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
- a fixed 64 KiB memory-mapper baseline of segments `3,2,1,0` and publication
  of the discovered RAM slot through `RAMAD0`-`RAMAD3`;
- IM 1 VBlank handling, standard `H.KEYI`/`H.TIMI` hooks, keyboard buffering,
  and `JIFFY`;
- partial Screen 0/1/2 setup, text and Graphics II console output, scrolling,
  VRAM primitives, and project-owned printable glyphs;
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
- sets `DEVICE=1`, clears disk setup state, and invokes `H.RUNC` only when a
  disk ROM installed a standard `H.PHYD` hook.

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

The formal component contract is `docs/abi/nms8250-disk-rom.md`.

The disk ROM loads and runs an MSX-DOS-style boot sector but does not yet load a
real MSX-DOS kernel, and does not provide FAT or DOS services, formatting,
drive B, writes, non-NMS controllers, or real-hardware timing guarantees.
Destination buffers must remain within `8000h-EFFFh` while the extension
occupies page 1.

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
| M3 keyboard/PSG/basic devices | In progress | Repeat/locks/function keys, break, PSG init, controllers, printer classification |
| M4 cartridge compatibility | In progress | Startup-state contracts, mapper arrangements, redistributable compatibility corpus |
| M5 MSX2 main BIOS/SUB-ROM | Not started | Separate MSX2 ROMs, V9938, SUB-ROM calls, bitmap modes, palette, clock |
| M6 completeness/optional components | In progress | ABI gaps, behavior characterization, releases, and broader disk functionality |

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

After timing/error behavior is established, the next functional disk milestone
should be chosen explicitly. The read-only `DSKCHG` and `GETDPB` entries are
complete; the smallest useful progression from here is a minimal deterministic
boot-sector path. Filesystem services, drive B, formatting, and writes should
remain separate milestones with their own tests and provenance.

Broader project work can instead return to the unfinished M1-M4 items in
`docs/ROADMAP.md`; do not imply that floppy support makes the main BIOS complete.

## Key Files

| Path | Purpose |
| --- | --- |
| `src/main_msx1.asm` | Main BIOS, reset, slots, hooks, devices, console |
| `src/disk_nms8250_rom.asm` | Optional production disk-ROM shell |
| `src/disk_nms8250_driver.asm` | Shared read-only WD2793 PHYDIO implementation |
| `docs/abi/main-bios.csv` | Truthful fixed-entry implementation status |
| `docs/abi/nms8250-disk-rom.md` | Disk component ABI and limitations |
| `docs/ROADMAP.md` | Authoritative milestone plan |
| `docs/DEVELOPMENT_POLICY.md` | Source-isolation and provenance rules |
| `docs/REFERENCES.md` | Exact implementation/test references |
| `tools/make_test_disk.py` | Deterministic raw DSK fixture generator |
| `tools/run_1983_disk_baseline.py` | Symbol-based disk integration runner |
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
- Update ABI and roadmap claims whenever behavior changes.
- Treat emulator implementation details as validation inputs, not code to copy.
- Do not add backward-compatibility behavior without a concrete shipped or
  persisted-data requirement.
