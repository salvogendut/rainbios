<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Slot-call status

RainBIOS M1H implements the public primary-slot register calls, primary and
expanded forms of `RDSLT`, `WRSLT`, and `ENASLT`, and page-1/page-2 primary
and expanded `CALSLT`. The register contract follows Chapter 5, section 7 of
the public MSX2 Technical Handbook.

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

Page-0 reads and writes use dedicated RAM helpers at `F383h` and `F38Bh`.
Pages 1–3 execute from page 0; a page-3 access restores the old page before
executing `RET`, so the original stack is visible again.

`CALSLT` at `001Ch` takes the target address in IX and the slot ID in the high
byte of IY. M1H accepts primary and expanded targets in page 1 or page 2. If
the target returns, RainBIOS restores the exact previous primary and secondary
selections and returns the target routine's normal registers and flags. Slot
selection runs through the alternate banks so AF/BC/DE/HL reach the target
unchanged. Maskable interrupts are inhibited before the target is selected.
Targets in page 0 or page 3 remain rejected because they would hide the caller
or its stack.

## Invalid and unsupported inputs

An expanded ID whose primary slot is not marked in `EXPTBL` fails closed with
carry set and does not alter memory or either selector. Carry is clear after
successful `ENASLT`, `RDSLT`, and `WRSLT`; `CALSLT` returns the flags produced
by its target. The invalid-ID failure convention is a RainBIOS bring-up
extension, not a claim about the standard BIOS contract.

`CALLF` parses the standard inline slot byte and target word through the
alternate banks, then delegates primary or expanded page-1/page-2 calls to
`CALSLT` without changing the target's normal input registers. Page-0/page-3
targets remain pending.

The `test-openmsx-slots` target verifies register preservation, every primary
page selection, physical-RAM reads and writes, exact map restoration, all
three page-0 RAM helpers, the page-3 stack paths, returning page-1/page-2
`CALSLT`, a nested returning page-1 call, and invalid-ID failure.
`test-openmsx-expanded-slots` independently exercises all four pages through
multiple secondary slots, checks the physical inverted selector and `SLTTBL`,
tests stack-safe page-3 restoration, and calls a returning expanded page-1
target. The separate `test-openmsx-services` probe exercises `CALLF` from
`H.TIMI` while interrupts are enabled and requires the exact slot state to be
restored.
