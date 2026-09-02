<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Slot-call status

RainBIOS M1H implements the public primary-slot register calls, primary and
expanded forms of `RDSLT`, `WRSLT`, and `ENASLT`, and inter-slot calls
(`CALSLT`/`CALLF`) for primary and expanded targets in every page. The
register contract follows Chapter 5, section 7 of the public MSX2 Technical
Handbook.

`MAPPER_SEGMENTS` at `F345h` holds the memory-mapper segment count detected at
boot (a power of two, or 1 when no mapper is present). Segment allocation uses
the standard reserved mapper ports `FCh`-`FFh` with `MAPPER_SEGMENTS` as the
upper bound. Detection accepts a candidate segment only when two complementary
write patterns stick at two addresses without changing the segment-0 marker.
The first unwritable or mirrored candidate is the upper bound; this rejects
decoded but physically unpopulated SRAM banks.

## Implemented calls

`RSLREG` at `0138h` reads PPI port `A8h` into A. It preserves the remaining
registers and flags.

`WSLREG` at `013Bh` writes A to PPI port `A8h`. It preserves registers and
flags. This is intentionally the raw low-level operation specified by the
interface; callers are responsible for executing from, and retaining a stack
in, memory that remains mapped by the requested value.

`ENASLT` at `0024h` accepts the standard slot ID in A. For expanded IDs,
bit 7 is set, bits 3–2 select the secondary slot, and bits 1–0 select the
primary slot. The top two bits of H select the 16 KiB page. Other pages retain
their current selections. Expanded calls update both `SLTTBL` and the
non-inverted value written to the physical `FFFFh` selector. The call inhibits
maskable interrupts before changing either selector.

Page 0 switching finishes through an `OUT (A8h),A`/`RET` helper installed at
`F380h`, because code in page 0 disappears as soon as the new slot is selected.
Page 3 switching pops the return address before replacing the page that
normally contains the stack, then jumps directly to that address.

`RDSLT` at `000Ch` reads the byte addressed by HL from the primary or expanded
slot in A and returns it in A. HL and E are preserved. `WRSLT` at `0014h`
writes E to that address and preserves both HL and E. Both calls restore the
exact previous primary and secondary selections before returning. They inhibit
maskable interrupts before changing slot state.

Page-0 reads and writes use the standard RAM primitives `RDPRIM` at `F380h`
and `WRPRIM` at `F385h`. `CLPRIM` at `F38Ch` and `CLPRM1` at `F398h` provide
the corresponding primary-slot call trampoline. Pages 1–3 execute from page 0;
a page-3 access restores the old page before executing `RET`, so the original
stack is visible again.

`CALSLT` at `001Ch` takes the target address in IX and the slot ID in the high
byte of IY. M1H accepts primary and expanded targets in page 1 or page 2. If
the target returns, RainBIOS restores the exact previous primary and secondary
selections and returns the target routine's normal registers and flags. Slot
selection runs through the alternate banks so AF/BC/DE/HL reach the target
unchanged. Maskable interrupts are inhibited before the target is selected.
Expanded calls expose separate saved primary and secondary selector fields at
the standard stack offsets used by mapper kernels. If the target patches those
page-2/page-3 fields after reallocating RAM, RainBIOS restores the patched
values rather than the stale pre-call selectors.

## Page-0 and page-3 targets

`CALSLT` accepts targets in pages 0 and 3 as well.

A page-0 target switches page 0 only. Because the PPI write hides this page-0
routine, the switch, the call, and the map restore run from the standard
`CLPRIM` helper in page-3 RAM (the same helper the primary-slot read/write
paths use). For an expanded page-0 target the subslot selector is written from
this page-0 routine first — safe because the target primary differs from the
primary mapped in page 0, otherwise the call fails closed — and the page-0
return frame restores both the selector and the map afterward. A page-0 target
cannot call the BIOS through page-0 vectors while it runs (page 0 is its own
slot), matching the original inter-slot behavior.

A page-3 target whose slot already occupies page 3 is a no-op switch and uses
the ordinary returning-call path with the stack left visible. A page-3 target
in another slot switches page 3 only; the target's page-3 memory must be
writable RAM, and RainBIOS installs a return frame at `F360h-F368h` in that
RAM. The frame carries the previous map, the previous selector (expanded
targets only), and the caller's stack pointer, which the return path restores
after the target returns. Page-3 targets in another slot may not rely on the
caller's stack contents, and the mapping and selector are restored even if the
target remapped page 3.

`CALLF` parses the standard inline slot byte and target word through the
alternate banks, then delegates to `CALSLT`; page-0 and page-3 targets follow
the same paths.

## Invalid and unsupported inputs

An expanded ID whose primary slot is not marked in `EXPTBL` fails closed with
carry set and does not alter memory or either selector. Carry is clear after
successful `ENASLT`, `RDSLT`, and `WRSLT`; `CALSLT` returns the flags produced
by its target. The invalid-ID failure convention is a RainBIOS bring-up
extension, not a claim about the standard BIOS contract.

A page-0 expanded target whose primary equals the primary currently mapped in
page 0 fails closed: writing that selector would hide the executing page-0
routine. A page-3 target in another slot whose page-3 memory is not writable
RAM fails closed after restoring the previous mapping.

`CALLF` parses the standard inline slot byte and target word through the
alternate banks, then delegates to `CALSLT` without changing the target's
normal input registers.

The `test-openmsx-slots` target verifies register preservation, every primary
page selection, physical-RAM reads and writes, exact map restoration, all
three page-0 RAM helpers, the page-3 stack paths, returning page-1/page-2
`CALSLT`, a nested returning page-1 call, page-0 and page-3 primary calls, and
invalid-ID failure. `test-openmsx-expanded-slots` independently exercises all
four pages through multiple secondary slots, checks the physical inverted
selector and `SLTTBL`, tests stack-safe page-3 restoration, calls a returning
expanded page-1 target which patches all three saved selector bytes before
returning, and covers page-0, page-3 expanded, and page-3 primary-different
slot targets. `test-openmsx-mapper` verifies boot-time memory-mapper sizing
with both a full 4 MiB mapper and an Omega-style 512 KiB mapper whose upper
decoded banks are physically absent.
The separate `test-openmsx-services` probe exercises `CALLF` from
`H.TIMI` while interrupts are enabled and requires the exact slot state to be
restored.
