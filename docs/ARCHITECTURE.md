# Architecture

RainBIOS keeps compatibility surfaces separate from their implementations so
that missing behavior is visible and testable.

## Firmware artifacts

| Artifact | Address range | Size | Purpose |
| --- | ---: | ---: | --- |
| MSX1 main ROM | `0000h-7FFFh` | 32 KiB | Reset, slots, devices, BIOS ABI, cartridge startup |
| MSX2 main ROM | `0000h-7FFFh` | 32 KiB | MSX1 ABI plus MSX2 dispatch and initialization |
| MSX2 SUB-ROM | normally page 1 | 16 KiB | Extended VDP, clock, palette, and graphics ABI |

The main and SUB-ROM targets will share implementation modules but have
different fixed-address front ends.

## Layers

1. **ABI veneers** occupy standardized addresses and jump to named routines.
2. **Machine core** owns reset, slot enumeration, RAM selection, interrupts,
   hooks, and system variables.
3. **Device drivers** own VDP, PPI/keyboard, PSG, printer, cassette, and clock
   access.
4. **Services** implement console I/O, graphics, input, queues, and boot
   discovery.
5. **Compatibility tests** validate calls through their public entry points,
   not private labels.

Fixed entry points contain only jumps or documented metadata. Implementations
live after `0200h` during the bootstrap phase; this will be replaced with a
link-time section layout as modules grow.

The M0 cold-boot path is intentionally stackless. It programs the TMS9918,
uploads a converted Graphics II logo and Space-key notice, plays a short
four-note PSG motif, and polls the keyboard without assuming that RAM is
visible. Space switches to a fixed Screen 1 boot-menu preview built from the
project-owned partial font. Menu selection and payload launch remain disabled
until M1 establishes RAM, slots, a stack, and work areas.

The 13,056-byte logo payload is temporarily embedded in the main ROM. It will
move to a compressed or separate, independently discoverable ROM before
main-BIOS space becomes constrained.

## Optional BASIC payload

The boot menu is intended to launch a separately built BBC BASIC for Z80
payload. The imported interpreter source retains its permissive upstream
notice, while new MSX platform code is BSD-3-Clause. RainBIOS will discover
and enter the payload only through a documented descriptor after M1
initialization. Keeping the payload outside the 32 KiB main BIOS also preserves
ROM space and allows either project to be released independently. The initial
port profile keeps the 12,492-byte language core in a 16 KiB page-1 payload
ROM, places its aligned state at `8000h-8307h`, and begins user memory at
`8308h`. A guarded interactive openMSX test records zero cartridge writes for
the P1 cases, and 1983 independently renders the live prompt. See
`docs/BASIC_PAYLOAD.md`.

## Failure behavior during bring-up

Unimplemented ordinary calls currently return with carry set. Reset remains
in its boot UI, and interrupt vectors return safely. This makes the M0 ROM useful
for layout validation without suggesting that unsupported behavior is
compatible. Each such entry remains marked `stub` in the ABI table.

Before the first cartridge-boot milestone, unsupported calls will optionally
emit structured diagnostics to an emulator debug device in development builds.
Release builds must not depend on emulator-only hardware.

## Testing strategy

- Host-side structural tests validate ROM sizes, entry-point opcodes, metadata,
  and address bounds.
- Z80 unit tests will execute one BIOS call in a controlled memory/port model.
- Emulator integration tests will boot a minimal, original test cartridge and
  report results over a debug port or serial channel.
- Hardware smoke tests will cover at least one MSX1 and one MSX2 machine before
  a compatibility milestone is released.
- Differential tests may compare public behavior against authorized reference
  firmware, but never compare implementation bytes or internal traces.
