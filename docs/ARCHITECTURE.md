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

The cold-boot bootstrap remains stackless until it has located RAM. The first
M1 slice preserves the reset-selected ROM mapping and requires complementary
write patterns to stick in both pages 2 and 3 of one primary-slot candidate.
It then establishes the stack, minimal MAIN-ROM work-area bounds, primary slot
tables, and empty hooks. Expanded-slot RAM and interrupts remain later M1
work.

M1B adds direct `RSLREG`/`WSLREG` access and primary-slot `ENASLT`. Because
switching page 0 removes the routine performing the switch, cold boot installs
a three-byte `OUT (A8h),A`/`RET` helper at `F380h`. Switching page 3 instead
pops the return address before replacing the page that contains the stack.
Expanded-slot IDs remain an explicit unsupported case.

M1C extends the RAM-resident helper block with page-0 read/restore and
write/restore operations. `RDSLT` and `WRSLT` handle pages 1–3 from visible
page-0 code and restore page 3 before touching its stack. These calls are
primary-slot-only until expanded-slot state is initialized.

M1D implements the primary-slot page-1/page-2 subset of `CALSLT`. IX supplies
the target and the high byte of IY supplies the slot ID. The old PPI map lives
in that call's page-3 stack frame while cartridge code runs, because the
target is permitted to replace the normal registers. If it returns, a page-0
continuation uses the alternate register set to restore the exact map while
preserving the target's normal register and flag results. Separate stack
frames also allow returning primary calls to nest.

M1E scans the public cartridge header locations at `4000h` and `8000h` in
each non-BIOS primary slot. A header beginning `41h,42h` with a nonzero
page-1/page-2 INIT pointer is entered through `CALSLT`. A returning INIT lets
the scan continue; a game may retain control. This is deliberately the first
simple primary-cartridge slice, not a claim of expanded-slot, mapper, or
full-service compatibility.

After that bootstrap, the ROM programs the TMS9918, uploads a converted
Graphics II logo and Space-key notice, plays a short four-note PSG motif, and
checks primary cartridges before polling the keyboard. Space switches to a
fixed Screen 1 boot-menu preview built from the project-owned partial font.
Menu selection and payload launch remain disabled until the remaining firmware
services and launch checks exist.

The 13,056-byte logo payload is temporarily embedded in the main ROM. It will
move to a compressed or separate, independently discoverable ROM before
main-BIOS space becomes constrained.

## Optional BASIC payload

The boot menu is intended to launch a separately built BBC BASIC for Z80
payload. The imported interpreter source retains its permissive upstream
notice, while new MSX platform code is BSD-3-Clause. RainBIOS will discover
and enter the payload only through the versioned descriptor in
`docs/abi/payload-v1.md`. Keeping the payload outside the 32 KiB main BIOS
also preserves ROM space and allows either project to be released
independently. The initial port profile keeps the 12,492-byte language core in
a 16 KiB page-1 payload ROM, places its aligned state at `8000h-8307h`, and
begins user memory at `8308h`. A guarded interactive openMSX test records zero
cartridge writes for the P1 cases, and 1983 independently renders the live
prompt. See `docs/BASIC_PAYLOAD.md`.

## Failure behavior during bring-up

Unimplemented ordinary calls currently return with carry set. Reset remains
in its boot UI, and interrupt vectors return safely. This makes the M1 ROM useful
for layout validation without suggesting that unsupported behavior is
compatible. Each such entry remains marked `stub` in the ABI table.

Unsupported calls may later emit structured diagnostics to an emulator debug
device in development builds. Release builds must not depend on emulator-only
hardware.

## Testing strategy

- Host-side structural tests validate ROM sizes, entry-point opcodes, metadata,
  and address bounds.
- Z80 unit tests will execute one BIOS call in a controlled memory/port model.
- Emulator integration tests boot a minimal, original test cartridge, inspect
  its RAM proof marker and execution state, and require a rendered nonblank
  frame in both openMSX and 1983.
- Hardware smoke tests will cover at least one MSX1 and one MSX2 machine before
  a compatibility milestone is released.
- Differential tests may compare public behavior against authorized reference
  firmware, but never compare implementation bytes or internal traces.
