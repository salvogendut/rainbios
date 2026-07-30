<!-- SPDX-License-Identifier: BSD-3-Clause -->

# RainBIOS payload descriptor v1

Optional RainBIOS payloads remain ordinary MSX cartridges. A normal 16 KiB
payload places this descriptor in its final 16 bytes (`7FF0h-7FFFh`) so the
firmware can identify and validate it without changing the standard `AB`
header or cartridge initialization behavior.

All 16-bit fields are little-endian:

| Offset | Size | Field | BBC BASIC P1 |
| ---: | ---: | --- | ---: |
| `00h` | 4 | magic, ASCII `RBP1` | `52 42 50 31` |
| `04h` | 1 | descriptor version | `01h` |
| `05h` | 1 | descriptor length | `10h` |
| `06h` | 1 | payload type (`01h` = BASIC) | `01h` |
| `07h` | 1 | required firmware services | `07h` |
| `08h` | 2 | entry address | `4010h` |
| `0Ah` | 2 | first payload RAM address | `8000h` |
| `0Ch` | 2 | exclusive payload RAM limit | `F300h` |
| `0Eh` | 1 | contiguous 16 KiB RAM pages required | `02h` |
| `0Fh` | 1 | checksum | additive sum of all 16 bytes is zero |

Required-service bits are:

- bit 0: text console BIOS calls;
- bit 1: keyboard BIOS calls;
- bit 2: 50/60 Hz timing and `JIFFY`;
- bits 3-7: reserved and zero.

The descriptor describes requirements; successful validation authorizes the
menu entry, not immediate cartridge startup. RainBIOS also verifies that pages
2 and 3 map contiguous RAM, that all requested services are implemented, and
that the entry lies in the selected page-1 payload ROM. The first valid
primary or expanded payload wins. A cartridge with exact `RBP1` magic but an invalid
descriptor fails closed and its ordinary `INIT` is not called.

## Entry contract

Selecting option 1 produces this non-returning transfer:

- page 0 remains the RainBIOS MAIN-ROM;
- page 1 maps the slot containing the validated payload;
- pages 2 and 3 remain the contiguous RAM selected at cold boot;
- `SP=F380h`;
- A, BC, DE, HL, IX, and IY are zero;
- Z80 interrupt mode 1 and maskable interrupts are enabled;
- the keyboard buffer is empty after the menu selection is consumed.

RainBIOS pushes the descriptor entry temporarily and uses `RET` only as an
indirect jump, leaving `SP=F380h` at the target. There is no payload return
address: a version-1 entry must not return. Flags are unspecified.
