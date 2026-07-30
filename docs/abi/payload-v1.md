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

The descriptor describes requirements; it does not authorize a launch.
RainBIOS must also verify that pages 2 and 3 map suitable RAM, that the
required services are implemented, and that the entry lies in the selected
payload ROM. Version 1 discovery is limited to normal 16 KiB page-1 payloads.
Expanded-slot discovery and the exact launch/return register contract remain
separate M1 work.
