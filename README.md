![RainBIOS project artwork](rainbios.png)

# RainBIOS

RainBIOS is an independent, open-source firmware project for MSX and MSX2
computers. Its goal is binary-compatible system behavior without incorporating
proprietary source code, ROM data, fonts, logos, or other copyrighted assets.

Milestone M1 is in progress. The project builds a deliberately incomplete
32 KiB MSX1 main ROM with the standard entry-point layout and a small set of
low-level hardware routines. Cold boot now finds and tests 32 KiB of RAM in a
primary or secondary slot, maps it into pages 2 and 3, establishes the stack
and minimal MAIN-ROM work area, initializes primary/expanded slot control and
memory read/write
calls, enables an IM 1 VBlank path with standard hooks and `JIFFY`, and then
displays the boot UI. It also discovers public `AB` cartridge headers in
primary and secondary slots and can invoke page-1/page-2 `INIT` routines. The first Screen
0/1/2 initialization, Screen 0/1 text output, interrupt-driven international
keyboard scan, buffered character-input services, and descriptor-driven BBC
BASIC menu launch are present. Complete keyboard behavior, memory-mapper
allocation, broad cartridge compatibility, and most firmware services remain
pending.

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

The menu launches the separately built
[BBC BASIC for Z80 on MSX](https://github.com/salvogendut/bbcbasic-z80-msx)
payload when its versioned descriptor and requirements validate. Invalid
descriptors are not advertised or entered. The console, keyboard, timing, and
menu path pass the payload's interactive smoke test. Its open-source core and
new BSD-3-Clause MSX port can be distributed with RainBIOS while remaining a
distinct build artifact. The console-only cartridge is pinned by source
revision, size, and SHA-256 digest. The dependency, license, packaging, and
platform boundary are described in
[docs/BASIC_PAYLOAD.md](docs/BASIC_PAYLOAD.md).

An optional openMSX machine-definition check is available:

```sh
make test-openmsx
```

The M1 state probe places RAM in each non-ROM primary slot in turn, adds a
page-3-only decoy ahead of a valid 32 KiB candidate, and boots with RAM in
expanded slot 3-2. It checks the resulting page map, stack, work-area bounds,
slot tables, and hook initialization:

```sh
make test-openmsx-m1 OPENMSX='flatpak run org.openmsx.openMSX'
```

The M1D call probe verifies `RSLREG`, `WSLREG`, primary-slot `ENASLT`,
primary-slot `RDSLT`/`WRSLT`, and returning page-1/page-2 `CALSLT` calls,
including exact slot-map restoration:

```sh
make test-openmsx-slots OPENMSX='flatpak run org.openmsx.openMSX'
```

The expanded-slot probe independently checks `EXPTBL`/`SLTTBL`, the inverted
`FFFFh` selector, all four address pages, stack-safe restoration, and a
returning expanded `CALSLT`:

```sh
make test-openmsx-expanded-slots \
  OPENMSX='flatpak run org.openmsx.openMSX'
```

The interrupt/video service probe checks `CALLF`, `H.TIMI`, `JIFFY`,
`WRTVDP`, `INITXT`, `POSIT`, `CHPUT`, and `CLS` through their public entries:

```sh
make test-openmsx-services OPENMSX='flatpak run org.openmsx.openMSX'
```

The M3 keyboard probe uses physical openMSX matrix events to verify Shift+A,
raw `SNSMAT`, `CHSNS`, register-preserving `CHGET`, `KILBUF`, and an empty
blocking `CHGET` which wakes on Return:

```sh
make test-openmsx-keyboard OPENMSX='flatpak run org.openmsx.openMSX'
```

An original 16 KiB diagnostic cartridge proves cold-boot header discovery and
`INIT` transfer in openMSX:

```sh
make test-openmsx-cartridge OPENMSX='flatpak run org.openmsx.openMSX'
```

The corresponding secondary-slot test places the same cartridge in expanded
slot 2-2:

```sh
make test-openmsx-expanded-cartridge \
  OPENMSX='flatpak run org.openmsx.openMSX'
```

Both tests require the CPU to be executing from cartridge page 1, the correct
slot to be mapped, a cartridge-written RAM signature to exist, and the
rendered screen to remain nonblank. BBC BASIC descriptor discovery and menu
launch in expanded slot 2-2 are covered by:

```sh
make test-openmsx-expanded-bbcbasic-menu \
  OPENMSX='flatpak run org.openmsx.openMSX'
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
make test-1983-expanded
make test-1983-cartridge
```

The first target runs 120 NTSC frames and requires the M1 stack and
page-2/page-3 slot map. The expanded target repeats that check on the MSX2
layout and requires secondary selector `A0h`, with RAM in slot 3-2. The
cartridge target independently requires execution in the diagnostic
cartridge with slot 1 mapped into page 1. All validate the rendered screen and
write captures below `build/1983/`. Override
`EMULATOR_1983` or `MODELS_1983` when those sibling paths differ.

With the pinned BBC BASIC artifact already built, its complete editing,
language, error, clock, and timed-input sequence runs through Space, the
descriptor-aware menu, and option 1. The second target performs the same menu
transfer in 1983 and independently requires a visible banner and prompt:

```sh
make test-openmsx-bbcbasic OPENMSX='flatpak run org.openmsx.openMSX'
make test-1983-bbcbasic
```

The positive openMSX path also checks the payload slot, entry address, enabled
menu text, page map, stack, and entry registers. A corrupt-descriptor fixture
proves that claimed-but-invalid payloads fail closed without executing their
ordinary cartridge `INIT`:

```sh
make test-openmsx-payload-invalid \
    OPENMSX='flatpak run org.openmsx.openMSX'
```

Optional black-box tests cover the locally supplied 32 KiB Arkanoid and MSX
Diagnostics cartridges in both emulators:

```sh
make test-external-cartridges \
    OPENMSX='flatpak run org.openmsx.openMSX'
```

The ROMs are not part of RainBIOS. The defaults point to `Arkano.rom` and
`diag.rom` under the adjacent `1983/ROMS` directory; override `ARKANO_ROM` or
`MSX_DIAGNOSTICS_ROM` for another local layout. Exact identities, results,
and the limits of these smoke tests are recorded in
[docs/CARTRIDGE_COMPATIBILITY.md](docs/CARTRIDGE_COMPATIBILITY.md).

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
