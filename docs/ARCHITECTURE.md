# Architecture

RainBIOS keeps compatibility surfaces separate from their implementations so
that missing behavior is visible and testable.

## Firmware artifacts

| Artifact | Address range | Size | Purpose |
| --- | ---: | ---: | --- |
| MSX1 main ROM | `0000h-7FFFh` | 32 KiB | Lower-bank firmware/assets plus source-built page-1 BASIC payload |
| MSX2 main ROM | `0000h-7FFFh` | 32 KiB | MSX1 ABI plus MSX2 dispatch and initialization |
| MSX2 SUB-ROM | normally page 1 | 16 KiB | Extended VDP, clock, palette, and graphics ABI; first slices provide bitmap modes, palette, 16-bit VRAM, block transfers, and the clock |
| NMS 8250 disk ROM | `4000h-7FFFh` | 16 KiB | WD2793 PHYDIO read/write, DSKCHG/GETDPB, CHOICE/DSKFMT, FAT12 FS.LOAD/FS.DIR/FS.WRITE |
| Omega unified ROM | two `00000h-3FFFFh` banks | 512 KiB | JP1-selectable EEPROM image containing the MSX2 main ROM, Sub-ROM, and generic WD2793 disk ROM in Omega physical-slot order |

The main and SUB-ROM targets will share implementation modules but have
different fixed-address front ends.

The Omega image models four consecutive 64 KiB physical ROM regions in each
256 KiB JP1 bank: primary slot 0 followed by expanded-slot subslots 0, 1, and
3. The MSX2 main ROM starts at offset `00000h`, the Sub-ROM at `10000h`, and
the disk ROM at `34000h`, corresponding to page 1 of subslot 3. Unused bytes
are `FFh`, and the two banks are intentionally identical. `make omega` cooks
this image from freshly built RainBIOS components; host tests compare the
complete output byte-for-byte with that declared layout and independently
rebuild it to prove determinism.

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
adds the standard expanded-call selector fields for page-1/page-2 targets;
mapper kernels may patch the saved page-2/page-3 values, and RainBIOS consumes
those patched values during restoration. `CLPRIM`/`CLPRM1` occupy their
standard RAM addresses for primary-slot dispatch.

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
entered through its ordinary cartridge `INIT`. The built-in form is an `RBC1`
container in the MAIN-ROM's page 1. RainBIOS validates the container, copies
its ZX0 stream to high RAM, maps the contiguous RAM slot into page 1, expands
the exact standalone image there, and checks its `AB`/`RBP1` markers before
launch.

M1H performs a stackless pre-RAM expansion probe without changing the
reset-selected page-0/page-1 subslots. Once RAM is live it publishes
`EXPTBL`, the non-inverted selectors in `SLTTBL`, and the full `BIOSSLT`.
Expanded page-3 calls keep restoration state in registers until the old
secondary selector and primary map are both visible again. Standard memory
mappers receive the independent 64 KiB page baseline `3,2,1,0`; the discovered
full RAM slot is published in `RAMAD0` through `RAMAD3` for extension ROMs.
Sizing and allocating segments beyond that baseline remain pending.

The disk bring-up path invokes `H.STKE` after all extension `INIT` routines,
preserves a nonzero `DEVICE` kernel count, clears disk setup state, and normally
calls a non-empty `H.RUNC`. A standalone empty SD Mapper first leaves any
previously installed `H.PHYD` path a chance to boot drive A. The optional 16 KiB
NMS 8250 disk extension separates a small production ROM shell from a shared
WD2793 driver. Test shells include the same driver and add only `H.RUNC` probes.
Without a disk-system master, the production component installs `H.PHYD`,
publishes one drive, and installs its standalone bootstrap hook. When Nextor or
MSX-DOS is already active, it instead appends a legacy driver-table entry,
allocates an initialized F9 DPB, and preserves the master's hooks. This makes
the built-in NMS8250 floppy available after cartridge-backed Nextor devices.

The driver accepts drive A and 720 KiB `F9h` media, supporting both reads and
writes. It validates the complete logical-sector and RAM-buffer ranges before
I/O, converts LBAs to 80-track/two-side/nine-sector geometry, issues bounded
seek and single-sector read/write commands, advances across side and track
boundaries, and reports the number of fully completed sectors. `DSKCHG` drains
the WD2793 drive register and probes status without starting the motor to report
changed, unchanged, and unknown states; `GETDPB` publishes the fixed F9 DPB
without touching the controller. `CHOICE` (4019h) returns one format choice;
`DSKFMT` (401Ch) formats all 80 tracks via WD2793 Format Track (F0h).
Filesystem services provide FAT12 `FS.LOAD` (4025h), `FS.DIR` (4028h), and
`FS.WRITE` (402Bh). Integration probes cover reads, writes, no media, partial
record-not-found, write-protect rejection, DSKCHG/GETDPB, DSKFMT, and the
three FAT12 filesystem services.
See `docs/abi/nms8250-disk-rom.md` for the exact contract.

 M2A publishes the eight TMS9918 register shadows and current screen/table work
 variables. VDP register and address command pairs are protected from interrupt
 interleaving. Screen 0, Screen 1, and Screen 2 initialization use original
 RainBIOS tables and the project-owned font. A live standard `CD` SUB-ROM
 signature scan gates a narrow Screen 7 register handoff for compatibility
 testing on MSX2 hardware without publishing `EXBRSA`; that path alone also
 maintains the standardized V9938 R8-R23 shadows. This is not general SUB-ROM
 dispatch or a substitute for the M5 ROMs. The first console slice
 supports one-based cursor positioning, text name-table output, carriage
 return, line feed, wrapping, clearing, and scrolling in text and Graphics II
 modes; the complete control-character and cursor-presentation behavior remains
 pending.

The M5 first slice adds a distinct MSX2 main-ROM build (`rainbios_msx2.rom`)
assembled from the same `main_msx1.asm` source with `-DMSX2=1`. It sets the
`002Dh` generation byte to `01`, detects a live V9938 with the standard `CD`
SUB-ROM scan, publishes the discovered slot in `EXBRSA` (`FAF8h`), and loads a
V9938 R8-R23 shadow baseline. On that build the public `WRTVDP` dispatches
registers 8-23 through the extended-register shadow path in addition to the
TMS9918 R0-R7 contract.

The M5 second slice adds the standard SUB-ROM calling contract to the MSX2
build: `SUBROM` (`015Ch`), `EXTROM` (`015Fh`), and `CHKSLZ` (`0162h`). `EXTROM`
saves the caller's alternate registers and interrupt state, loads the slot
published in `EXBRSA` into IYH, and dispatches the routine at IX through the
mapper-compatible expanded `CALSLT` frame; the caller's normal registers reach
the SUB-ROM routine and its results are returned in them. `SUBROM` implements
the documented `push IX`/`jp SUBROM` wrapper that restores IX after the call.
`CHKSLZ` reuses the boot `CD` scan to republish the SUB-ROM slot in `EXBRSA`,
returning carry set when found. Dedicated 1983 and openMSX probes call all three
entries into a fixture SUB-ROM and observe the called routine's write, the
republished `EXBRSA`, and the carry result.

The M5 third slice adds the RainBIOS-owned SUB-ROM
(`src/main_msx2_sub.asm`, `build/rainbios_msx2_sub.rom`), a self-contained
16 KiB extended-VDP ROM with the standard `CD` header and the documented
fixed-entry layout. It implements `CHGMOD` for bitmap screens 5/6/7/8
(register programming, table-base work-area publication, and a full bitmap
clear through the VDP HMMV command), the palette calls
`INIPLT`/`RSTPLT`/`GETPLT`/`SETPLT` over the V9938 palette latch with a VRAM
palette store, `WRTVDP`/`VDPSTA`, and 16-bit `WRTVRM`/`RDVRM` covering the full
128 KiB range. Because it runs in its own slot, the SUB-ROM cannot call the
main BIOS; it performs VDP register writes, VRAM access, and the R0-R23 shadow
updates locally.

The M5 fourth slice adds the VDP command transfers and the real-time clock to
the SUB-ROM. `BLTVV` drives the LMMM command for VRAM-to-VRAM rectangle
copies and waits for the CE bit. `BLTVM`/`BLTMV` use the LMMC/LMCM CPU-transfer
handshake: the CPU waits for the status-2 TR bit, then writes each pixel
colour to R44 (`BLTVM`) or reads it from status 7 (`BLTMV`), packing pixels
per the current screen mode (SC5/SC7 two 4-bit, SC6 four 2-bit, SC8 one 8-bit
per byte). `REDCLK`/`WRTCLK` read and write the MSX2 clock registers through
the `B4h`/`B5h` ports, selecting the block through the RTC mode register.
The disk-file transfer entries (`BLTVD`/`BLTDV`/`BLTMD`/`BLTDM`) remain safe
returns: a real implementation streams whole files through the DOS API and
requires the machine to boot a disk system such as Nextor, which the MSX2
build does not yet do (see ROADMAP M5). Screen 10-12 is V9958-only and out of
scope. The MSX1 ROM keeps its `015F` compatibility return.

The M5 fifth slice validates the firmware on a 64 KiB VRAM V9938
(`test-openmsx-msx2-64k`) with an openMSX fixture, CHGMOD Screens 5/8, and
even-address 16-bit WRTVRM/RDVRM round trips across the full 64 KiB range.
openMSX's 64 KiB V9938 model is known to mishandle CPU VRAM access to odd
addresses (openMSX issue #1157), so the 64 KiB gate exercises the even-address
range; the 128 KiB gates cover every address.

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

M3C initializes the PSG GPIO directions and implements `GTSTCK` for cursor keys
and both joystick connectors plus `GTTRIG` for Space and both buttons on each
connector. Connector reads preserve the other connector and Kana LED state in
PSG R15. `GTPAD` selectors 12-19 perform the standard four-nibble mouse
transaction on either connector, cache signed relative motion in `PADX`/`PADY`,
and return buttons through `GTTRIG`. Touch panels, light pens, explicit
trackball detection, and `GTPDL` paddle timing remain unsupported. The public
contract and limitations are in `docs/abi/controllers.md`.

After that bootstrap, the ROM programs the TMS9918, uploads a converted
Graphics II logo and `RainBios booting...` notice, plays a short four-note PSG
motif, and keeps the completed logo visible for 60 VBlank frames (about one
second on NTSC or 1.2 seconds on PAL) before checking primary cartridges. A
Space press during that interval is buffered and remembered.
Immediately before the first conventional cartridge `INIT`, it replaces the
logo with a cleared 40-column console using light-yellow text on the same dark
blue used by the logo. Extension-ROM and storage diagnostics therefore start
on a clean text display; subsequent returning extensions retain earlier messages.
Cartridge initialization uses a temporary stack ending below `F100h`, while
publishing the standard `F380h` `HIMEM` boundary and pre-BASIC `MEMSIZ`/`STKTOP`
values expected by disk allocators. RainBIOS then runs `H.STKE` and any
non-empty `H.RUNC` hook. For the validated Nextor SD Mapper path, one mounted
card boots automatically, two mounted cards receive an A/B chooser, and no
mounted card returns to the RainBIOS boot-wait/menu path.
The original-BIOS keyboard decoder entry at `0D89h`, used directly by Nextor
2.1, reports the international layout without exposing that implementation as
a public BIOS contract.
Holding Space during startup switches to a Screen 1 menu headed `RainBIOS (c) salvogendut 2026`, which
reports whether the built-in payload is ready. `START BASIC` maps the payload
in page 1 and transfers to its descriptor entry under the contract in
`docs/abi/payload-v1.md`. `BOOT FLOPPY` invokes the optional disk ROM's drive-A
`H.RUNC` boot-sector hook. `BOOT IDE OR SD` maps a detected storage cartridge,
distinguishes Sunrise ATA from SD Mapper SPI registers, and applies the same
`C000h`/`C01Eh` loader contract when no standard cartridge boot path has taken
control.

If no external payload has been selected and each applicable storage path
returns cleanly, RainBIOS selects the built-in payload. A remembered Space from
the logo interval, or Space held through one final post-scan keyboard frame,
opens the options menu; otherwise BASIC launches automatically. A non-returning
or state-corrupting third-party cartridge remains outside this fallback guarantee.

The generated logo and menu tables are stored as ZX0 streams and expanded one
at a time into transient `C000h-D7FFh` RAM before VRAM upload. The public 2 KiB
font remains uncompressed because `CGTABL` points directly at it. The simpler
CC0 boot logo reduces its three compressed tables from 3,922 bytes to 917
bytes. The lower bank currently ends at `3350h`, leaving 3,247 bytes before the
hard `4000h` boundary.

## Embedded BASIC payload

Every normal RainBIOS build verifies the pinned companion checkout, runs its
tests and provenance audit, builds the 16 KiB payload from source, verifies its
digest, compresses it with ZX0, and stores the stream in an `RBC1` container at
`4000h`. The remainder of the upper bank is erased padding so storage firmware
does not interpret interpreter data as another ROM header. At BASIC launch the
exact image is reconstructed in page-1 RAM. The source-built artifact remains
usable as a standalone cartridge ROM. The imported interpreter source retains
its Zlib notice, while the independently written MSX platform code is
BSD-3-Clause.

The current port profile keeps the language core at `4400h-74C1h`, Graphics II
and platform services at `74C2h-7B75h`, and sequential cassette services at
`7B76h-7D19h`. Aligned state occupies `8000h-8339h`, and user memory begins at
`833Ah`. In the expanded RAM image its descriptor remains at `7FF0h-7FFFh`.
Guarded openMSX tests record zero writes to the ROM bank and verify the exact
header/descriptor after expansion; 1983 independently renders the prompt,
multicolour graphics frame, and cassette-loaded program. Combined-image release packaging must
preserve all component notices, and the non-transferable `BBC BASIC` branding
permission must be resolved by permission or rename. See
`docs/BASIC_PAYLOAD.md` and `docs/EMBEDDED_BASIC.md`.

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
  pinned BASIC payload supplies the end-to-end console/keyboard/timing
  workload, guarded against writes to its ROM. Dedicated openMSX and 1983
  probes also require the embedded no-cartridge path to reach its prompt and
  preserve the exact internal header, descriptor, slot map, and ROM write
  guard.
- The BBC BASIC graphics workload checks Graphics II mode registers, VRAM
  reference pixels and colours, cursor state, `POINT()` readback, zero ROM
  writes, and a separately rendered 1983 frame.
- Cassette probes decode public CAS data through the BIOS in openMSX and 1983,
  load and run a tokenized BBC BASIC program in 1983, and decode the header of
  a BBC BASIC SAVE waveform recorded by openMSX.
- Disk probes cover safe no-device returns, extension bootstrap context,
  production hook/drive registration, WD2793 read/write transfers, controller
  errors, write-protect rejection, DSKFMT formatting, and FAT12 FS.LOAD,
  FS.DIR, and FS.WRITE filesystem services in 1983.
- Positive and corrupt descriptor probes check menu state, fail-closed
  handling, payload mapping, and the exact non-returning entry contract.
- Hardware smoke tests will cover at least one MSX1 and one MSX2 machine before
  a compatibility milestone is released.
- Differential tests may compare public behavior against authorized reference
  firmware, but never compare implementation bytes or internal traces.
