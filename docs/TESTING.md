<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Testing RainBIOS

RainBIOS validation is split between host-side structural tests, openMSX, the
adjacent open-source 1983 emulator, and optional black-box cartridge inputs.
Tests call public BIOS or extension-ROM entries wherever possible; test-only
fixtures keep pass/failure loops and host mailboxes outside production code.

## Prerequisites

The host suite requires the normal build dependencies listed in the README:
GNU Make, a C99 compiler, Python 3.10+, Pillow 10+, RASM 3.x, and externally
supplied `zmac`/`ld80`. The sibling `../bbcbasic-z80-msx` checkout is mandatory
because every normal main-ROM build tests and rebuilds it from source before
compressing and embedding its exact payload.

Optional integration suites require:

- openMSX, either installed directly or invoked as
  `flatpak run org.openmsx.openMSX`;
- the adjacent open-source 1983 checkout and model catalogue, defaulting to
  `../1983/1983` and `../1983/1983-models.conf`;
- the official open-source C-BIOS 0.29a SUB-ROM at
  `../cbios-0.29a/roms/cbios_sub.rom` for the current V9938 fixture;
- a local GeoBench `GBMSX.IMG` at `../geobench/QA/GBMSX.IMG`;
- local cartridge/storage ROMs for explicitly named black-box tests.

External ROMs and generated media are not RainBIOS release artifacts. Their
identities and permitted use are recorded in `docs/REFERENCES.md` and
`docs/CARTRIDGE_COMPATIBILITY.md`.

## Quick checks

Run host validation after every source change:

```sh
make test
```

Run a basic configuration, rendered-boot check, and boot-information matrix in
openMSX:

```sh
make test-openmsx test-openmsx-boot test-openmsx-boot-info \
  OPENMSX='flatpak run org.openmsx.openMSX'
```

Run the independent 1983 boot check:

```sh
make test-1983
```

Before committing, also run:

```sh
git diff --check
```

## Host targets

| Target | Coverage |
| --- | --- |
| `make test` | ROM layout, generated assets, ABI metadata, fixture construction, and report/state parsers |
| `make omega` | Builds the deterministic 512 KiB Omega EEPROM image and its MSX2 component ROMs |
| `make check-bbcbasic` | Pinned BBC BASIC source revision and dependency identity |
| `make check-bbcbasic-artifact` | Rebuilds and byte-verifies the pinned 16 KiB payload using the legacy assemblers |

`make test` first follows the same unconditional source-build path as `make`:
it runs the companion repository's tests and audit, rebuilds its ROM, checks
the pinned digest, and embeds a ZX0 stream from that exact copy in the main
ROM. Runtime probes verify the decompressed page-1 image.

## openMSX targets

Set the Flatpak command once when openMSX is not installed on `PATH`:

```sh
OPENMSX='flatpak run org.openmsx.openMSX'
```

Pass it to any target below as `OPENMSX="$OPENMSX"`.

### Boot, slots, and public services

| Target | Coverage |
| --- | --- |
| `test-openmsx` | Machine-definition configuration |
| `test-openmsx-boot` | Rendered boot artwork and nonblank output |
| `test-openmsx-boot-info` | Exact Graphics II RAM/VRAM/RTC overlay text on MSX1, 64 KiB and 128 KiB VRAM MSX2 machines, and an MSX2 machine without an RTC; also validates `MAPPER_SEGMENTS` and the published `MODE` size bits |
| `test-openmsx-options` | Held-Space, non-blocking menu route and Screen 1 rendering; host asset tests pin the title and three action labels |
| `test-openmsx-audio` | Non-silent startup-jingle PCM capture |
| `test-openmsx-m1` | Primary, split, decoy, and expanded RAM discovery layouts |
| `test-openmsx-slots` | Primary `RSLREG`, `WSLREG`, `ENASLT`, `RDSLT`, `WRSLT`, and returning `CALSLT` incl. page-0/page-3 primary targets |
| `test-openmsx-expanded-slots` | Expanded selectors, slot tables, all pages, restoration, and returning `CALSLT` incl. page-0 and page-3 different-slot targets |
| `test-openmsx-mapper` | Boot-time memory-mapper sizing and access to a segment beyond the fixed 64 KiB baseline |
| `test-openmsx-services` | Interrupt, hook, VDP, mode, console, scrolling, and `CLS` services |
| `test-openmsx-vram` | VRAM transfer calls with hardening: WRTVRM/RDVRM round trips, the 14-bit address wrap at `4000h` (WRAPTOP/BASE/ZERO), `FILVRM`/`LDIRVM`/`LDIRMV` crossing the boundary including a full double-wraparound fill (FULLWRAP), large crossing fill/copy (WRAPFILL/LDIRVMW/LDIRMVW), and port-ordering — an H.TIMI hook writes R0 every VBlank while 4000 `WRTVDP` calls to R7 complete, so R7 must stay clean (`ORDER`), the hook must have fired (`HOOKFIRE`), and the registers must remain readable (`VDPREG`) |
| `test-openmsx-keyboard` | Physical matrix input, translation, CAPS, buffering, blocking `CHGET`, Ctrl-STOP break, function-key display flags, `ERAFNK` row clearing/cursor preservation, text-mode forcing, auto-repeat, `INLIN`/`PINLIN`/`QINLIN`/`BEEP`, dead-key accents via the dedicated dead-key key plus the literal `"`/`'`/`` ` ``/`^` glyphs, the key click, the standard MSX cursor/edit-key codes through `CHGET`, and `SNSMAT` active-low row reads across the whole matrix |
| `test-openmsx-controller` | Cursor/joystick directions, triggers, mouse requests and cached axes on both ports, PSG R15 preservation, and no-paddle `GTPDL` |
| `test-openmsx-geobench-sunrise` | Sunrise/Nextor reaches the mapped GeoBench desktop application in active Screen 7 with the full desktop geometry (status bar, blue background plane, red UI accents) against the byte-verified unmodified image |
| `test-openmsx-msx2` | MSX2 main-ROM boot on a V9938 machine with the C-BIOS SUB-ROM: generation byte, `EXBRSA`, R8-R23 shadows, and rendered boot frame |
| `test-openmsx-msx2-subrom` | MSX2 SUB-ROM calling contract into a fixture SUB-ROM: `SUBROM`/`EXTROM`/`CHKSLZ` markers and the SUB-ROM spin PC |
| `test-openmsx-msx2-services` | RainBIOS SUB-ROM bitmap/palette/VRAM services: CHGMOD Screens 5/6/7/8, palette GETPLT, and 16-bit WRTVRM/RDVRM across all four Screen 5 `ACPAGE` values and both Screen 8 pages; physical VRAM markers are checked below and above `10000h` |
| `test-openmsx-msx2-cmdclock` | RainBIOS SUB-ROM VDP command transfers and clock: BLTVV/BLTVM VRAM results, BLTMV header/pixels, and REDCLK/WRTCLK round trip |
| `test-openmsx-msx2-64k` | RainBIOS MSX2 main ROM + SUB-ROM on a 64 KiB VRAM V9938: CHGMOD Screens 5/8 and even-address 16-bit WRTVRM/RDVRM round trips across the full 64 KiB range |
| `test-openmsx-font` | Printable project-owned font coverage |
| `test-openmsx-cls` | Screen 0/1/2/3 clearing, cursor state, and automatic BASIC fallback after the fixture cartridge INIT returns |

### Cartridges and payloads

| Target | Coverage |
| --- | --- |
| `test-openmsx-cartridge` | Original primary-slot `AB` cartridge discovery and `INIT` transfer, including the characterized INIT entry state (IX/DE = INIT pointer, A/B = slot, C = 0, IY = slot in the high byte, page-3 SP) cross-checked against the fixture's in-ROM snapshot |
| `test-openmsx-expanded-cartridge` | The same discovery path and INIT entry state in an expanded secondary slot |
| `test-openmsx-page2-cartridge` | Cartridge discovery and INIT entry state when the `INIT` routine lives in page 2 (the mapper-style arrangement): a 32 KiB fixture whose header at `4000h` points to `8000h`, forced onto slot 1 with an explicit `Normal4000` mapping |
| `test-1983-page2-cartridge` | The same 32 KiB page-2 INIT fixture on the independent 1983 emulator, validating the `D0h` slot map and page-2 loop PC |
| `test-openmsx-bbcbasic-menu` | Descriptor discovery and enabled menu state |
| `test-openmsx-expanded-bbcbasic-menu` | Descriptor discovery and launch from an expanded slot |
| `test-openmsx-bbcbasic` | Complete console/editing/language/error/timing workload |
| `test-openmsx-bbcbasic-graphics` | Graphics II drawing, readback, VRAM guards, and rendered output |
| `test-openmsx-payload-invalid` | Claimed-but-invalid descriptor fails closed without running `INIT` |
| `test-openmsx-embedded-basic` | No-cartridge automatic launch, internal header/descriptor, slot state, ROM write guard, arithmetic, and clean top-of-screen banner/prompt |
| `test-openmsx-payload-state` | Payload-launch register and work-area state at the descriptor entry: `SP=F380h`, A/BC/DE/HL/IX/IY zeroed, page 0 on the MAIN-ROM slot with pages 1-3 on contiguous RAM, empty key buffer, and a live `JIFFY` proving the interrupt source and IM1/EI are active |
| `test-openmsx-printer` | `LPTSTT` reports busy with no printer and ready once a printer is attached, and `LPTOUT` sends bytes through the data port with a clear carry, verified by the openMSX printer logger capturing the exact output |
| `test-openmsx-gtpad` | Touch-panel GTPAD selectors: returns 00h without a device and exercises the UPD7001 serial protocol against openMSX's touchpad without hanging; the touched-coordinate read is documented per the reference (headless openMSX cannot deliver host touch) |
| `test-openmsx-bbcbasic-quote` | The double-quote key pressed through the physical matrix reaches the BBC BASIC console line editor as a literal `"` (regression: the key used to latch the umlaut dead key and drop the character) |

### Cassette and disk

| Target | Coverage |
| --- | --- |
| `test-openmsx-tape` | Public cassette input calls against an original CAS fixture |
| `test-openmsx-bbcbasic-tape-save` | BBC BASIC SAVE waveform plus semantic header decoding |
| `test-openmsx-disk-fault` | WD2793 timeout/status fault injection through a RAM controller double |

## 1983 targets

The 1983 suite is fully headless and reports final CPU, slot, mapper, VDP, and
VRAM state. Override sibling paths when needed:

```sh
make test-1983 \
  EMULATOR_1983=/path/to/1983 \
  MODELS_1983=/path/to/1983-models.conf
```

### Boot, cartridge, BASIC, and cassette

| Target | Coverage |
| --- | --- |
| `test-1983` | MSX1 stack, RAM page map, and rendered boot frame |
| `test-1983-expanded` | NMS 8250 expanded-slot RAM layout |
| `test-1983-cartridge` | Primary diagnostic cartridge starts on a cleared Screen 0, prints yellow-on-logo-blue extension text without retained logo pixels, and preserves the cartridge entry contract |
| `test-1983-stubs` | BIOS stub safe-return contract: all 21 callable M6 stubs (SYNCHR/CHRGTR/OUTDO/GETYPR/INITIO/STRTMS/CNVCHR/LFTQ/PUTQ and the SCALXY..SCANL group plus CALBAS) set carry and preserve A/BC/DE/HL via CALSLT. NMI (0066h) is excluded as an interrupt return, not a callable stub |
| `test-1983-abi-clobber` | DCOMPR flag/carry contract (HL<DE, HL==DE, HL>DE) and BC preservation; WRTPSG/RDPSG round trip through the PSG ports |
| `test-1983-disk-abi` | Hook-dispatching disk baseline: PHYDIO/FORMAT/OUTDLP safe defaults return carry, ISFLIO returns A=0, FORMAT dispatches to an installed H_FORM hook, and GETVCP/GETVC2 return the voice-control-block pointers |
| `test-1983-gtpdl-clobber` | GTPDL paddle-read clobber contract: returns 0 with no paddle, preserves HL/IX/IY, and restores the PSG IOB (R15) |
| `test-1983-inifnk` | INIFNK fills FNKSTR with the ten default function-key strings (LIST..SCREEN 0) and leaves FNKFLG untouched |
| `test-1983-iscntc` | ISCNTC/CKCNTC break consumption: clears INTFLG and the key buffer and returns carry on a latched break (Ctrl-STOP/STOP), then carry clear on a subsequent call |
| `test-1983-chgmod` | CHGMOD screen-mode dispatch: modes 0-3 set SCRMOD; unsupported modes return carry set with SCRMOD untouched |
| `test-1983-keyint` | KEYINT VBlank bookkeeping: JIFFY advances by one per tick and STATFL holds the VDP status byte |
| `test-1983-embedded-basic-graphics` | Internal payload graphics workload: the embedded BASIC runs the Graphics II program in the payload RAM slot (FC) with R0=02/R1=E0 and a rendered three-colour pattern |
| `test-1983-embedded-basic-tape` | Internal payload cassette workload: the embedded BASIC LOAD/RUNs the tape fixture to PC=4400 in the same page-1 slot (F8) as the external path with non-blank VRAM |
| `test-1983-bbcbasic-scroll` | External scrolling text workload: the BBC BASIC PRINT loop completes (marker at F3C8), runs in the external slot (F4) on Screen 0 |
| `test-1983-embedded-basic-scroll` | Internal payload scrolling text workload: same PRINT loop completes with the marker, payload RAM slot (FC), identical VRAM to external |
| `test-1983-bbcbasic-edit` | External editing workload: Backspace/Delete corrections produce the 5Ah markers (external slot F4) |
| `test-1983-embedded-basic-edit` | Internal payload editing workload: same Backspace/Delete corrections produce the 5Ah markers (payload RAM slot FC) |
| `test-1983-fnkey` | POSIT cursor positioning, ERAFNK erase (CNSDFG=0, spaces), DSPFNK render (CNSDFG=FF, cursor to last row), FNKSB toggle, and TOTEXT text-mode refresh |
| `test-1983-kbd` | CHSNS empty/data reporting, CHGET char read with BC/DE/HL preserved and GETPNT advance, KILBUF buffer reset, CHGCAP Caps-Lock lamp on with BC/DE/HL preserved (PPI port-C bit 6 read back), and CHGSND click on/off switch with BC/DE/HL preserved |
| `check-release` | Reproducible release bundle: production ROMs, symbol files, component manifest, notices, and license texts under `build/release/`, with consistent `SHA256SUMS` and `RELEASE-NOTES.md` naming the source commit |
| `test_spdx_export` | SPDX 2.3 JSON document in the bundle: packages match the manifest, external components pin download locations, ROM files carry build-matching SHA-256 digests, and every element is described |
| `test-1983-bbcbasic` | BBC BASIC menu launch, banner, prompt, and runtime state |
| `test-1983-embedded-basic` | No-cartridge automatic launch of the embedded payload and clean top-of-screen banner/prompt |
| `test-1983-msx2` | MSX2 main-ROM boot on the `msx2` model with the C-BIOS SUB-ROM: generation byte, `EXBRSA=83h`, `RG8SAV=08h`, and rendered boot frame |
| `test-1983-msx2-subrom` | MSX2 SUB-ROM calling contract into a fixture SUB-ROM: CHKSLZ carry/EXBRSA, EXTROM write marker, SUBROM write marker, and the SUB-ROM spin PC |
| `test-1983-msx2-subrom-services` | RainBIOS SUB-ROM bitmap/palette/VRAM services: CHGMOD Screens 5/6/7/8 SCRMOD and table bases, palette SETPLT/GETPLT, and distinct WRTVRM/RDVRM round trips on all four Screen 5 `ACPAGE` values and both Screen 8 pages |
| `test-1983-msx2-subrom-cmdclock` | RainBIOS SUB-ROM VDP command transfers and clock: BLTVV/BLTVM VRAM results, BLTMV header/pixels, and REDCLK/WRTCLK round trip |
| `test-1983-bbcbasic-graphics` | Independently rendered Graphics II workload |
| `test-1983-tape` | Raw cassette fixture through public `TAP*` calls |
| `test-1983-bbcbasic-tape` | BBC BASIC cassette LOAD/RUN path |

### NMS 8250 disk extension

| Target | Coverage |
| --- | --- |
| `test-1983-disk-baseline` | Safe default disk-hook behavior |
| `test-1983-disk-boot` | Test disk-ROM bootstrap hook and preserve the scan when `INIT` claims `F300h` work RAM |
| `test-1983-disk-boot-production` | Production ROM clears the boot logo to a uniform Screen 0 and loads a two-sector boot fixture; the fixture captures the loader inputs (HL=DISKVE F323h, DE=ENAKRN 0) at the C000h+1Eh contract |
| `test-1983-disk-bdos` | Source-built DOS1 loader/system fixture on both RainBIOS MSX1 and MSX2: cold handoff on a cleared 40-column Screen 0 with the cursor homed, standard communication state, page-1 loading, `$$INIT`, the resident `CA06h` to `F37Dh` CALL-5 gate, version/login/default-drive calls, blocking buffered console input driven by scripted `OK` plus Return, and FCB Search First/Search Next over a root containing enough volume/deleted/LFN entries to exercise the 16-bit FS.DIR count before exact and wildcard matches |
| `test-1983-disk-write` | DSKIO write path: a fixture writes a deterministic 512-byte pattern to logical sector 2 and the host byte-verifies the image |
| `test-1983-disk-write-protect` | DSKIO write-protect: the same write against a read-only image reports error 3 and leaves the image untouched |
| `test-1983-disk-boot-fallback` | Empty/non-bootable media returns to the menu |
| `test-1983-disk-boot-menu` | Menu option 2 reaches the production bootstrap |
| `test-1983-disk-menu-stub` | Option 3 without a storage cartridge remains in the menu |
| `test-1983-disk-read` | Multi-sector, side/track, and boundary reads, and the motor-arm adoption: after the access the drive stays on until the RainBIOS IM 1 handler stops it (reaches `disk_phydio_motor_pass`) |
| `test-1983-disk-no-media` | No-media error behavior |
| `test-1983-disk-dskchg-getdpb` | Media-change state and DPB publication with media |
| `test-1983-disk-dskchg-no-media` | Media-change/DPB behavior without media |
| `test-1983-disk-write-guard` | Write rejection without changing a writable host image |
| `test-1983-disk-partial-error` | Exact completed-sector count on a later failure |
| `test-1983-nms8250-disk-rom` | Production INIT, hook, and drive registration |
| `test-1983-nms8250-disk-rom-slave` | Redistributable synthetic-master gate: preserved master hooks, appended legacy drive, initialized drive-C DPB, and safe 21-byte HIMEM/stack allocation |

### Sunrise IDE and SD Mapper V2

| Target | Coverage |
| --- | --- |
| `test-1983-ide-boot` | Sunrise ATA sector 0 boot plus a second-sector loader read |
| `test-1983-ide-menu` | Sunrise cartridge with no medium restores the pre-call map |
| `test-1983-sd-boot` | SD Mapper SPI initialization, sector 0 boot, and second CMD17 read |
| `test-1983-sd-menu` | SD Mapper with no card restores the pre-call map |
| `test-1983-sd-empty-floppy` | Empty SD Mapper does not suppress a bootable production floppy |
| `test-1983-sd-empty-sunrise` | Empty SD Mapper preserves a second Nextor kernel and Sunrise boot |
| `test-1983-nextor` | Sunrise `INIT`, `H.RUNC`, `NEXTOR.SYS`, and rendered `A:\>` prompt |
| `test-1983-nextor-sd` | SD Mapper one-card auto-boot plus dual-card chooser selection and matching Nextor prompts |
| `test-1983-geobench-sunrise` | The MSX2 ROM's standard generation identity remains compatible with Sunrise/Nextor and reaches the complete GeoBench Screen 7 desktop |
| `test-1983-geobench-sd` | SD Mapper/Nextor reaches the complete GeoBench Screen 7 desktop |
| `test-1983-nextor-internal-floppy` | An empty SD Mapper supplies Nextor while the source-built NMS8250 disk ROM registers its internal floppy; GeoBench boots from drive C with the complete source-built MSX2 firmware stack |

The storage tests default to local ROMs under `../1983/ROMS`. Override
`SUNRISE_ROM` or `SD_MAPPER_ROM` for another local layout. The ROMs remain
black-box inputs, but RainBIOS now follows their standard `AB` header `INIT`
and invokes a non-empty `H.RUNC` hook before falling back to its direct
controller loaders.

For an interactive check with the deterministic test media, launch either:

```sh
make run-1983-ide-boot
make run-1983-sd-boot
```

Press Space and then `3`. A successful second-sector read displays `IDE BOOT
PASS` or `SD BOOT PASS`; F12 exits 1983. Connecting an extension from 1983's
overlay resets the emulated machine, so these targets attach the controller and
media before startup. These fixtures validate RainBIOS's boot-sector contract;
they are not Nextor or MSX-DOS system images.

The explicit Nextor test uses local, non-redistributed system files and requires
`sfdisk`, `mkfs.fat`, and mtools `mcopy`. Its defaults are
`../1983/DOS/NEXTOR.SYS` and `../1983/DOS/COMMAND2.COM`; override `NEXTOR_SYS`
or `NEXTOR_COMMAND` as needed. The generated FAT16 image is mounted read-only:

```sh
make test-1983-nextor
make test-1983-nextor-sd
```

Success requires the Nextor 2.12 banner and rendered prompt area, not merely
transfer into an unknown boot sector. The SD target independently verifies
automatic boot from card A and card B when it is the only mounted card.
With both cards mounted, it selects B through RainBIOS's chooser and requires a
drive-B prompt.

These files are user-supplied test inputs, not RainBIOS dependencies or release
artifacts. RainBIOS neither downloads nor bundles a DOS; users may choose any
compatible system for their media. Nextor is freely available from its upstream
project and provides the currently validated integration path.

## GeoBench integration

Run the complete local matrix with:

```sh
make test-1983-geobench-sunrise test-1983-geobench-sd
make test-openmsx-geobench-sunrise \
  OPENMSX='flatpak run org.openmsx.openMSX'
```

The defaults are `../geobench/QA/GBMSX.IMG`, the Sunrise and SD Mapper ROMs
under `../1983/ROMS`, and the C-BIOS 0.29a open-source SUB-ROM named above.
These are local test inputs and are not release artifacts. Both 1983 targets
mount the image read-only and require R0=`0Ah`, R1=`62h`, `SCRMOD=7`, mapper
pages `03h,02h,01h,00h`, nonblank VRAM, and the full desktop geometry.

The openMSX target starts from a fresh private copy of the image and proves
that it remains byte-identical afterward. It requires the same Screen 7 and
mapper baseline, the GeoBench desktop segment mapped into page 1, and active
blue/red/white UI output. The sampled PC is recorded for diagnostics but is not
required to be in page 1 because a capture can legitimately interrupt the
desktop in a kernel or frame-pacing routine. The target deliberately does not
enable openMSX's `toggle_vdp_access_test` helper: that diagnostic identifies
timing-sensitive VDP access sites in the current GeoBench image and changes
the rendered result. Full desktop-geometry parity in an unmodified openMSX run
therefore remains a separate compatibility gap; the target is a boot-state
gate, while the two 1983 targets are desktop-render gates.

## External cartridge smoke tests

| Target | Coverage |
| --- | --- |
| `test-openmsx-external-arkano` | Arkanoid startup/render state in openMSX, including 16x16 R1=`E2h` and a completed-frame visual capture |
| `test-openmsx-external-diagnostics` | Diagnostics menu state and screenshot gate in openMSX |
| `test-openmsx-external-cartridges` | Both openMSX external fixtures |
| `test-1983-external-arkano` | Arkanoid startup/render state in 1983, including 16x16 R1=`E2h` and full-width paddle rendering |
| `test-1983-external-diagnostics` | Diagnostics menu in 1983 |
| `test-1983-external-diagnostics-screen3` | Keyboard-driven diagnostics Screen 3 path in 1983 |
| `test-1983-external-cartridges` | All three 1983 external paths |
| `test-external-cartridges` | Combined openMSX and 1983 external suites |

Run the local fixtures in both emulators with:

```sh
make test-external-cartridges \
  OPENMSX='flatpak run org.openmsx.openMSX'
```

Override `ARKANO_ROM` and `MSX_DIAGNOSTICS_ROM` when the local paths differ.
These targets are smoke tests, not full compatibility claims; see
`docs/CARTRIDGE_COMPATIBILITY.md`. The current openMSX diagnostics screenshot
gate is a documented known failure, while Arkanoid and all three 1983 paths
pass.

## Generated outputs

Generated files remain under `build/` and are not committed:

- `build/rainbios_msx1.rom` and `build/rainbios_msx1.sym`;
- `build/rainbios_msx2.rom`, `build/rainbios_msx2_sub.rom`, and their symbols;
- `build/rainbios_omega.rom`, the two-bank 512 KiB Omega EEPROM image;
- `build/rainbios_disk.rom` and its symbols;
- `build/rainbios_nms8250_disk.rom` and its symbols;
- `build/logo/` for converted artwork and palette previews;
- `build/openmsx/` for machine definitions, reports, audio, and screenshots;
- `build/1983/` for headless emulator screenshots;
- `build/disks/` and `build/cassettes/` for deterministic media fixtures;
- `build/cartridges/` for original test ROMs.

Deliberately selected project screenshots live under `screenshots/`; see
`screenshots/README.md` for the distinction between documentation images and
generated test captures.
