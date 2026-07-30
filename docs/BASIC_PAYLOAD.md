# BASIC payload integration

RainBIOS intends to offer `START BBC BASIC` as a boot-menu entry. The current
M0 menu is a truthful preview: there is no MSX payload binary and launch stays
disabled until M1 establishes slots, RAM, a stack, and work areas.

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
payload with interpreter state at `8000h` and user memory from `8300h`
plausible. A runtime read-only write guard is still required before that
layout becomes a compatibility promise.

SE BASIC IV remains useful open-source prior art and a possible future
alternative payload. Its adjacent upstream checkout remains unmodified; no
SE BASIC fork or source change is part of this integration.

## Payload responsibilities

The BBC BASIC project will own:

- the interpreter and its retained upstream license;
- an MSX startup and return adapter;
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

## Proposed launch sequence

After M1, RainBIOS will:

1. initialize slots, RAM, the stack, interrupts, and documented work areas;
2. discover a payload through a versioned descriptor, not a hard-coded slot;
3. validate descriptor size, version, addresses, RAM requirement, and required
   firmware capabilities;
4. copy a ROM-resident interpreter image into its selected writable layout if
   the final port requires it;
5. establish the documented register and interrupt state;
6. transfer control through inter-slot code and diagnose an unexpected return.

The descriptor bytes, entry registers, memory ownership, required service
table, and return convention will be fixed by original tests before launcher
code is enabled. The descriptor must not collide with ordinary MSX cartridge
startup.

## Dependency workflow

With the BBC BASIC repository cloned beside RainBIOS, run:

```sh
make check-bbcbasic
```

This verifies the checked-out commit, preserved upstream tag/tree, and the BBC
repository's own tests. The lock currently records `"artifact": null`, so
RainBIOS cannot accidentally claim that an unbuilt payload is available. Once
the MSX build is reproducible, the lock will also record the artifact name,
size, and SHA-256 digest.

## Milestones

- **M0:** visible BBC BASIC menu entry; launcher truthfully marked as requiring
  M1.
- **M1:** payload descriptor and discovery tests; initialized launch state.
- **Port P0 (complete):** standalone build driver reproduces the 15,616-byte
  CP/M baseline with SHA-256 `8f65a0a8…`; the externally supplied `zmac` and
  `ld80` sources are recorded.
- **Port P0b (complete):** static audit fixes the 26-symbol MSX platform
  boundary and checks ROM-core assumptions on every `make check`.
- **Port P1:** MSX console-only prompt with storage explicitly unsupported.
- **M2/M3:** enough console, keyboard, timing, and optional PSG services for
  interactive smoke tests.
- **M4:** launch the pinned payload and run BBC BASIC expression, editing, and
  example-program tests.
