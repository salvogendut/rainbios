<!-- SPDX-License-Identifier: BSD-3-Clause -->

# NMS 8250 disk hardware validation checklist

This checklist validates the assumptions built into
`src/disk_nms8250_driver.asm` against a real Philips NMS 8250. The emulator and
openMSX fixtures idealize DRQ/IRQ and motor timing, so this document is the
explicit compatibility work deferred by `docs/abi/nms8250-disk-rom.md`.

Every numbered item is either a *measurement* (record the observed value) or a
*pass/fail check*. Record all results in the machine section below and add the
session to `docs/REFERENCES.md` when a new source is consulted.

## Environment record

Fill in before starting:

- Machine: NMS 8250 model/revision, BIOS sub-version if known.
- Controller: WD2793 / WD1793 / FD1793 variant and FDC crystal (determines the
  DRQ byte-cell window, see Timing).
- Drive: make, model, head step rate, ready/door-switch wiring.
- Media: 720 KiB double-sided, density (DD), media ID `F9h`.
- ROM under test: `build/rainbios_nms8250_disk.rom` build hash
  `f0d1e9883a7d12aa3c97bfa8948dd5f4` (record the tested hash).
- How the ROM is loaded (cartridge adapter, EPROM board, flash), and how the
  host reads the probe mailbox (debugger, serial logger, scope).
- Date, ambient conditions, test jig/setup description.

## Register window and polarity

The driver uses the fixed window `7FF8h-7FFFh`. Confirm each before any timing
work; a polarity error here manifests as a hang, not a clean error code.

1. **Window mapping.** Write a known pattern to `7FF9h` (`FDC_TRACK`) and read
   it back; confirm `7FF8h` aliases status/command, `7FFBh` aliases data, and
   `7FFFh` is the LINES register.
2. **LINES bit 6 = inverted IRQ** (`src/disk_nms8250_driver.asm:356`,
   `:420`). Idle (no transfer): read `7FFFh`, bit 6 must be `1`. Issue a force
   interrupt (`D0h` to `7FF8h`): bit 6 must read `0` until the next command.
3. **LINES bit 7 = inverted DRQ** (`:335-338`). After a read command with a
   byte in `7FFBh`, bit 7 must read `0`; after the byte is consumed it returns
   to `1`.
4. **Drive/motor register** (`7FFDh`). Write `80h` then `00h`; verify the
   drive motor audibly starts/stops and drive A is selected (`:78-79`,
   `:144-147`).
5. **Side register** (`7FFCh`). Write `01h` then `00h` and confirm the head
   load/side effect matches (side 1 vs side 0) (`:321-327`).
6. **Status register bits** (`7FF8h`). After a no-media attempt, bit 7
   (not ready) must be set; the mapping in `disk_map_read_status`
   (`:390-418`) assumes bits 7, 4, 3, 2, and 1:0 mean not-ready,
   record-not-found, data-error, lost-data, and busy/DRQ.

## Functional read path

7. **Single sector.** Read logical sector 0 into a known buffer; verify the
   recorded marker and no error. Confirm B returns 1.
8. **Side and track crossing.** Read a range that crosses a side boundary and
   a range that crosses a track boundary (for example LBA 8-18 and LBA 17-19);
   verify complete data.
9. **Multi-sector B.** Request several sectors and confirm B equals the number
   of fully completed sectors on success and on an injected failure.
10. **Cold start.** First call on a cold machine must not return not-ready; the
    driver waits before seeking (`disk_motor_spinup`, `:152-167`).

## Timing

The driver replaces JIFFY with bounded instruction loops because the controller
path runs with interrupts inhibited. All loops are `#ffff` iterations.

11. **Motor spin-up.** Measure the time between writing `80h` to `7FFDh` and
    the drive reaching operating speed. Compare with the driver's approximately
    one-second budget (two `#ffff` epochs, `:154-164`) at the measured Z80
    clock. A cold drive must be ready before the seek command starts.
12. **Not-ready timeout.** With an empty drive, a read must return error 2
    (not ready), not error 16 (timeout), and must do so within the bounded IRQ
    wait (`disk_wait_irq`, `:420-434`).
13. **DRQ service rate (primary risk).** Measure the worst-case
    poll-to-read latency of `disk_read_sector_wait_data` (`:334-353`) against
    the DD byte-cell window for the FDC crystal:
    - Poll interval when DRQ is not yet set: about 33 cycles
      (`ld a,(7FFFh)`, `bit 7`, `jr z` not taken).
    - Read completes about 41 cycles after the poll that catches DRQ, giving a
      worst-case ~74 cycles (~21 us at 3.58 MHz) from DRQ assertion to data
      read.
    - A 250 kbit/s byte cell (~32 us) leaves margin; a 500 kbit/s cell
      (~16 us) does not and can lose data.
    Do not trust this cycle estimate on hardware. Run the soak test below; any
    lost-data/CRC error on a known-good disk is evidence the loop does not
    service the real byte stream.
14. **Head settling.** Repeatedly seek to a track and read it immediately;
    the WD2793 read-command settling delay (`:329`) must absorb seek settle on
    the real drive without CRC errors.
15. **Verified seek.** Confirm the seek+verify command (`1Ch`, `:279`) leaves
    `7FF9h` (`FDC_TRACK`) equal to the requested track on both sides, including
    after a failed seek.
16. **Force interrupt.** With a stuck transfer, `D0h` must retire it and the
    next status read must be valid (`:378-382`, `:116-124`).

## Error-path reproduction

Reproduce the openMSX fault scenarios on hardware, without the test double:

- Empty drive read -> error 2.
- No media in a selected drive -> error 2.
- Damaged sector (scratch, or bad CRC region) -> error 4.
- Wrong geometry/format so a physical sector is absent -> error 8.
- Lost data, when reproducible, -> error 4 (never a silent success).
- Seek failure -> error 6.
- Any status whose busy/DRQ bits are set at completion -> error 16.

Confirm each error code matches `docs/abi/nms8250-disk-rom.md`.

## Media-change and DPB behavior

The `DSKCHG`/`GETDPB` paths drain the WD2793 drive register and probe status
without issuing a command, so they must never spin or start the motor.

19. **Changed medium.** Mount a disk, call `DSKCHG` (`4013h`) for drive A with
    the DOS calling convention; confirm carry clear, A zero, and B `FFh`.
20. **Unchanged medium.** Call `DSKCHG` again without touching the drive; confirm
    B `01h`. Swap the disk and call again; confirm B `FFh` once more.
21. **No medium.** With the drive empty, call `DSKCHG`; confirm carry clear,
    A zero, and B `00h` (unknown), never an error or a hang.
22. **Bad drive.** Call `DSKCHG` with A not equal to zero; confirm error 12.
23. **DPB publication.** Call `GETDPB` (`4016h`) with `HL` at a 21-byte buffer
    and confirm the 18 bytes `HL+1..HL+18` match the F9 layout in
    `docs/abi/nms8250-disk-rom.md`, the drive byte at `HL` is untouched, and the
    FAT pointer at `HL+19..HL+20` is untouched. Confirm the motor never starts.
24. **Bad drive.** Call `GETDPB` with A not equal to zero; confirm error 12.

## Bootstrap hook

RainBIOS calls `H.RUNC` (`FECBh`) once at cold boot after it has selected a disk
device. The hook reads the boot sector into `C000h`, validates the MSX-DOS
signature, and either transfers control to the loader at `C000h+1Eh` (with
`A = 0` for a cold boot and carry set) or returns so the interactive menu
continues.

25. **Bootable disk.** Boot with a 720 KiB F9 disk whose sector 0 begins with
    `EBh`/`E9h`. Confirm the loader runs from `C000h`, can call `DSKIO` (`4010h`)
    for further sectors, and that the machine never falls through to the BASIC
    prompt.
26. **Non-bootable medium.** Boot with a disk whose sector 0 does not begin with
    `EBh`/`E9h`, and again with an empty drive. Confirm `H.RUNC` returns, the
    stack is the RainBIOS stack, and the interactive menu appears.
27. **Second boot attempt.** Confirm the hook is only invoked once per cold boot
    and never re-entered after a warm return.

## Data-integrity soak

17. Read the entire disk (1440 logical sectors) and verify every recorded
    marker. Repeat at least three times. A single lost byte anywhere fails the
    checklist. Run at least one cold-start soak and one warm soak.
18. If a second drive is available, swap drive A and repeat the soak to rule
    out a drive-specific timing outlier.

## Instrumentation suggestions

- **Software:** reuse the test-shell pattern in `tests/cartridges/*.asm`; put
  results in a mailbox the host can read. Time the spin-up with a busy-loop
  counter logged before and after.
- **Logic analyzer/scope:** probe DRQ, IRQ, and the address decoder for
  `7FFBh`/`7FFFh` to measure poll-to-read latency directly (item 13) and to
  confirm the LINES polarity (items 2-3).
- **Soak harness:** a test ROM that reads the whole disk in a loop and toggles
  a PSG/PPI bit on any error is the cheapest lost-data detector.

## Recording and sign-off

Record the results of every item, the machine/controller revision, the drive
and media, the tested ROM hash, and the date. For anything that fails, capture
whether it is a driver bug, a wrong assumption, or a measurement error, and
open the fix as its own change. Update `docs/abi/nms8250-disk-rom.md`
limitations and `docs/REFERENCES.md` with what the session establishes.
