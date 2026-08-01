<!-- SPDX-License-Identifier: BSD-3-Clause -->

# NMS 8250 read-only disk ROM

`build/rainbios_nms8250_disk.rom` is an optional 16 KiB extension ROM for the
Philips NMS 8250 WD2793 memory layout. It is built separately with
`make nms8250-disk-rom` and is not part of the main RainBIOS artifact.

## Initialization

The standard `AB` header begins at `4000h`. `INIT` derives its full slot ID from
`IYH`, publishes one drive in `DRVINF`, installs a five-byte `H.PHYD` hook, and
installs a five-byte `H.RUNC` bootstrap hook. It does not retain control.
Standard `DSKIO` entry `4010h` reaches the same read-only implementation.

## Bootstrap contract

RainBIOS calls `H.RUNC` (`FECBh`) at cold boot through `cold_boot_init_disk`,
after setting `DEVICE = 1` and `DISK_SETUP = 0`. A valid payload holds back that
cold-boot call so the Space-key menu can be reached; menu option 2 re-enters the
same hook with the same `DEVICE`/`DISK_SETUP` context whenever the user asks to
run the drive-A boot-sector path. The hook reads logical sector 0 into `C000h`
with the read-only `PHYDIO` path and checks the first byte for the MSX-DOS
signature `EBh` or `E9h`.

If the signature does not match, or the read fails (for example an empty drive),
the hook returns normally and the interactive menu continues. If it matches,
the hook sets `SP` to a page-3 stack and enters the loader at `C000h+1Eh`:

| Input | Value |
| --- | --- |
| A | `00h`, cold-boot flag |
| Carry | Set |

The loader runs in page-3 RAM while this ROM stays mapped in page 1, so it may
call `DSKIO` (`4010h`) and every other entry below through an inter-slot call
using the slot ID published in `H.PHYD+1`. The cold-boot path invokes the hook
once; the menu re-enters it on request. A return always means no bootable medium
was found and the caller (cold boot or menu) continues.

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

## DSKCHG contract

Standard `DSKCHG` entry `4013h`. Inputs follow the MSX-DOS `DSKCHG` calling
convention:

| Input | Supported value |
| --- | --- |
| A | `00h`, drive A |
| B | ignored; the kernel passes `00h` |
| C | `F9h`, expected media descriptor |
| HL | Base of the 21-byte DPB |

The medium-change flag is drained from the WD2793 drive register and the
controller status is probed without issuing a command; both are single reads,
so the call never spins or starts the motor. On success carry is clear and A is
zero, with B reporting the change state:

| B | Meaning |
| --- | --- |
| `FFh` | The medium has changed since the last `DSKCHG`; the FAT and data buffers must be discarded |
| `01h` | The medium is still in place |
| `00h` | Unknown (drive not ready) |

A drive number other than A reports error 12 with carry set and B zero. C, DE,
and HL are clobbered.

## GETDPB contract

Standard `GETDPB` entry `4016h`. Inputs follow the MSX-DOS `GETDPB` calling
convention:

| Input | Supported value |
| --- | --- |
| A | `00h`, drive A |
| B | ignored; the kernel passes the descriptor read from the FAT |
| C | `F9h`, expected media descriptor |
| HL | Base of the 21-byte per-drive parameter block |

The fixed F9 DPB is published in the 18 bytes `HL+1` through `HL+18`. The drive
number byte at `HL` and the FAT buffer pointer at `HL+19..HL+20` belong to the
kernel and are left untouched. On success carry is clear and A and B are zero,
and DE and HL are preserved. A drive number other than A reports error 12 with
carry set and B zero.

The published 720 KiB F9 layout is:

| Field | Offset | Value |
| --- | --- | --- |
| MEDIA | HL+1 | `F9h` |
| SECBIZ | HL+2 | `0200h` (512) |
| DIRMSK | HL+4 | `0Fh` |
| DIRSHFT | HL+5 | `04h` |
| CLUSMSK | HL+6 | `01h` |
| CLUSSHFT | HL+7 | `02h` |
| FIRFAT | HL+8 | `0001h` |
| FATCNT | HL+10 | `02h` |
| MAXENT | HL+11 | `70h` (112) |
| FIRREC | HL+12 | `000Eh` (14) |
| MAXCLUS | HL+14 | `02CAh` (714) |
| FATSIZ | HL+16 | `03h` |
| FIRDIR | HL+17 | `0007h` |

The `MAXCLUS` value is `DISK_CLUSTERS + 1`, so DOS stores the true count minus
one in the FAT, matching the MSX-DOS `DSKCHG`/`GETDPB` usage.

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

The current component provides a cold-boot bootstrap hook that loads and runs a
boot-sector loader, but not FAT or DOS services, `DSKCHG` media-change driven
DOS calls, formatting, drive B, writes, or controllers other than the NMS 8250
memory-mapped WD2793. The change state is
synthesized from the WD2793 drive register and controller status rather than a
mechanical switch, so it cannot distinguish a swapped medium of identical
geometry from the originally mounted image. Emulator validation does not
establish real hardware DRQ timing, motor spin-up timing, or side/drive
polarity; those remain explicit compatibility work with a concrete test plan in
`docs/HARDWARE_TEST.md`.
