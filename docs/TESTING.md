<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Testing RainBIOS

RainBIOS validation is split between host-side structural tests, openMSX, the
adjacent open-source 1983 emulator, and optional black-box cartridge inputs.
Tests call public BIOS or extension-ROM entries wherever possible; test-only
fixtures keep pass/failure loops and host mailboxes outside production code.

## Prerequisites

The host suite requires the normal build dependencies listed in the README:
GNU Make, Python 3.10+, Pillow 10+, and RASM 3.x.

Optional integration suites require:

- openMSX, either installed directly or invoked as
  `flatpak run org.openmsx.openMSX`;
- the adjacent open-source 1983 checkout and model catalogue, defaulting to
  `../1983/1983` and `../1983/1983-models.conf`;
- the sibling BBC BASIC checkout for payload integration targets;
- local cartridge/storage ROMs for explicitly named black-box tests.

External ROMs and generated media are not RainBIOS release artifacts. Their
identities and permitted use are recorded in `docs/REFERENCES.md` and
`docs/CARTRIDGE_COMPATIBILITY.md`.

## Quick checks

Run host validation after every source change:

```sh
make test
```

Run a basic configuration and rendered-boot check in openMSX:

```sh
make test-openmsx test-openmsx-boot \
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
| `make check-bbcbasic` | Pinned BBC BASIC source revision and dependency identity |
| `make check-bbcbasic-artifact` | Builds and byte-verifies the pinned 16 KiB payload using the legacy assemblers |

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
| `test-openmsx-options` | Space-key menu route and Screen 1 rendering |
| `test-openmsx-audio` | Non-silent startup-jingle PCM capture |
| `test-openmsx-m1` | Primary, split, decoy, and expanded RAM discovery layouts |
| `test-openmsx-slots` | Primary `RSLREG`, `WSLREG`, `ENASLT`, `RDSLT`, `WRSLT`, and returning `CALSLT` |
| `test-openmsx-expanded-slots` | Expanded selectors, slot tables, all pages, restoration, and returning `CALSLT` |
| `test-openmsx-services` | Interrupt, hook, VDP, mode, console, scrolling, and `CLS` services |
| `test-openmsx-keyboard` | Physical matrix input, translation, CAPS, buffering, and blocking `CHGET` |
| `test-openmsx-font` | Printable project-owned font coverage |
| `test-openmsx-cls` | Screen 0/1/2/3 clearing and cursor state |

### Cartridges and payloads

| Target | Coverage |
| --- | --- |
| `test-openmsx-cartridge` | Original primary-slot `AB` cartridge discovery and `INIT` transfer |
| `test-openmsx-expanded-cartridge` | The same discovery path in an expanded secondary slot |
| `test-openmsx-bbcbasic-menu` | Descriptor discovery and enabled menu state |
| `test-openmsx-expanded-bbcbasic-menu` | Descriptor discovery and launch from an expanded slot |
| `test-openmsx-bbcbasic` | Complete console/editing/language/error/timing workload |
| `test-openmsx-bbcbasic-graphics` | Graphics II drawing, readback, VRAM guards, and rendered output |
| `test-openmsx-payload-invalid` | Claimed-but-invalid descriptor fails closed without running `INIT` |

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
| `test-1983-cartridge` | Primary diagnostic cartridge startup smoke test |
| `test-1983-bbcbasic` | BBC BASIC menu launch, banner, prompt, and runtime state |
| `test-1983-bbcbasic-graphics` | Independently rendered Graphics II workload |
| `test-1983-tape` | Raw cassette fixture through public `TAP*` calls |
| `test-1983-bbcbasic-tape` | BBC BASIC cassette LOAD/RUN path |

### NMS 8250 disk extension

| Target | Coverage |
| --- | --- |
| `test-1983-disk-baseline` | Safe default disk-hook behavior |
| `test-1983-disk-boot` | Test disk-ROM bootstrap hook |
| `test-1983-disk-boot-production` | Production ROM loads a two-sector boot fixture |
| `test-1983-disk-boot-fallback` | Empty/non-bootable media returns to the menu |
| `test-1983-disk-boot-menu` | Menu option 2 reaches the production bootstrap |
| `test-1983-disk-menu-stub` | Option 3 without a storage cartridge remains in the menu |
| `test-1983-disk-read` | Multi-sector, side/track, and boundary reads |
| `test-1983-disk-no-media` | No-media error behavior |
| `test-1983-disk-dskchg-getdpb` | Media-change state and DPB publication with media |
| `test-1983-disk-dskchg-no-media` | Media-change/DPB behavior without media |
| `test-1983-disk-write-guard` | Write rejection without changing a writable host image |
| `test-1983-disk-partial-error` | Exact completed-sector count on a later failure |
| `test-1983-nms8250-disk-rom` | Production INIT, hook, and drive registration |

### Sunrise IDE and SD Mapper V2

| Target | Coverage |
| --- | --- |
| `test-1983-ide-boot` | Sunrise ATA sector 0 boot plus a second-sector loader read |
| `test-1983-ide-menu` | Sunrise cartridge with no medium restores the BIOS map |
| `test-1983-sd-boot` | SD Mapper SPI initialization, sector 0 boot, and second CMD17 read |
| `test-1983-sd-menu` | SD Mapper with no card restores the BIOS map |

The storage tests default to local ROMs under `../1983/ROMS`. Override
`SUNRISE_ROM` or `SD_MAPPER_ROM` for another local layout. The ROMs are used
only as black-box cartridge shells; RainBIOS does not enter their Nextor INIT.

For an interactive check with the deterministic test media, launch either:

```sh
make run-1983-ide-boot
make run-1983-sd-boot
```

Press Space and then `3`. A successful second-sector read displays `IDE BOOT
PASS` or `SD BOOT PASS`; F12 exits 1983. Connecting an extension from 1983's
overlay resets the emulated machine, so these targets attach the controller and
media before startup. These fixtures validate RainBIOS's boot-sector contract;
they are not Nextor or MSX-DOS system images. Real system media are not expected
to boot yet: after a valid signature transfers control, an unsupported loader
can restart the machine or corrupt the display while calling missing firmware
services.

## External cartridge smoke tests

| Target | Coverage |
| --- | --- |
| `test-openmsx-external-arkano` | Arkanoid startup/render state in openMSX |
| `test-openmsx-external-diagnostics` | Diagnostics menu state and screenshot gate in openMSX |
| `test-openmsx-external-cartridges` | Both openMSX external fixtures |
| `test-1983-external-arkano` | Arkanoid startup/render state in 1983 |
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
- `build/rainbios_nms8250_disk.rom` and its symbols;
- `build/logo/` for converted artwork and palette previews;
- `build/openmsx/` for machine definitions, reports, audio, and screenshots;
- `build/1983/` for headless emulator screenshots;
- `build/disks/` and `build/cassettes/` for deterministic media fixtures;
- `build/cartridges/` for original test ROMs.

Deliberately selected project screenshots live under `screenshots/`; see
`screenshots/README.md` for the distinction between documentation images and
generated test captures.
