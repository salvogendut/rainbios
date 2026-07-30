# BASIC payload integration

RainBIOS intends to offer `START BBC BASIC` as a boot-menu entry. The
console-only MSX payload now boots as a standalone cartridge, while the
current menu remains a truthful preview. RainBIOS now establishes primary-slot
RAM, a stack, a minimal work area, and simple primary-cartridge INIT transfer.
BBC BASIC menu launch stays disabled until its required firmware services,
descriptor discovery, capability checks, and the dedicated transfer contract
are implemented.

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
provided the BBC BASIC notice and all BSD notices are retained. BBC BASIC
will still be built as a distinct payload rather than consuming space in the
32 KiB main BIOS. A standalone payload release can also be used with another
compatible firmware launcher.

No proprietary MSX BIOS or BASIC source, ROM data, or disassembly may be
copied into either project.

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

The P1 console build places its cartridge veneer at `4000h`, independently
written adapter at `4013h-4230h`, unchanged core at `4400h-74CBh`, fixed state
at `8000h-8307h`, and user memory from `8308h`. Its deterministic 16 KiB ROM
ends with payload descriptor v1 at `7FF0h-7FFFh` and has SHA-256
`2a53b54b…`. A guarded openMSX test exercises editing, integer and
floating-point expressions, strings, a stored program, error handling, time,
and timed input with zero writes to the selected cartridge window. The 1983
emulator independently confirms that the banner and prompt render visibly.

SE BASIC IV remains useful open-source prior art and a possible future
alternative payload. Its adjacent upstream checkout remains unmodified; no
SE BASIC fork or source change is part of this integration.

## Payload responsibilities

The BBC BASIC project owns:

- the interpreter and its retained upstream license;
- the standalone cartridge startup adapter;
- console, keyboard, cursor, and centisecond-clock services;
- a replacement for the CP/M-specific file/operating-system layer;
- its writable memory map and minimum-RAM requirements;
- standalone payload builds and interpreter smoke tests.

RainBIOS will own:

- descriptor discovery across initialized slots;
- RAM and slot state supplied to the launcher;
- version and capability checks;
- inter-slot transfer and defined failure/return handling;
- the menu state shown when no compatible payload is present.

## Launch sequence

During the remaining M1 and later cartridge work, RainBIOS will:

1. initialize slots, RAM, the stack, interrupts, and documented work areas;
2. discover a payload through a versioned descriptor, not a hard-coded slot;
3. validate descriptor size, version, addresses, RAM requirement, and required
   firmware capabilities;
4. keep the payload ROM mapped in page 1 and reserve its documented page-2/3
   RAM layout;
5. establish the documented register and interrupt state;
6. transfer control through inter-slot code and diagnose an unexpected return.

The descriptor bytes and validation rules are fixed in
`docs/abi/payload-v1.md` and covered by original host tests. Entry registers,
memory ownership during transfer, and the return convention remain to be fixed
by tests before launcher code is enabled. The descriptor does not alter the
ordinary MSX cartridge header or standalone startup.

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
- **M1:** payload descriptor complete; primary RAM/stack state and simple
  primary-cartridge INIT implemented; expanded-slot discovery, interrupts,
  payload discovery, required services, and transfer state remain.
- **Port P0 (complete):** standalone build driver reproduces the 15,616-byte
  CP/M baseline with SHA-256 `8f65a0a8…`; the externally supplied `zmac` and
  `ld80` sources are recorded.
- **Port P0b (complete):** static audit fixes the 26-symbol MSX platform
  boundary and checks ROM-core assumptions on every `make check`.
- **Port P0c (complete):** deterministic link proof validates the 16 KiB
  page-1 ROM and aligned page-2 state layout.
- **Port P1 (complete):** bootable MSX console cartridge with storage
  explicitly unsupported, guarded runtime tests in openMSX, and independent
  rendered-prompt confirmation in 1983.
- **M2/M3:** enough console, keyboard, timing, and optional PSG services for
  interactive smoke tests.
- **M4:** launch the pinned payload and run BBC BASIC expression, editing, and
  example-program tests.
