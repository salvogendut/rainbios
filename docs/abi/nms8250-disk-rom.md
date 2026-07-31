<!-- SPDX-License-Identifier: BSD-3-Clause -->

# NMS 8250 read-only disk ROM

`build/rainbios_nms8250_disk.rom` is an optional 16 KiB extension ROM for the
Philips NMS 8250 WD2793 memory layout. It is built separately with
`make nms8250-disk-rom` and is not part of the main RainBIOS artifact.

## Initialization

The standard `AB` header begins at `4000h`. `INIT` derives its full slot ID from
`IYH`, publishes one drive in `DRVINF`, and installs a five-byte `H.PHYD` hook.
It does not install a boot hook or retain control. Standard `DSKIO` entry
`4010h` reaches the same read-only implementation.

## PHYDIO contract

Inputs follow BIOS entry `0144h`:

| Input | Supported value |
| --- | --- |
| A | `00h`, drive A |
| B | `01h` through `FFh`, subject to range and buffer limits |
| C | `F9h`, 720 KiB media |
| DE | First zero-based logical sector, `0000h` through `059Fh` |
| HL | Destination wholly within `8000h` through `EFFFh` |
| Carry | Clear for read; set requests a write |

The complete request is validated before the motor or controller is touched.
The exclusive logical end must not exceed sector 1440. The exclusive buffer
end must not exceed `F000h`, must not wrap, and must remain outside page 1,
which contains the disk extension while the hook runs.

On success carry is clear, A is zero, and B is the requested sector count. On
failure carry is set, A is an error code, and B is the number of fully completed
sectors. AF, C, DE, HL, IX, IY, and alternate registers are clobbered.

## Error codes

| A | Meaning |
| --- | --- |
| 0 | A valid write was rejected as write-protected |
| 2 | Drive A has no ready media |
| 4 | CRC, lost-data, or incomplete-sector data error |
| 6 | Seek failed or timed out |
| 8 | Physical sector was not found |
| 12 | Drive, media, count, logical range, or buffer was invalid |
| 16 | Read or controller completion timed out, or status was inconsistent |

Writes are rejected before any WD2793 write command. Error codes 10 and 14 are
not produced because the component neither writes nor allocates memory.

## Geometry and transfer

Logical sectors use 80 tracks, two sides, nine 512-byte sectors per side:

```text
track  = logical / 18
side   = (logical % 18) / 9
sector = (logical % 9) + 1
```

The driver seeks the requested track and issues one WD2793 single-sector read
per logical sector. Every call allows a cold motor approximately one second to
spin up, requests seek verification, and enables the read-command head-settling
delay. It advances sector, side, and track in software, allowing a single call
to cross all three boundaries. Controller IRQ and DRQ polls are finite. On any
runtime failure, the driver force-interrupts the controller, turns off the
motor, and reports only the completely validated sector prefix.

## Limitations

The current component does not provide disk boot, FAT or DOS services,
`DSKCHG`, `GETDPB`, formatting, drive B, writes, or controllers other than the
NMS 8250 memory-mapped WD2793. Emulator validation does not establish real
hardware DRQ timing, motor spin-up timing, or side/drive polarity; those remain
explicit compatibility work.
