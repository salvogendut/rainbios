<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Slot-call status

RainBIOS M1B implements the public primary-slot register calls and the
non-expanded portion of `ENASLT`. The register contract follows Chapter 5,
section 7 of the public MSX2 Technical Handbook.

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

## Temporary expanded-slot behavior

An `ENASLT` input with A bit 7 set is not implemented yet. M1B leaves the slot
map unchanged and returns with carry set. Carry is clear after a successful
primary-slot selection. This failure convention is a RainBIOS bring-up
extension, not a claim about the standard BIOS contract, and will disappear
when expanded-slot handling is implemented.

`RDSLT`, `WRSLT`, `CALSLT`, and `CALLF` remain stubs.

The `test-openmsx-slots` target verifies register preservation, every primary
page selection, the page-0 RAM helper, the page-3 return path, and the
expanded-ID failure behavior.
