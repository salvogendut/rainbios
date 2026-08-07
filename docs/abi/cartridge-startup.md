<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Cartridge startup state

The state RainBIOS presents to an ordinary MSX1 cartridge at its `INIT` entry,
characterized end to end by `test-openmsx-cartridge` and
`test-openmsx-expanded-cartridge`.

## INIT entry

RainBIOS finds the public `AB` header at `4000h` of a non-BIOS slot, reads the
16-bit `INIT` pointer at `4002h`, and transfers control through the returning
`CALSLT` path with this register state:

| Register | Value |
| --- | --- |
| `IX` | the `INIT` pointer from the header |
| `IY` | the slot ID in the high byte (primary or expanded) |
| `DE` | the `INIT` pointer |
| `A`, `B` | the slot ID |
| `C` | `00h` |
| `HL` | `4003h`, the header address of the `INIT` high byte (scan artifact) |
| `SP` | a RainBIOS page-3 stack (`F080h`-`F380h`) with the `CALSLT` return frame |

Flags are unspecified. A, B, C, DE, and HL pass through `CALSLT` unchanged,
matching the documented slot-calling contract. An `INIT` that returns is
treated as a conventional application cartridge: it suppresses automatic
embedded BASIC and may continue through hooks or interrupt-driven code.

## Work area at boot

A cartridge sees the normal M1 boot state: hooks initialized to `RET`, the
standard slot tables (`EXPTBL` at `FCC1h`, `SLTTBL` at `FCC5h`), `BIOSSLT`
(`FCC0h`) and the RAM slot published through `RAMAD0`-`RAMAD3`, `BOTTOM`
(`FC48h`) and `HIMEM` (`FC4Ah`) set, and `SP` established at reset. The probe
verifies the slot map, tables, and a nonblank rendered frame alongside the
register snapshot.
