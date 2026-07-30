<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Slot-call status

RainBIOS M1D implements the public primary-slot register calls, the
non-expanded portions of `RDSLT`, `WRSLT`, and `ENASLT`, and page-1/page-2
primary `CALSLT`. The register contract follows Chapter 5, section 7 of the
public MSX2 Technical Handbook.

## Implemented calls

`RSLREG` at `0138h` reads PPI port `A8h` into A. It preserves the remaining
registers and flags.

`WSLREG` at `013Bh` writes A to PPI port `A8h`. It preserves registers and
flags. This is intentionally the raw low-level operation specified by the
interface; callers are responsible for executing from, and retaining a stack
in, memory that remains mapped by the requested value.

`ENASLT` at `0024h` accepts a non-expanded primary slot number in A bits 0–1.
The top two bits of H select the 16 KiB page. Other pages retain their current
primary slots.

Page 0 switching finishes through an `OUT (A8h),A`/`RET` helper installed at
`F380h`, because code in page 0 disappears as soon as the new slot is selected.
Page 3 switching pops the return address before replacing the page that
normally contains the stack, then jumps directly to that address.

`RDSLT` at `000Ch` reads the byte addressed by HL from the non-expanded primary
slot in A bits 0–1 and returns it in A. HL is preserved. `WRSLT` at `0014h`
writes E to that address and preserves both HL and E. Both calls restore the
exact previous primary-slot map before returning.

Page-0 reads and writes use dedicated RAM helpers at `F383h` and `F38Bh`.
Pages 1–3 execute from page 0; a page-3 access restores the old page before
executing `RET`, so the original stack is visible again.

`CALSLT` at `001Ch` takes the target address in IX and the slot ID in the high
byte of IY. M1D accepts non-expanded primary slots for targets in page 1 or
page 2. If the target returns, RainBIOS restores the exact previous primary
map and returns the target routine's normal registers and flags. Targets in
page 0 or page 3 are temporarily rejected because they would hide the caller
or its stack.

## Temporary expanded-slot behavior

An `ENASLT`, `RDSLT`, or `WRSLT` input with A bit 7 set, or a `CALSLT` input
with IY high bit 7 set, is not implemented yet. M1D leaves the slot map
unchanged and returns with carry set; an expanded `WRSLT` also leaves memory
unchanged. Carry is clear after successful primary `ENASLT`, `RDSLT`, and
`WRSLT`. `CALSLT` instead returns the flags produced by its target. This
failure convention is a RainBIOS bring-up extension, not a claim about the
standard BIOS contract, and will disappear when expanded-slot handling is
implemented.

`CALLF` remains a fail-stop stub. Slot calls are not yet tested with interrupts
enabled.

The `test-openmsx-slots` target verifies register preservation, every primary
page selection, physical-RAM reads and writes, exact map restoration, all
three page-0 RAM helpers, the page-3 stack paths, returning page-1/page-2
`CALSLT`, a nested returning page-1 call, and expanded-ID failure.
