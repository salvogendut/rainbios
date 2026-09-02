![RainBIOS project artwork](rainbios.png)

# RainBIOS

RainBIOS is an independent, open-source firmware project targeting MSX and
MSX2 computers. It aims for binary-compatible public behavior without using
proprietary source code, ROM data, disassembly, fonts, logos, or extracted
assets.

The repository currently builds source-based 32 KiB MSX1 and MSX2 main ROMs,
a 16 KiB MSX2 Sub-ROM, generic and Philips NMS 8250 WD2793 disk ROMs, and a
deterministic 512 KiB Omega unified EEPROM image. The main ROMs contain a
compressed, source-built Z80 BASIC payload which RainBIOS expands into page-1
RAM before launch.

RainBIOS implements a substantial, test-gated compatibility subset, but is not
yet a complete replacement firmware. It is intended for compatibility
development and controlled tests. See the [roadmap](docs/ROADMAP.md) and
[ABI status table](docs/abi/main-bios.csv) for exact implementation status.

## Key features

- deterministic 32 KiB MSX1 and MSX2 main ROMs with standard fixed entry
  points, plus a source-built MSX2 Sub-ROM;
- primary and expanded slot discovery, 32 KiB RAM selection, and a fixed
  64 KiB memory-mapper baseline;
- initial Screen 0/1/2, console, keyboard, interrupt, cassette, joystick, and
  standard two-port MSX mouse services, plus PSG output;
- public `AB` cartridge discovery and versioned RainBIOS payload descriptors;
- an embedded Z80 BASIC fallback, plus a boot menu whose `START BASIC`,
  `BOOT FLOPPY`, and `BOOT IDE OR SD` choices cover the built-in interpreter,
  an MSX-DOS-style drive-A boot sector, Sunrise IDE, and SD Mapper V2 media;
- an optional NMS 8250 WD2793 disk extension with PHYDIO read/write, DSKCHG,
  GETDPB, CHOICE/DSKFMT formatting, and FAT12 FS.LOAD/FS.DIR/FS.WRITE services;
- a deterministic 512 KiB Omega image with duplicated JP1 banks laid out in
  physical-slot order;
- reproducible release bundles with ROMs, symbols, SHA-256 sums, a provenance
  manifest, and an SPDX 2.3 software bill of materials;
- host, openMSX, and 1983 integration tests built from original fixtures.

## Current limitations

- some BIOS entries remain partial or documented safe stubs;
- MSX2 disk-file transfer commands remain safe returns, and Screens 10-12 are
  outside the current scope;
- selectable interrupt frequency and locale, a redistributable cartridge
  compatibility corpus, drive B, and additional floppy controllers remain
  pending;
- storage validation uses local, user-supplied Nextor and MSX-DOS media;
  RainBIOS does not bundle an operating system;
- real-hardware timing and compatibility validation remain in progress.

## Build

Requirements:

- GNU Make;
- a C99 compiler;
- Python 3.10 or newer;
- Pillow 10 or newer;
- [RASM](https://github.com/EdouardBERGE/rasm) 3.x on `PATH`;
- `zmac` and `ld80`, or paths supplied through `BBC_ZMAC` and `BBC_LD80`;
- the pinned
  [bbcbasic-z80-msx](https://github.com/salvogendut/bbcbasic-z80-msx)
  checkout beside this repository at `../bbcbasic-z80-msx`.

Build the default firmware set and run host validation:

```sh
make
make test
```

Every normal build verifies the companion checkout, runs its tests, rebuilds
its exact 16 KiB ROM from source, checks its pinned digest, compresses it with
ZX0, and embeds the compressed stream in an inert `RBC1` container. It never
falls back to an old prebuilt payload. The default outputs include
`build/rainbios_msx1.rom` and `build/rainbios_omega.rom`; the Omega dependency
chain also builds the MSX2 main ROM, Sub-ROM, and generic WD2793 disk ROM. The
independently usable exact payload and its compressed stream are copied to
`build/payload/bbcbasic_msx_console.rom` and
`build/payload/bbcbasic_msx_console.zx0`.

The five redistributable images bundled by 1983 are also versioned directly
under `build/`: the MSX2 main ROM, MSX2 Sub-ROM, generic and NMS8250 disk
ROMs, and the Omega unified image. Other generated build contents remain
ignored.

Override tools or the sibling path when needed:

```sh
make RASM=/path/to/rasm \
  BBC_ZMAC=/path/to/zmac BBC_LD80=/path/to/ld80 \
  BBC_BASIC_DIR=/path/to/bbcbasic-z80-msx
```

Build the optional NMS 8250 disk extension with:

```sh
make nms8250-disk-rom
```

Its output is `build/rainbios_nms8250_disk.rom`.

Build only the Omega unified EEPROM image and its source ROMs with:

```sh
make omega
```

The result, `build/rainbios_omega.rom`, is an exact 512 KiB image. Each
JP1-selectable 256 KiB half contains four 64 KiB physical-slot regions for
primary slot 0 and expanded slot 3 subslots 0, 1, and 3. RainBIOS MSX2 occupies
slot 0, the RainBIOS Sub-ROM begins slot 3-0, and the generic WD2793 disk ROM
occupies page 1 of slot 3-3. Both JP1 halves deliberately contain the same
redistributable firmware set.

Build and verify the reproducible release bundle with:

```sh
make release
make check-release
```

The versioned bundle is written below `build/release/` and contains all public
ROMs, symbol files, checksums, provenance metadata, and the SPDX SBOM.

## Quick validation

```sh
make test
make test-openmsx-boot OPENMSX='flatpak run org.openmsx.openMSX'
make test-openmsx-controller OPENMSX='flatpak run org.openmsx.openMSX'
make test-1983
```

The complete emulator matrix, optional local inputs, variable overrides, and
generated report locations are documented in [docs/TESTING.md](docs/TESTING.md).
Selected emulator images are collected under [screenshots/](screenshots/).

## Components

### Embedded Z80 BASIC

With no controlling external cartridge and no successful storage boot,
RainBIOS automatically launches the embedded
[BBC BASIC for Z80 on MSX](https://github.com/salvogendut/bbcbasic-z80-msx)
payload automatically after a bounded one-second logo interval and a final
non-blocking keyboard check. Pressing Space while the logo is visible, or
holding it through the final check, opens the options menu. A compatible
external payload can still override the embedded copy, and the standalone 16
KiB cartridge ROM remains available from the companion build. The dependency, memory layout,
boot policy, licensing analysis, and release gates are in
[docs/EMBEDDED_BASIC.md](docs/EMBEDDED_BASIC.md) and
[docs/BASIC_PAYLOAD.md](docs/BASIC_PAYLOAD.md); the exact handoff is in
[docs/abi/payload-v1.md](docs/abi/payload-v1.md). The code licenses permit this
combination, but public use of the `BBC BASIC` name still requires permission
or a rename before release.

The menu deliberately uses the generic `START BASIC` label. BASIC initializes
a clean 40-column text screen, and RainBIOS's `ERAFNK` service clears the
function-key row without moving the homed cursor, so the sign-on banner begins
at the top of the screen.

### Disk and storage boot

The optional NMS 8250 extension provides `PHYDIO` read and write, `DSKCHG`,
`GETDPB`, `CHOICE`/`DSKFMT` formatting, FAT12 `FS.LOAD`/`FS.DIR`/`FS.WRITE`,
the DOS1 communication-area/DPB state and resident `CALL 0005h` gate needed
by stock MSX-DOS 1, and a bounded `H.RUNC` boot-sector path. Storage
cartridges now enter
their standard `INIT`; an installed `H.RUNC` takes the normal cold-boot path,
including a validated Nextor prompt through Sunrise IDE. Menu option 3
retains RainBIOS's direct ATA/SPI fallback loader. Exact disk-ROM behavior is
documented in [docs/abi/nms8250-disk-rom.md](docs/abi/nms8250-disk-rom.md);
implementation status and remaining work are tracked under M7 in
[docs/ROADMAP.md](docs/ROADMAP.md).

In the menu, option 2 is labelled `BOOT FLOPPY` because it specifically
re-enters the drive-A disk-ROM hook. It does not imply that MSX-DOS is bundled.

RainBIOS does not bundle an operating system. Users can supply the DOS of their
choice on their own media; [Nextor](https://github.com/Konamiman/Nextor) is a
freely available option and is the currently validated system path.

## Documentation

- Design and status: [architecture](docs/ARCHITECTURE.md),
  [roadmap](docs/ROADMAP.md), and [main BIOS ABI](docs/abi/main-bios.csv).
- Public contracts: [slot calls](docs/abi/slot-calls.md),
  [keyboard](docs/abi/keyboard.md), [controllers](docs/abi/controllers.md),
  [payload v1](docs/abi/payload-v1.md), and [NMS 8250 disk
  ROM](docs/abi/nms8250-disk-rom.md).
- Validation: [testing guide](docs/TESTING.md),
  [cartridge compatibility](docs/CARTRIDGE_COMPATIBILITY.md), and
  [hardware checklist](docs/HARDWARE_TEST.md).
- Provenance: [development policy](docs/DEVELOPMENT_POLICY.md),
  [references](docs/REFERENCES.md), and [asset record](docs/ASSETS.md).

## Project boundaries

Public specifications and documented hardware behavior define the contract.
Compatible open-source references may be consulted only when their license and
scope are recorded. Proprietary BIOS source, ROM disassembly, extracted assets,
and rewrites of such material are not implementation inputs. Read
[docs/DEVELOPMENT_POLICY.md](docs/DEVELOPMENT_POLICY.md) before contributing.

## License

Original RainBIOS code and documentation are licensed under the BSD 3-Clause
License. The boot logo, project artwork, and selected screenshots are
CC0-1.0. The combined ROM also contains the Zlib-licensed interpreter core and
BSD-3-Clause MSX adapter from the companion repository. The vendored ZX0 code
is BSD-3-Clause, and the adapted C-BIOS openMSX machine fixture retains the
C-BIOS two-clause license. Full third-party and asset terms are in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), `LICENSES/`,
[docs/ASSETS.md](docs/ASSETS.md), and
[docs/EMBEDDED_BASIC.md](docs/EMBEDDED_BASIC.md).
