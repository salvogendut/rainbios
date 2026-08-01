![RainBIOS project artwork](rainbios.png)

# RainBIOS

RainBIOS is an independent, open-source firmware project targeting MSX and
MSX2 computers. It aims for binary-compatible public behavior without using
proprietary source code, ROM data, disassembly, fonts, logos, or extracted
assets.

The repository currently builds a deliberately incomplete 32 KiB MSX1 main
ROM. It is suitable for compatibility development and controlled tests, not as
a complete replacement firmware. See the [roadmap](docs/ROADMAP.md) and
[ABI status table](docs/abi/main-bios.csv) for exact implementation status.

## Key features

- deterministic 32 KiB MSX1 ROM with standard fixed entry points;
- primary and expanded slot discovery, 32 KiB RAM selection, and a fixed
  64 KiB memory-mapper baseline;
- initial Screen 0/1/2, console, keyboard, interrupt, and cassette services,
  plus PSG output;
- public `AB` cartridge discovery and versioned RainBIOS payload descriptors;
- a boot menu for BBC BASIC, an MSX-DOS-style floppy boot sector, Sunrise IDE,
  and SD Mapper V2 media;
- an optional read-only NMS 8250 WD2793 disk extension;
- host, openMSX, and 1983 integration tests built from original fixtures.

## Current limitations

- many BIOS entries remain partial or safe stubs;
- no MSX2 main ROM or SUB-ROM is built yet;
- mapper allocation, broad cartridge compatibility, and several keyboard,
  controller, printer, graphics, and filesystem services remain pending;
- Sunrise IDE compatibility boots a local Nextor 2.12 system image in 1983;
  a provenance-cleared MSX-DOS 1 system remains pending;
- real-hardware timing and compatibility validation remain in progress.

## Build

Requirements:

- GNU Make;
- Python 3.10 or newer;
- Pillow 10 or newer;
- [RASM](https://github.com/EdouardBERGE/rasm) 3.x on `PATH`.

Build the main ROM and run host validation:

```sh
make
make test
```

The main output is `build/rainbios_msx1.rom`. Override the assembler when
needed:

```sh
make RASM=/path/to/rasm
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
make test-1983
```

The complete emulator matrix, optional local inputs, variable overrides, and
generated report locations are documented in [docs/TESTING.md](docs/TESTING.md).
Selected emulator images are collected under [screenshots/](screenshots/).

## Optional components

### BBC BASIC

The Space-key menu can launch the separately built
[BBC BASIC for Z80 on MSX](https://github.com/salvogendut/bbcbasic-z80-msx)
payload after validating its versioned descriptor and service requirements.
The dependency, license boundary, memory layout, and release workflow are in
[docs/BASIC_PAYLOAD.md](docs/BASIC_PAYLOAD.md); the exact handoff is in
[docs/abi/payload-v1.md](docs/abi/payload-v1.md).

### Disk and storage boot

The optional NMS 8250 extension provides read-only `PHYDIO`, `DSKCHG`,
`GETDPB`, and a bounded `H.RUNC` boot-sector path. Storage cartridges now enter
their standard `INIT`; an installed `H.RUNC` takes the normal cold-boot path,
including a validated Nextor 2.12 prompt through Sunrise IDE. Menu option 3
retains RainBIOS's direct ATA/SPI fallback loader. Exact disk-ROM behavior is
documented in [docs/abi/nms8250-disk-rom.md](docs/abi/nms8250-disk-rom.md);
implementation status and remaining work are tracked under M7 in
[docs/ROADMAP.md](docs/ROADMAP.md).

RainBIOS does not bundle an operating system. Users can supply the DOS of their
choice on their own media; [Nextor](https://github.com/Konamiman/Nextor) is a
freely available option and is the currently validated system path.

## Documentation

- Design and status: [architecture](docs/ARCHITECTURE.md),
  [roadmap](docs/ROADMAP.md), and [main BIOS ABI](docs/abi/main-bios.csv).
- Public contracts: [slot calls](docs/abi/slot-calls.md),
  [keyboard](docs/abi/keyboard.md), [payload v1](docs/abi/payload-v1.md), and
  [NMS 8250 disk ROM](docs/abi/nms8250-disk-rom.md).
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
CC0-1.0. The adapted C-BIOS openMSX machine fixture retains the C-BIOS
two-clause license. Full third-party and asset terms are in `LICENSES/` and
[docs/ASSETS.md](docs/ASSETS.md).
