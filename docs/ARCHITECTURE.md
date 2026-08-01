# Architecture

RainBIOS keeps compatibility surfaces separate from their implementations so
that missing behavior is visible and testable.

## Firmware artifacts

| Artifact | Address range | Size | Purpose |
| --- | ---: | ---: | --- |
| MSX1 main ROM | `0000h-7FFFh` | 32 KiB | Reset, slots, devices, BIOS ABI, cartridge startup |
| MSX2 main ROM | `0000h-7FFFh` | 32 KiB | MSX1 ABI plus MSX2 dispatch and initialization |
| MSX2 SUB-ROM | normally page 1 | 16 KiB | Extended VDP, clock, palette, and graphics ABI |
| NMS 8250 disk ROM | `4000h-7FFFh` | 16 KiB | Optional read-only WD2793 PHYDIO + DSKCHG/GETDPB extension |

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
It then establishes the stack, minimal MAIN-ROM work-area bounds, slot tables,
and empty hooks. M1H extends the stackless probe to secondary-slot RAM.

M1B adds direct `RSLREG`/`WSLREG` access and primary-slot `ENASLT`. Because
switching page 0 removes the routine performing the switch, cold boot installs
a standard RAM primitive block at `F380h-F399h`; permanent page-0 `ENASLT`
uses a register-preserving stack trampoline. Switching page 3 instead pops the
return address before replacing the page that contains the stack. M1H extends
the same paths to expanded IDs and mirrors permanent selections in `SLTTBL`.

M1C uses standard `RDPRIM`/`WRPRIM` page-0 read/restore and write/restore
operations. `RDSLT` and `WRSLT` handle pages 1–3 from visible page-0 code and
restore page 3 before touching its stack. M1H restores both the primary map and
expanded selector around these calls.

M1D implements the primary-slot page-1/page-2 subset of `CALSLT`. IX supplies
the target and the high byte of IY supplies the slot ID. The old PPI map lives
in that call's page-3 stack frame while cartridge code runs, because the
target is permitted to replace the normal registers. Dispatch itself runs in
the alternate AF/BC/DE/HL banks so the target receives the caller's exact
normal inputs. If it returns, a page-0 continuation uses those alternate banks
to restore the exact map while preserving the target's normal register and
flag results. Separate stack frames also allow returning calls to nest. M1H
adds secondary-selector metadata to the frame for expanded page-1/page-2
targets; `CLPRIM`/`CLPRM1` occupy their standard RAM addresses for primary-slot
dispatch.

M1E scans the public cartridge header locations at `4000h` and `8000h` in
each non-BIOS slot. A header beginning `41h,42h` with a nonzero
page-1/page-2 INIT pointer is entered through `CALSLT`. A returning INIT lets
the scan continue; a game may retain control. This is deliberately the first
simple cartridge slice. M1H extends enumeration to all secondary slots;
bank-switched mapper compatibility remains separate work.

M1F enables IM 1 only after page 0 and the page-3 stack are stable. `KEYINT`
preserves the normal register set, runs `H.KEYI`, acknowledges VDP status,
runs `H.TIMI` on VBlank, and increments `JIFFY`. Standard five-byte hooks can
use the partial `CALLF`, which parses its inline slot and address through the
alternate register set and delegates page-1/page-2 targets to
`CALSLT`.

M1G recognizes a version-1 RainBIOS payload descriptor at `7FF0h` in normal
16 KiB page-1 cartridges. It validates the checksum, type, required-service
mask, entry, and RAM requirements before recording the first compatible slot
payload. A ROM which claims `RBP1` but fails validation is not
entered through its ordinary cartridge `INIT`.

M1H performs a stackless pre-RAM expansion probe without changing the
reset-selected page-0/page-1 subslots. Once RAM is live it publishes
`EXPTBL`, the non-inverted selectors in `SLTTBL`, and the full `BIOSSLT`.
Expanded page-3 calls keep restoration state in registers until the old
secondary selector and primary map are both visible again. Standard memory
mappers receive the independent 64 KiB page baseline `3,2,1,0`; the discovered
full RAM slot is published in `RAMAD0` through `RAMAD3` for extension ROMs.
Sizing and allocating segments beyond that baseline remain pending.

The disk bring-up path invokes `H.STKE` after all extension `INIT` routines,
then prepares `DEVICE`/disk setup state and calls `H.RUNC` when a disk ROM has
installed `H.PHYD`. The optional 16 KiB NMS 8250 disk extension separates a
small production ROM shell from a shared WD2793 driver. Test shells include the
same driver and add only `H.RUNC` probes. The production component installs
`H.PHYD`, publishes one drive, and returns from startup without test behavior.

The read-only driver accepts drive A and 720 KiB `F9h` media. It validates the
complete logical-sector and RAM-buffer ranges before I/O, converts LBAs to
80-track/two-side/nine-sector geometry, issues bounded seek and single-sector
read commands, advances across side and track boundaries, and reports the
number of fully completed sectors. `DSKCHG` drains the WD2793 drive register
and probes status without starting the motor to report changed, unchanged, and
unknown states; `GETDPB` publishes the fixed F9 DPB without touching the
controller. Integration probes cover LBA 8 through 18,
a direct seek to LBA 731, the final two sectors, a page-2/page-3 buffer crossing,
no media, partial record-not-found, write rejection on writable host media,
and `DSKCHG`/`GETDPB` behavior with and without a mounted image.
See `docs/abi/nms8250-disk-rom.md` for the exact contract.

M2A publishes the eight TMS9918 register shadows and current screen/table
work variables. VDP register and address command pairs are protected from
interrupt interleaving. Screen 0, Screen 1, and Screen 2 initialization use
original RainBIOS tables and the project-owned font. The first console slice
supports one-based cursor positioning, text name-table output, carriage
return, line feed, wrapping, clearing, and scrolling in text and Graphics II
modes; the complete control-character and cursor-presentation behavior remains
pending.

M3A scans international keyboard-matrix rows 0-8 once per VBlank. `OLDKEY` and
`NEWKEY` retain active-low row state, while new press edges are translated
into the standard 40-byte circular `KEYBUF`. `CHSNS` tests its read/write
pointers, `CHGET` blocks under `HALT` with interrupts enabled and consumes one
character, and `KILBUF` resets both pointers. Shift, Ctrl, CAPS lock (state
in `CAPST` at its published address, LED through PPI port C bit 6), printable
ASCII, and editing keys are supported; repeat, dead-key state, key click,
function-key expansion, and break handling remain separate work.

M3B implements the published `TAPION`, `TAPIN`, `TAPIOF`, `TAPOON`,
`TAPOUT`, `TAPOOF`, and `STMOTR` interface over PSG port A and PPI port C.
Input measures the leader and decodes framed, LSB-first bytes; output emits
long/short leaders and 1200-baud FSK. Standard CAS input is confirmed in
openMSX and 1983. Slow sampled-WAV replay remains a separate decoder-hardening
task.

After that bootstrap, the ROM programs the TMS9918, uploads a converted
Graphics II logo and Space-key notice, plays a short four-note PSG motif, and
checks primary cartridges before waiting through the buffered keyboard path.
Cartridge initialization uses a temporary `F300h` stack so disk kernels can
allocate below the standard `F380h` `HIMEM` boundary without overwriting the
BIOS return chain. RainBIOS then runs `H.STKE` and any non-empty `H.RUNC` hook.
The original-BIOS keyboard decoder entry at `0D89h`, used directly by Nextor
2.1, reports the international layout without exposing that implementation as
a public BIOS contract.
Space switches to a Screen 1 menu which reports whether BBC BASIC is ready.
When it is, option 1 maps the payload in page 1 and transfers to its descriptor
entry under the contract in `docs/abi/payload-v1.md`. Option 2 invokes the
optional disk ROM's `H.RUNC` boot-sector hook. Option 3 maps a detected storage
cartridge, distinguishes Sunrise ATA from SD Mapper SPI registers, and applies
the same `C000h`/`C01Eh` loader contract when no standard cartridge boot path
has taken control.

The 13,056-byte logo payload is temporarily embedded in the main ROM. It will
move to a compressed or separate, independently discoverable ROM before
main-BIOS space becomes constrained.

## Optional BASIC payload

The boot menu launches a separately built BBC BASIC for Z80 payload. The
imported interpreter source retains its permissive upstream notice, while new
MSX platform code is BSD-3-Clause. RainBIOS discovers and enters the payload
only through the versioned descriptor in
`docs/abi/payload-v1.md`. Keeping the payload outside the 32 KiB main BIOS
also preserves ROM space and allows either project to be released
independently. The current port profile keeps the 12,492-byte language core
and independently written Graphics II and sequential cassette adapters in a
16 KiB page-1 payload ROM. The cassette adapter ends at `794Eh`, aligned
state occupies `8000h-8321h`, and user memory begins at `8322h`. Guarded
openMSX tests record zero cartridge writes for the console and graphics
programs; 1983 independently renders the prompt, multicolour graphics frame,
and cassette-loaded program. See `docs/BASIC_PAYLOAD.md`.

## Failure behavior during bring-up

Unimplemented ordinary calls currently return with carry set. Reset remains
in its boot UI, while the NMI vector returns safely. This makes the M1 ROM
useful for layout validation without suggesting that unsupported behavior is
compatible. Each such entry remains marked `stub` in the ABI table.

Unsupported calls may later emit structured diagnostics to an emulator debug
device in development builds. Release builds must not depend on emulator-only
hardware.

## Testing strategy

The runnable target matrix and emulator setup are maintained in
`docs/TESTING.md`.

- Host-side structural tests validate ROM sizes, entry-point opcodes, metadata,
  and address bounds.
- Z80 unit tests will execute one BIOS call in a controlled memory/port model.
- Emulator integration tests boot a minimal, original test cartridge, inspect
  its RAM proof marker and execution state, and require a rendered nonblank
  frame in both openMSX and 1983.
- An openMSX service probe calls interrupt, VDP, mode, and console entries only
  through their fixed public addresses. Optional opaque-cartridge probes
  record the sampled PC and require the expected slot/video state plus a
  rendered frame in both openMSX and 1983.
- A physical-matrix keyboard probe checks translation and blocking input. The
  pinned BBC BASIC payload supplies the end-to-end console/keyboard/timing
  workload, guarded against writes to its ROM; 1983 separately requires its
  banner and prompt to be visibly rendered.
- The BBC BASIC graphics workload checks Graphics II mode registers, VRAM
  reference pixels and colours, cursor state, `POINT()` readback, zero ROM
  writes, and a separately rendered 1983 frame.
- Cassette probes decode public CAS data through the BIOS in openMSX and 1983,
  load and run a tokenized BBC BASIC program in 1983, and decode the header of
  a BBC BASIC SAVE waveform recorded by openMSX.
- Disk probes cover safe no-device returns, extension bootstrap context,
  production hook/drive registration, general read-only WD2793 transfers,
  controller errors, and host-image immutability through public `PHYDIO` in
  1983.
- Positive and corrupt descriptor probes check menu state, fail-closed
  handling, payload mapping, and the exact non-returning entry contract.
- Hardware smoke tests will cover at least one MSX1 and one MSX2 machine before
  a compatibility milestone is released.
- Differential tests may compare public behavior against authorized reference
  firmware, but never compare implementation bytes or internal traces.
