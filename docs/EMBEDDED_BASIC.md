<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Embedded Z80 BASIC feasibility and implementation plan

## Status and conclusion

This document assesses a future RainBIOS variant which contains the current
MSX Z80 BASIC payload in the same 32 KiB MAIN-ROM image. It is a design record,
not an implementation and not legal advice.

Tracking issue: [#24](https://github.com/salvogendut/rainbios/issues/24).

The short conclusion is:

- a traditional 32 KiB combined ROM is technically feasible;
- the lower 16 KiB must contain all RainBIOS executable code and compressed
  boot assets, while the upper 16 KiB contains the interpreter unchanged as a
  page-1 ROM image;
- the desired boot fallback is straightforward when a cartridge or storage
  bootstrap returns cleanly, but firmware cannot recover reliably from an
  arbitrary cartridge which hangs, crashes, or corrupts machine state;
- the code licenses permit redistribution in a combined image if their
  separate notices and conditions are preserved;
- the public name `BBC BASIC` is a separate branding issue. The current
  upstream repository says its permission to use that name is not
  transferable to forks. Obtain written permission before releasing a derived
  ROM under that name, or give the port a distinct name and retain factual
  provenance attribution.

The recommended release model is to keep the existing separate-ROM package
and add a second, optional combined output. Do not replace the separate
payload workflow until the combined image has equivalent emulator and
hardware coverage.

## Required behavior

The intended automatic boot policy is:

1. initialize the machine and give ordinary external cartridges their normal
   startup opportunity;
2. attempt an installed disk or IDE/SD boot path;
3. if no external cartridge takes control and all applicable storage paths
   return without booting, start the built-in interpreter;
4. allow Space during a bounded startup window to open the RainBIOS options
   menu instead of immediately following the automatic policy.

In particular:

- with no cartridges present, the built-in interpreter starts;
- with a working game or application cartridge, that cartridge keeps control;
- with a bootable Sunrise IDE or SD Mapper setup, its operating system boots;
- when an IDE/SD bootstrap reports failure by returning, the built-in
  interpreter starts;
- a bootable floppy should retain its existing opportunity before BASIC;
- an external, valid RainBIOS BASIC payload may override the built-in copy if
  the project deliberately adopts that precedence rule.

The last rule must be decided explicitly during implementation. Preferring an
external payload makes upgrades possible without replacing the system ROM and
is therefore the recommended policy.

## Current binary and address-space facts

### RainBIOS

The MAIN-ROM is already exactly 32 KiB and is mapped at `0000h-7FFFh`. In the
currently built image:

- executable code and small tables end before `1F06h`;
- the boot font and menu data begin at `1F06h`;
- raw logo data continues through approximately `6025h`;
- the rest of the image is padded with `FFh` through `7FFFh`.

This leaves about 8 KiB unused at the end, which is not enough to append a
16 KiB interpreter. More importantly, appending a third 16 KiB page would not
produce a standard MAIN-ROM mapping. A Z80 has only the `0000h-7FFFh` BIOS
window available for the conventional 32 KiB MAIN-ROM.

The useful fact is that RainBIOS's executable code is in page 0. Most of the
current page-1 occupation is raw boot artwork, not firmware routines. If all
firmware code and boot data can be kept below `4000h`, page 1 can be dedicated
to the interpreter, matching the traditional MSX BIOS-plus-BASIC layout.

Subsequent BIOS development will increase page-0 use. The combined target must
therefore enforce the `4000h` boundary at link time rather than relying on the
addresses recorded here.

### Interpreter payload

The current MSX payload is a deterministic 16,384-byte normal cartridge ROM
designed for `4000h-7FFFh`. Its relevant layout is:

| Address | Purpose |
| --- | --- |
| `4000h-4012h` | ordinary `AB` cartridge header and entry veneer |
| `4013h-423Ah` | MSX console adapter |
| `4400h-74C1h` | preserved Z80 language core |
| `74C2h-7B75h` | graphics and remaining platform services |
| `7B76h-7D19h` | cassette storage adapter |
| `7FF0h-7FFFh` | RainBIOS `RBP1` descriptor |
| `8000h-82FFh` | interpreter fixed RAM |
| `8300h-8339h` | MSX adapter state |
| `833Ah-F2FFh` | initial program and dynamic-memory area |

It already executes safely from ROM in the page-1 cartridge window and has
tests which reject writes to that window. This is the central reason the
combined-ROM design is practical: the upper half can contain the same tested
payload bytes instead of a new relocated interpreter build.

At the time of this assessment, the sibling checkout is at commit
`34540d468d3f39da0d283da49c0feb2dab9a1313`. Its built ROM has SHA-256
`82b0ff999ae85d4105875ad6e8c5a33f37662fbcde1642044c56a430de9759a6`.
RainBIOS's dependency lock still records the earlier commit `6ddaa57...` and
artifact digest `29691e2a...`. Reconcile and review that update before using a
payload in a combined release.

## Recommended 32 KiB layout

The proposed combined output is:

| ROM offset / CPU address | Contents | Licensing |
| --- | --- | --- |
| `0000h-3FFFh` | RainBIOS jump table, firmware, compressed boot assets, decompressor | BSD-3-Clause code and CC0-1.0 boot assets |
| `4000h-7FFFh` | pinned MSX interpreter payload | Zlib core plus BSD-3-Clause MSX adapter |

Suggested artifact names are:

- `rainbios_msx1.rom`: the existing BIOS-only output;
- `rainbios_msx1_basic.rom`: the optional combined output;
- `bbcbasic_msx_console.rom`: the independently usable payload, retained in
  the companion project and release bundle.

The combined build should place the exact, validated 16 KiB payload at offset
`4000h`. It should not extract selected modules from a previously built ROM or
silently patch the payload. Build the companion project from its pinned source,
verify its digest, then include the whole artifact.

### Boot-asset compaction

Current generated boot assets total 15,872 bytes:

- 2,048-byte font;
- two 768-byte menu name tables;
- 32-byte menu colour table;
- 6,144-byte logo pattern table;
- 768-byte logo name table;
- 6,144-byte logo colour table.

As a feasibility check, generic compression reduces the concatenated generated
assets to roughly 4.8 KiB. That format is not proposed for the Z80 decoder, but
the measurement shows ample repetition in the data. A small Z80-oriented
decoder should stream directly from ROM to VRAM so the full uncompressed image
never needs to occupy RAM.

The implementation should evaluate at least:

- a clearly licensed ZX0-style or equivalent Z80 decompressor;
- a project-owned PackBits/RLE format specialized for pattern and colour
  tables;
- tile deduplication for the boot logo and menu tables.

Whichever format is selected must have a host-side round-trip test and a
rendered emulator test. Its license and exact upstream revision, if any, must
be recorded before code is imported. The build must fail if the lower-half
image reaches `4000h`; silently truncating or overlapping the interpreter is
unacceptable.

Compressing all generated boot assets is preferable to compressing only the
logo. It leaves several KiB of page-0 growth room, whereas compressing only the
large logo tables leaves little margin for the decompressor and unfinished
BIOS work. Even after compaction, committing the entire upper half to BASIC
places a permanent growth ceiling on page-0 firmware. This is the principal
long-term technical cost of a traditional combined ROM.

## Internal launch design

The built-in payload occupies the MAIN-ROM's own page 1, so it need not be
discovered as an external cartridge. The launcher can reuse the existing
version-1 entry contract:

- page 0 remains mapped to the RainBIOS slot;
- page 1 maps the same slot and contains the interpreter;
- pages 2 and 3 remain the contiguous RAM selected at cold boot;
- `SP=F380h`;
- normal and index registers are initialized as documented;
- interrupts are enabled in IM 1;
- control transfers to `4010h` without a return address.

The implementation should still validate the internal descriptor and checksum
at `7FF0h`. Treating an internal build error as impossible would turn a corrupt
ROM into an uncontrolled jump. For the combined target, the internal payload
slot is `BIOSSLT`, its entry is `4010h`, and its documented RAM limit remains
`F300h`.

External payload discovery should remain separate from the internal fallback.
Recommended precedence is:

1. valid external payload selected explicitly from the menu;
2. valid external payload as the automatic BASIC fallback;
3. validated internal payload;
4. a clear fatal message if neither is valid.

This allows a newer external interpreter to override the factory copy while
ensuring a self-contained machine still reaches BASIC.

## Boot dispatcher and failure semantics

### Proposed state machine

```text
reset and hardware initialization
          |
          v
show logo/jingle and scan external cartridges
          |
          +-- cartridge INIT does not return --> cartridge owns machine
          |
          v
bounded Space-key window
          |
          +-- Space --> options menu
          |
          v
try installed floppy/disk bootstrap, if applicable
          |
          +-- success --> operating system owns machine
          |
          v
try IDE/SD standard hook or RainBIOS direct bootstrap
          |
          +-- success --> operating system owns machine
          |
          v
launch external BASIC payload if valid, otherwise built-in BASIC
```

The exact disk-versus-IDE order should preserve the compatibility behavior
already established for NMS 8250, Sunrise IDE, SD Mapper, and mixed
configurations. The important change is that every clean no-media or
non-bootable return converges on the BASIC fallback instead of the indefinite
logo wait.

The current `cold_boot_valid_payload` behavior suppresses automatic storage
boot whenever an external BASIC payload is present. That rule should be
revisited: it conflicts with the new policy that storage gets a boot attempt
before automatic BASIC. Menu-selected BASIC can still bypass storage.

### Meaning of “IDE boot failed”

RainBIOS can guarantee fallback only for failures represented by a bounded
return path, for example:

- no IDE/SD controller found;
- no medium found;
- command timeout or controller error detected by RainBIOS code;
- invalid or missing boot-sector signature;
- a standard `H.RUNC` path which returns without transferring control;
- a direct RainBIOS IDE/SD loader which restores the slot map and returns.

RainBIOS cannot generally recover from arbitrary third-party code which:

- never returns from cartridge `INIT` or `H.RUNC`;
- disables interrupts and hangs;
- corrupts page mappings, the stack, hooks, or BIOS work areas;
- jumps into invalid memory;
- resets the machine repeatedly.

A watchdog-based recovery would be hardware- and emulator-dependent and is
outside the normal MSX cartridge contract. The user-facing promise should
therefore say “falls back to BASIC when the boot path reports failure or
returns” rather than claiming recovery from every malfunctioning cartridge.

Before launching BASIC after any storage return, restore and verify:

- page 0 and page 1 mapped to the MAIN-ROM slot;
- page 2 and page 3 mapped to the selected contiguous RAM;
- mapper ports at the documented `3,2,1,0` baseline where applicable;
- `SP`, `HIMEM`, `MEMSIZ`, `STKTOP`, hook state, keyboard buffer, VDP mode,
  PSG/controller state, and interrupt mode required by the payload contract.

## Alternatives considered

### Separate internal slot ROM

Install the existing 16 KiB payload as an internal page-1 ROM in another
primary or secondary slot. This needs no boot-asset compaction and preserves
the full 32 KiB RainBIOS address space. It is the safest architecture for an
emulator machine definition or new hardware with suitable slot decoding.

It does not produce a universal single 32 KiB ROM file. A concatenated flash
image would be hardware-specific because the board must decode its parts into
different MSX slots. This remains the recommended long-term architecture when
firmware growth matters more than a traditional drop-in MAIN-ROM image.

### Compressed interpreter copied to RAM

The current interpreter ROM compresses to roughly 11.8 KiB with a generic
host compressor, which still does not fit comfortably in the existing 8 KiB
tail. More importantly, copying it into page-1 RAM would consume one of the
three visible RAM pages available while BASIC also needs `8000h-F2FFh` for
state, programs, work areas, and the BIOS stack boundary. Reading compressed
source from page-1 ROM while replacing page 1 with RAM also complicates slot
access.

This design gives up the already-tested ROM-safety model and should not be the
first implementation.

### Banked ROM larger than 32 KiB

A banked 48/64 KiB system ROM would preserve space, but there is no universal
MSX MAIN-ROM banking contract. It would require machine-specific hardware,
emulator configuration, and bank-switching code. Treat it as a separate
hardware target, not the default RainBIOS ROM format.

## Licensing and branding assessment

### Component licenses

The current combined binary would contain components under several compatible
but distinct terms:

| Component | Terms |
| --- | --- |
| original RainBIOS code and documentation | BSD-3-Clause |
| RainBIOS logo and generated visual asset source | CC0-1.0 |
| imported R. T. Russell Z80 interpreter source | Zlib license text in the companion repository's `COPYING` |
| independently written MSX interpreter adapter | BSD-3-Clause |

The R. T. Russell notice matches the standard Zlib license: it permits use,
modification, and redistribution, including commercial use, while forbidding
misrepresentation, requiring altered source to be clearly marked, and
requiring the notice to remain in source distributions. The adapter and
RainBIOS BSD-3-Clause terms require their copyright/license notices to
accompany binary distributions in documentation or other supplied material.

These permissive terms are compatible with aggregation into one ROM. They do
not make the entire ROM exclusively BSD-3-Clause. Describe the combined binary
as containing BSD-3-Clause, Zlib, and CC0-1.0 components; an SPDX file-level
expression may therefore be `BSD-3-Clause AND Zlib AND CC0-1.0`. Preserve the
component boundary in source and release metadata.

At minimum, a source or binary release containing the combined ROM should
include:

- the RainBIOS BSD-3-Clause license and copyright notice;
- the interpreter port's BSD-3-Clause license and contributor notice;
- the complete R. T. Russell `COPYING` notice;
- the CC0-1.0 text and asset manifest for the logo;
- a `THIRD_PARTY_NOTICES` or equivalent file mapping ROM regions to their
  source repositories, revisions, and licenses;
- written identification of the port as an altered/derived MSX version, not
  an original upstream build.

Do not build the combined ROM from one of the binary download archives on the
official BBC BASIC site: those downloads have their own archive-distribution
condition. Build from the recorded Zlib-licensed source snapshot instead.

### Name and trademark risk

Copyright permission for the interpreter code does not grant branding rights.
R. T. Russell's current official `BBCZ80` repository states that the name
`BBC BASIC` is used with the British Broadcasting Corporation's permission
and that this permission does not transfer to derived or forked works.

This is a release blocker for using `BBC BASIC` as the title, boot-menu label,
ROM banner, repository identity, or promotional product name unless written
permission is obtained. Two safe paths should be evaluated:

1. obtain written permission covering the MSX port, RainBIOS integration,
   screenshots, repository name, and binary distribution; or
2. rename the derived port and its on-screen banner, while factually stating
   in provenance documentation that its interpreter core is derived from R. T.
   Russell's Z80 implementation under the Zlib license.

The second path must still satisfy the Zlib rule against misrepresenting the
origin. A distinct product name and accurate attribution are complementary,
not contradictory. Before a public release, have the chosen wording reviewed
by someone qualified to advise on trademark law in the target jurisdictions.

The existing `bbcbasic-z80-msx` repository name, README wording, RainBIOS menu
text, and interpreter banner should all be included in that branding review;
embedding makes the issue more visible but does not create it.

### Would changing RainBIOS from BSD-3-Clause to MIT help?

No material obstacle in this design is caused by RainBIOS using
BSD-3-Clause. MIT and BSD-3-Clause are both permissive licenses which allow
commercial use, modification, and source or binary redistribution. Both are
compatible with the interpreter core's Zlib license.

Their main practical differences here are:

- BSD-3-Clause has an explicit non-endorsement clause preventing the RainBIOS
  copyright holder's or contributors' names from being used to promote a
  derived product without permission;
- MIT lacks that clause and uses a shorter notice;
- MIT requires its copyright and permission notice in copies or substantial
  portions of the software, while BSD-3-Clause spells out source-retention and
  binary-documentation obligations separately.

Changing RainBIOS to MIT would not:

- relicense the Zlib interpreter core;
- relicense the BSD-3-Clause MSX adapter in the companion repository;
- change the logo's CC0-1.0 status;
- transfer permission to use the `BBC BASIC` name;
- eliminate the need for a multi-license notice bundle in a combined release.

Unless every relevant copyright holder agrees to relicense or dual-license
their contribution, existing BSD-3-Clause code cannot simply be declared MIT.
Changing only new RainBIOS code would create another license boundary, and
changing RainBIOS without changing the companion adapter could make the
combined image `MIT AND BSD-3-Clause AND Zlib AND CC0-1.0` instead of
simplifying it.

The recommendation is therefore to keep RainBIOS under BSD-3-Clause. It is
already permissive, compatible with the proposed integration, and its
non-endorsement protection is useful for a firmware project. Consider MIT or
dual licensing only for a broader project-governance reason, after identifying
all copyright holders and obtaining their explicit consent; do not do it as a
solution to interpreter embedding.

### Toolchain

The companion project records uncertainty around the historical licensing of
`zmac` and therefore does not vendor it. `ld80` is recorded as public domain.
The combined build should continue treating those executables as externally
supplied tools, or migrate to a clearly licensed reproducible assembler/linker
path before release automation depends on them. Do not include the uncertain
tool binary in RainBIOS release archives.

## Build and dependency design

Implementation should add a distinct target rather than making the ordinary
MAIN-ROM depend unconditionally on the sibling repository. A suitable build
pipeline is:

1. verify the pinned companion repository commit and preserved upstream tree;
2. build the 16 KiB payload from source with the recorded toolchain;
3. require the exact expected size, header, descriptor, map boundaries, and
   SHA-256;
4. generate and verify compressed boot assets;
5. assemble a lower-half RainBIOS image and fail if it exceeds `3FFFh`;
6. concatenate/link the exact payload bytes at `4000h`;
7. verify the resulting ROM is exactly 32,768 bytes and that its upper half is
   byte-identical to the independently built payload;
8. emit a machine-readable component/license manifest beside the ROM.

For ordinary development, the existing separate-ROM target should remain
buildable without the companion checkout. A release builder may use a pinned
submodule, a verified adjacent checkout, or a source archive with immutable
hashes. Whichever mechanism is chosen must make source identity obvious and
must not silently fall back to an old prebuilt interpreter artifact.

## Required tests

### Host-side layout and provenance

- combined ROM is exactly 32 KiB;
- lower-half firmware does not cross `4000h`;
- upper half equals the pinned 16 KiB payload byte for byte;
- `AB` header, `4010h` entry, `RBP1` descriptor, checksum, required service
  bits, RAM base, and RAM limit are valid;
- source revision, upstream tree, artifact digest, and all license files are
  present and match the release manifest;
- asset compression round-trips exactly to the generated VRAM tables.

### Automatic boot matrix in 1983 and openMSX

- no external cartridges: interpreter banner and prompt appear without input;
- Space during the bounded window: options menu appears;
- menu BASIC selection: built-in interpreter starts;
- normal game/application cartridge: cartridge retains control;
- ordinary cartridge whose `INIT` returns: BASIC fallback remains defined;
- bootable floppy: disk payload starts instead of BASIC;
- empty or non-bootable floppy: policy proceeds to IDE/SD and then BASIC;
- bootable Sunrise IDE: Nextor and GeoBench still boot;
- empty/non-bootable Sunrise IDE: BASIC starts after a clean return;
- bootable SD Mapper card A and card B: existing Nextor behavior remains;
- empty SD Mapper, including mixed floppy/Sunrise configurations: existing
  storage precedence remains and BASIC is the final fallback;
- external valid BASIC payload: selected precedence over the internal copy;
- invalid external payload: fails closed without suppressing the internal copy;
- MSX1 and MSX2 configurations, including expanded slots and a mapper;
- interpreter console, graphics, cassette LOAD/SAVE, scrolling, editing, and
  zero-ROM-write guards continue to pass from the internal slot mapping.

### Fault injection

Tests should force each RainBIOS-controlled storage error path: controller
absence, no medium, command timeout, status error, invalid boot signature,
partial sector read, and returned `H.RUNC`. Each must restore the documented
slot/stack/mapper state and reach BASIC. A deliberately non-returning cartridge
should be documented as outside the recovery guarantee rather than given a
false passing test.

### Hardware

Before making the combined image the recommended default, test at least:

- a real MSX1 with 32 KiB and 64 KiB RAM profiles as applicable;
- a real MSX2 with SUB-ROM and memory mapper;
- a Sunrise IDE cartridge with bootable and empty media;
- an SD Mapper with zero, one, and two cards;
- an NMS-style floppy controller;
- cold reset, warm reset, repeated reset, and power-cycle behavior.

## Implementation phases

1. **Resolve naming and release terms.** Obtain permission or select a new
   product name; add complete third-party notices.
2. **Reconcile the dependency lock.** Review and pin the intended companion
   revision and deterministic artifact.
3. **Compact boot assets.** Add a clearly licensed or original decoder,
   enforce the page-0 limit, and preserve exact logo/menu rendering.
4. **Produce the combined image.** Add the optional 32 KiB target and host
   layout/provenance checks without changing boot policy.
5. **Add internal descriptor launch.** Validate and launch the built-in copy
   through the existing entry contract.
6. **Change automatic fallback policy.** Add the bounded Space window and
   converge clean storage failures on BASIC.
7. **Run the full emulator matrix.** Preserve every current cartridge, Nextor,
   GeoBench, graphics, keyboard, controller, cassette, and disk test.
8. **Validate hardware and release packaging.** Only then consider presenting
   the combined ROM as the default end-user image.

## Decision record

Proceeding later is reasonable, subject to two conditions:

- resolve or avoid the non-transferable `BBC BASIC` branding before release;
- accept the page-0 growth ceiling imposed by dedicating `4000h-7FFFh` to the
  interpreter.

If page-0 space becomes too constrained as RainBIOS compatibility grows, keep
the BIOS and interpreter as separate distributed ROMs or install the payload
in a separately decoded internal slot. That architecture is less elegant as a
single universal file but has substantially lower long-term firmware risk.

## Sources and evidence

- Local RainBIOS source, symbol file, generated assets, payload ABI, and boot
  tests at the repository revision current when this document was written.
- Local `../bbcbasic-z80-msx` checkout, including `COPYING`, `UPSTREAM.md`,
  `docs/CORE_AUDIT.md`, `docs/TOOLCHAIN.md`, the link map, and the deterministic
  16 KiB payload.
- [Official R. T. Russell BBCZ80 repository](https://github.com/rtrussell/BBCZ80),
  including its Zlib license identification and branding notice.
- [SPDX Zlib license entry](https://spdx.org/licenses/Zlib.html).
- [SPDX BSD-3-Clause license entry](https://spdx.org/licenses/BSD-3-Clause.html)
  and [SPDX MIT license entry](https://spdx.org/licenses/MIT.html), consulted
  for the relicensing comparison.
- [Official BBC BASIC (Z80) distribution page](https://bbcbasic.co.uk/bbcbasic/z80basic.html),
  consulted to distinguish the official binary archives from the separately
  licensed source snapshot used by this project.
