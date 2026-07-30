![RainBIOS project artwork](rainbios.png)

# RainBIOS

RainBIOS is an independent, open-source firmware project for MSX and MSX2
computers. Its goal is binary-compatible system behavior without incorporating
proprietary source code, ROM data, fonts, logos, or other copyrighted assets.

Milestone M1 is in progress. The project builds a deliberately incomplete
32 KiB MSX1 main ROM with the standard entry-point layout and a small set of
low-level hardware routines. Cold boot now finds and tests 32 KiB of RAM in a
primary slot, maps it into pages 2 and 3, establishes the stack and minimal
MAIN-ROM work area, initializes primary-slot control and memory read/write
calls, and then displays the boot UI. Expanded-slot discovery, inter-slot
calls, interrupts, and cartridge startup remain pending.

## Build

Requirements:

- GNU Make
- Python 3.9 or newer
- Pillow 10 or newer
- [RASM](https://github.com/EdouardBERGE/rasm) 3.x on `PATH`

Build and validate the ROM:

```sh
make
make test
```

The output is `build/rainbios_msx1.rom`. Override the assembler when needed:

```sh
make RASM=/path/to/rasm
```

The build converts `src/logo.png` into legal TMS9918 Graphics II data, adds the
`PRESS SPACE TO SEE OPTIONS` notice, and writes a hardware-palette preview to
`build/logo/logo_preview.png`. Cold boot also plays a short PSG startup motif;
Space opens the early boot-menu preview. Asset provenance and release status
are tracked in
[docs/ASSETS.md](docs/ASSETS.md).

The menu is intended to launch the separately built
[BBC BASIC for Z80 on MSX](https://github.com/salvogendut/bbcbasic-z80-msx)
payload once slot/RAM initialization and the required firmware services
exist. Its open-source core and new BSD-3-Clause MSX port can be bundled with
RainBIOS while remaining a distinct build artifact. Its console-only
standalone cartridge now boots, publishes a versioned RainBIOS payload
descriptor, and is pinned by source revision, size, and SHA-256 digest. The
dependency, license, and platform boundary are described in
[docs/BASIC_PAYLOAD.md](docs/BASIC_PAYLOAD.md).

An optional openMSX machine-definition check is available:

```sh
make test-openmsx
```

The M1 state probe places RAM in each non-ROM primary slot in turn, then adds a
page-3-only decoy ahead of a valid 32 KiB candidate. It checks the resulting
page map, stack, work-area bounds, slot tables, and hook initialization:

```sh
make test-openmsx-m1 OPENMSX='flatpak run org.openmsx.openMSX'
```

The M1C call probe verifies `RSLREG`, `WSLREG`, primary-slot `ENASLT`, and
primary-slot `RDSLT`/`WRSLT`, including safe page-0 and page-3 operations:

```sh
make test-openmsx-slots OPENMSX='flatpak run org.openmsx.openMSX'
```

When openMSX is installed as a Flatpak, use:

```sh
make test-openmsx OPENMSX='flatpak run org.openmsx.openMSX'
```

To boot the ROM, capture the rendered logo, and validate that the screen is
nonblank:

```sh
make test-openmsx-boot OPENMSX='flatpak run org.openmsx.openMSX'
```

The captured hardware rendering is written to
`build/openmsx/rainbios_logo.png`.

Repository screenshots from supported emulators are collected in
[`screenshots/`](screenshots/).

The Space-key route and boot-menu rendering have a separate integration test:

```sh
make test-openmsx-options OPENMSX='flatpak run org.openmsx.openMSX'
```

The startup jingle can be captured and checked for non-silent PCM output:

```sh
make test-openmsx-audio OPENMSX='flatpak run org.openmsx.openMSX'
```

The adjacent `1983` emulator provides a second, fully headless boot check:

```sh
make test-1983
```

That target runs 120 NTSC frames, requires the M1 stack and page-2/page-3 slot
map, validates the rendered screen, and writes
`build/1983/rainbios_logo.ppm`. Override
`EMULATOR_1983` or `MODELS_1983` when those sibling paths differ.

The optional sibling BBC BASIC checkout can be checked against RainBIOS's
pinned revision with:

```sh
make check-bbcbasic
```

With the legacy assemblers available, `make check-bbcbasic-artifact` also
builds and byte-verifies the pinned 16 KiB console payload.

## Project boundaries

RainBIOS follows a source-isolated development policy. Do not use proprietary
BIOS source, ROM disassembly, extracted assets, or a rewrite of such material
as an implementation reference. See [docs/DEVELOPMENT_POLICY.md](docs/DEVELOPMENT_POLICY.md)
before contributing.

Public specifications and documented hardware behavior define the contract.
Open-source prior art may be consulted only when its license and the scope of
the consultation are recorded in [docs/REFERENCES.md](docs/REFERENCES.md).

## Direction

The compatibility target is split into independently testable artifacts:

- MSX1 32 KiB main BIOS ROM
- MSX2 32 KiB main BIOS ROM
- MSX2 16 KiB SUB-ROM
- optional, separately scoped BASIC and disk firmware components

See [docs/ROADMAP.md](docs/ROADMAP.md) for the implementation order and exit
criteria.

## License

Original RainBIOS code and documentation are licensed under the BSD 3-Clause
License.
The boot logo, project artwork, and selected screenshots are CC0-1.0. The
adapted C-BIOS openMSX machine fixture remains under the C-BIOS two-clause
license. Full third-party and asset terms are in `LICENSES/` and
`docs/ASSETS.md`.
