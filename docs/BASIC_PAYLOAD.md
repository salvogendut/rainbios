# BASIC payload integration

RainBIOS offers `START BASIC` as a boot-menu entry. The MSX
payload works both as a standalone cartridge on compatible firmware and
through RainBIOS's descriptor-aware menu. RainBIOS establishes slot RAM,
validates the payload and its required services, and performs a dedicated
non-returning transfer. The complete editing, language, error, clock,
timed-input, graphics, and cassette-program paths are executable.

## Selected project

The port lives in the separate
[`bbcbasic-z80-msx`](https://github.com/salvogendut/bbcbasic-z80-msx)
repository. RainBIOS pins its current integration commit and preserved
upstream tree in `deps/bbcbasic-z80-msx.lock.json`.

The repository has two important branches:

- `upstream` preserves the BBC BASIC-only history extracted from the openly
  licensed CP/Mish tree;
- `main` adds provenance tests, the port plan, and independently written MSX
  platform code.

The immutable `upstream-cpmish-d70c643` tag has Git tree
`e9d0ae3c5f53fbd78379aa0d3f38d13f31c823f6`, exactly matching
`third_party/bbcbasic` at CP/Mish revision
`d70c643a5db24007ad6533f92b701fd714a99b7f`.

## Component and license boundary

The imported BBC BASIC sources retain the permissive notice in their
`COPYING` file. New MSX adapter, build, test, and documentation files use
BSD-3-Clause. RainBIOS itself is BSD-3-Clause.

This combination permits a RainBIOS release bundle to contain both artifacts,
provided the interpreter notice and all BSD notices are retained. The payload
remains a distinct source-built 16 KiB artifact, and RainBIOS now also embeds
those exact bytes in the upper half of its 32 KiB MAIN-ROM. The standalone
payload can still be used with another compatible firmware launcher.

No proprietary MSX BIOS or BASIC source, ROM data, or disassembly may be
copied into either project.

## Release packaging

The development build produces `rainbios_msx1.rom` as a combined MAIN-ROM and
also preserves `bbcbasic_msx_console.rom` as an independently built/tested
artifact in the companion checkout. Every normal RainBIOS rebuild rebuilds,
validates, and copies the pinned payload before assembly; the combined upper
half must match it byte-for-byte. A release archive may distribute both ROMs
with both projects' notices, but the branding and hardware gates below still
prevent treating that archive as release-ready.

The detailed technical design, boot-fallback semantics, test matrix, and
multi-license release requirements are in
[`EMBEDDED_BASIC.md`](EMBEDDED_BASIC.md). That assessment also records a
separate release blocker: upstream's permission to use the `BBC BASIC` name is
not transferable to a derived or forked work. The code is permissively
licensed, but the public name must be authorized or changed before release.

## Why BBC BASIC

The available Z80 source already separates most of the language core from a
small machine boot adapter and a CP/M operating-system layer. The known CP/M
layout builds `main`, `exec`, `eval`, `fpp`, `sorry`, and `cmos` at `0200h`,
with a machine adapter at `0100h` and writable state at `3B00h`.

That is still a real port, not a binary wrapping exercise. The source assumes
a contiguous writable CP/M address space and requires an audit for writes to
code, absolute addresses, interrupt state, and RAM use. However, its platform
boundary is substantially narrower than adapting a BASIC tightly coupled to
Spectrum-family paging and video hardware.

The first static audit found a 12,492-byte language core with no CP/M calls,
reserved storage, or interrupt-control opcodes. All 21 direct symbolic writes
target the separate 768-byte RAM module. This makes a 16 KiB page-1 ROM
payload with interpreter state at `8000h` plausible.

The current build places its cartridge veneer at `4000h`, independently written
console adapter at `4013h-423Ah`, unchanged core at `4400h-74C1h`, graphics
adapter at `74C2h-7B75h`, cassette adapter at `7B76h-7D19h`, fixed state at
`8000h-8339h`, and user memory from `833Ah`. Its deterministic 16 KiB ROM ends
with payload descriptor v1 at `7FF0h-7FFFh`, is pinned at companion revision
`34540d468d3f39da0d283da49c0feb2dab9a1313`, and has SHA-256
`82b0ff999ae85d4105875ad6e8c5a33f37662fbcde1642044c56a430de9759a6`.
A guarded openMSX test exercises editing, integer and
floating-point expressions, strings, a stored program, error handling, time,
and timed input with zero writes to the selected cartridge window. The 1983
emulator independently confirms that the banner and prompt render visibly.
An executable graphics example adds mode and colour selection, lines,
absolute plotting, and pixel readback; it passes on C-BIOS and through
RainBIOS in openMSX, with rendered output independently confirmed in 1983.
The sequential storage adapter writes the public MSX binary-tape envelope:
ten `D0h` bytes and a case-insensitive six-character filename, followed by
start/end/execute metadata and the tokenized program. `LOAD` and `RUN` pass
against a standard CAS fixture in 1983; `SAVE` returns successfully in
openMSX, whose recorded WAV is decoded back to the expected type/name header.
Random-access channels remain unsupported.

SE BASIC IV remains useful open-source prior art and a possible future
alternative payload. Its adjacent upstream checkout remains unmodified; no
SE BASIC fork or source change is part of this integration.

## Payload responsibilities

The BBC BASIC project owns:

- the interpreter and its retained upstream license;
- the standalone cartridge startup adapter;
- console, keyboard, cursor, centisecond-clock, Graphics II, and sequential
  cassette program services;
- a replacement for the CP/M-specific file/operating-system layer;
- its writable memory map and minimum-RAM requirements;
- standalone payload builds and interpreter smoke tests.

RainBIOS owns:

- descriptor discovery across initialized slots;
- RAM and slot state supplied to the launcher;
- version and capability checks;
- the page-1 transfer and defined non-returning entry contract;
- the menu state shown when no compatible payload is present.

## Launch sequence

RainBIOS now:

1. initialize slots, RAM, the stack, interrupts, and documented work areas;
2. discover a payload through a versioned descriptor, not a hard-coded slot;
3. validate descriptor size, version, addresses, RAM requirement, and required
   firmware capabilities;
4. keep the payload ROM mapped in page 1 and reserve its documented page-2/3
   RAM layout;
5. establish the documented register and interrupt state;
6. transfer control without placing a return address on the payload stack.

The descriptor bytes and validation rules are fixed in
`docs/abi/payload-v1.md` and covered by original host and emulator tests. A
claimed `RBP1` descriptor which fails validation is withheld from ordinary
cartridge `INIT` processing. The descriptor does not alter the ordinary MSX
cartridge header or standalone startup on other compatible firmware.

## Dependency workflow

With the BBC BASIC repository cloned beside RainBIOS, run:

```sh
make check-bbcbasic
```

This verifies the checked-out commit, preserved upstream tag/tree, and the BBC
repository's own tests. The lock records the exact P1 source revision,
artifact path, 16,384-byte size, and SHA-256 digest. If the artifact exists,
the check validates its bytes too. To build and require the pinned artifact,
use:

```sh
make check-bbcbasic-artifact \
  BBC_ZMAC=/path/to/zmac BBC_LD80=/path/to/ld80
```

## Milestones

- **M0:** visible BBC BASIC menu entry; launcher truthfully marked as requiring
  M1.
- **M1:** payload descriptor, primary/expanded discovery, RAM/stack state,
  ordinary cartridge INIT, and payload transfer are implemented. BBC BASIC is
  tested both as a primary-slot ROM and in expanded slot 2-2.
- **Port P0 (complete):** standalone build driver reproduces the 15,616-byte
  CP/M baseline with SHA-256 `8f65a0a8…`; the externally supplied `zmac` and
  `ld80` sources are recorded.
- **Port P0b (complete):** static audit fixes the 26-symbol MSX platform
  boundary and checks ROM-core assumptions on every `make check`.
- **Port P0c (complete):** deterministic link proof validates the 16 KiB
  page-1 ROM and aligned page-2 state layout.
- **Port P1 (complete):** bootable MSX console cartridge with random-access
  storage explicitly unsupported, guarded runtime tests in openMSX, and
  independent rendered-prompt confirmation in 1983.
- **Port P2 graphics (complete):** initial TMS9918 Graphics II subset with
  `MODE 2/7`, `CLG`, `GCOL 0,c`, `MOVE`, `DRAW`, absolute `PLOT` 4/5/69,
  and `POINT`, exercised by a real stored BASIC program.
- **Port P3 cassette (complete for sequential CAS):** program `SAVE`/`LOAD`
  through the published MSX tape calls, with deterministic fixture,
  two-emulator input coverage, and semantically decoded SAVE output.
- **M2/M3:** console, keyboard, and timing services pass the interactive smoke
  and graphics tests; complete console controls, keyboard behavior, and
  optional PSG services remain.
- **M4 (first slice complete):** launch the pinned payload from the boot menu
  and run BBC BASIC expression, editing, and example-program tests.
