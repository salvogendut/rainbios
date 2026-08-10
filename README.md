![RainBIOS project artwork](rainbios.png)

# RainBIOS

RainBIOS is an independent, open-source firmware project targeting MSX and
MSX2 computers. It aims for binary-compatible public behavior without using
proprietary source code, ROM data, disassembly, fonts, logos, or extracted
assets.

The repository currently builds a deliberately incomplete 32 KiB MSX1 main
ROM whose upper 16 KiB contains a compressed, source-built Z80 BASIC payload.
RainBIOS expands the verified 16 KiB image into page-1 RAM before launch. It is
suitable for compatibility development and controlled tests, not as a
complete replacement firmware. See the [roadmap](docs/ROADMAP.md) and
[ABI status table](docs/abi/main-bios.csv) for exact implementation status.

## Key features

- deterministic 32 KiB MSX1 ROM with standard fixed entry points;
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
- host, openMSX, and 1983 integration tests built from original fixtures.

## Current limitations

- many BIOS entries remain partial or safe stubs;
- mapper allocation, broad cartridge compatibility, and several keyboard,
  touch-panel, paddle, printer, graphics, and filesystem services remain
  pending;
- Sunrise IDE and SD Mapper V2 compatibility boot a local Nextor 2.12 system
  image in 1983; the floppy extension also boots user-supplied, unmodified
  MSX-DOS 1 `MSXDOS.SYS` and `COMMAND.COM` files through its clean-room BDOS
  compatibility layer;
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

Build the main ROM and run host validation:

```sh
make
make test
```

Every normal build verifies the companion checkout, runs its tests, rebuilds
its exact 16 KiB ROM from source, checks its pinned digest, compresses it with
ZX0, and embeds the compressed stream in an inert `RBC1` container. It never
falls back to an old prebuilt payload. The main output is
`build/rainbios_msx1.rom`; the independently usable exact payload and its
compressed stream are copied to `build/payload/bbcbasic_msx_console.rom` and
`build/payload/bbcbasic_msx_console.zx0`. Override tools or the sibling path
when needed:

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
payload after a bounded Space-key menu window. A compatible external payload
can still override the embedded copy, and the standalone 16 KiB cartridge ROM
remains available from the companion build. The dependency, memory layout,
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
including a validated Nextor 2.12 prompt through Sunrise IDE. Menu option 3
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
