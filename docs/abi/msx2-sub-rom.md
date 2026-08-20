<!-- SPDX-License-Identifier: BSD-3-Clause -->

# MSX2 SUB-ROM status

RainBIOS ships a self-contained 16 KiB MSX2 SUB-ROM (`src/main_msx2_sub.asm`,
built as `build/rainbios_msx2_sub.rom`). It carries the standard `CD` header
and the documented SUB-ROM fixed-entry layout, and is installed in the machine
SUB-ROM slot (3-0 on the test fixtures). The MSX2 main ROM reaches its
routines through the `EXTROM` (`015Fh`) dispatch, which passes the SUB-ROM
routine address in IX and the slot from `EXBRSA`.

The SUB-ROM runs with the target page switched to its own slot, so it cannot
call the main BIOS: VDP register writes, 16-bit VRAM access, and the R0-R23
shadow work area are handled locally.

## Implemented entries

| Address | Name | Status | Behavior |
| --- | --- | --- | --- |
| `00D1h` | CHGMOD | implemented | Screens 5, 6, 7, and 8 (bitmap modes). Programs R0-R11, publishes `NAMBAS`/`PATBAS`/`ATRBAS`, sets `SCRMOD`, and clears the bitmap through the VDP HMMV command. Other modes return carry |
| `0109h` | WRTVRM | implemented | Write A to the 16-bit VRAM address in HL (R14 carries the high bits) |
| `010Dh` | RDVRM | implemented | Read the 16-bit VRAM address in HL into A |
| `012Dh` | WRTVDP | implemented | Write B to VDP register C and update the R0-R7/R8-R23 shadows |
| `0131h` | VDPSTA | implemented | Read the VDP status register selected by A into A; restores status 0 |
| `0141h` | INIPLT | implemented | Initialize the V9938 palette to the default 0GRB values and copy to the VRAM palette store |
| `0145h` | RSTPLT | implemented | Restore the palette from the VRAM palette store |
| `0149h` | GETPLT | implemented | Return colorcode A as `B = RRRRBBBB`, `C = xxxxGGGG` from the VRAM store |
| `014Dh` | SETPLT | implemented | Set palette index D to RRRRBBBB in A and xxxxGGGG in E, and update the VRAM store |
| `0191h` | BLTVV | implemented | Copy a rectangle from VRAM to VRAM (LMMM). Reads SX/SY/DX/DY/NX/NY from the command work area and waits for completion |
| `0195h` | BLTVM | implemented | Copy a rectangle from RAM to VRAM (LMMC). SX points at the RAM screen data: NX (16-bit), NY (16-bit), then pixels packed per the screen mode; the CPU feeds each pixel colour through R44 |
| `0199h` | BLTMV | implemented | Copy a rectangle from VRAM to RAM (LMCM). DX points at the destination RAM screen data: NX/NY header, then pixels; each pixel is read from status 7 and packed per the screen mode |
| `01F5h` | REDCLK | implemented | Read one RTC register selected by C (`xxBBAAAA`) through the clock ports (`B4h`/`B5h`) into A |
| `01F9h` | WRTCLK | implemented | Write A to the RTC register selected by C (`xxBBAAAA`) through the clock ports |

The remaining graphics/screen-mode entries (`0085h`-`00CDh`, `00D5h`-`00F1h`,
`00F5h`-`0105h`, `0111h`-`0119h`, `013Dh`, `019Dh`-`01B3h` excluding the
implemented block transfers and clock) return cleanly; they are not
implemented in this slice.

The disk-file transfer entries `BLTVD`/`BLTDV`/`BLTMD`/`BLTDM`
(`019Dh`/`01A1h`/`01A5h`/`01A9h`) are deliberately left as safe returns. A real
implementation streams whole files between disk and VRAM/RAM through the DOS
file API (open/create/set-DTA/random block I/O/close via BDOS), and requires
DOS API bindings not yet provided. MSX2 storage boot via Nextor is gated
independently of these calls. The main ROM reports the standard MSX2 generation
value at 002Dh so applications such as SymbOS can identify the machine
correctly. The entries stay safe returns until DOS bindings are implemented,
mirroring the C-BIOS reference.

## VDP command engine

The block-transfer commands drive the V9938 command engine through registers
R32-R46. SX/SY/DX/DY are written as 16-bit low/high pairs (R32-R39), NX/NY as
R40-R43, and the command code into R46. The work area variables are the
documented `SX`/`SY`/`DX`/`DY`/`NX`/`NY` (`F562h`-`F56Dh`) and `L_OP`
(`F570h`); `BLTVV` issues LMMM (`90h`) and waits for the CE bit, while
`BLTVM`/`BLTMV` use the LMMC (`B0h`)/LMCM (`A0h`) CPU-transfer handshake:
the CPU waits for the status-2 TR bit, then writes each pixel colour to R44
(`BLTVM`) or reads it from status 7 (`BLTMV`), packing per the current screen
mode (SC5/SC7: two 4-bit pixels per byte, SC6: four 2-bit, SC8: one 8-bit).

## Real-time clock

`REDCLK`/`WRTCLK` address the MSX2 battery-backed clock through ports `B4h`
(address) and `B5h` (data). C carries the address `xxBBAAAA` (two block bits,
four register bits); the block is selected through the mode register (13) and
the register through its low nibble.

## Palette encoding

The V9938 palette entry is 9-bit 0GRB: bits 8-10 green, bits 4-6 red, bits
0-2 blue. `SETPLT` writes the low byte (`xRRRxBBB`) then the high byte
(`xxxxxGGG`) to the palette latch (port `9Ah`). `INIPLT`/`RSTPLT`/`GETPLT`
maintain a 32-byte copy of the palette in VRAM at a screen-dependent base
(`7680h` for screens 5/6, `FA80h` for screens 7/8).

## 16-bit VRAM access

`WRTVRM`/`RDVRM` accept the full 16-bit address in HL and write the upper
address bits to VDP register 14 (R14), so the complete 128 KiB VRAM range is
reachable.

## Reference

- Register programming and entry layout cross-checked against the attributed
  open-source C-BIOS 0.29a SUB-ROM and the public MSX2 Technical Handbook
  behavior; see `docs/REFERENCES.md`.
- Verification: `test-1983-msx2-subrom-services` (1983) and
  `test-openmsx-msx2-services` (openMSX) call `EXTROM` into CHGMOD 5/6/7/8,
  palette, and 16-bit VRAM and validate the observable state.
  `test-1983-msx2-subrom-cmdclock` (1983) and `test-openmsx-msx2-cmdclock`
  (openMSX) call the block transfers and the RTC entries and validate the
  copied VRAM bytes, the BLTMV header/pixels, and the REDCLK/WRTCLK round
  trip.
