<!-- SPDX-License-Identifier: BSD-3-Clause -->

# BBC BASIC media integration plan

This document is the working plan for completing the media surface of the
embedded BBC BASIC payload: sound, sprites, and MSX2 graphic modes. It tracks
issue #172 and describes work across two repositories:

- `../bbcbasic-z80-msx` — the interpreter port whose `platform/msx/` adapter
  contains the currently stubbed `SOUND`, `ENVELOPE`, `ADVAL`, `COLOUR`, and
  sprite entries.
- this repository — the firmware that embeds and launches the payload and
  already exposes the underlying PSG, sprite, and extended-VDP services.

## Current state

The payload reaches the prompt and supports editing, expressions, stored
programs, cassette `SAVE`/`LOAD`, and an MSX1 Graphics II subset:

| Surface | Implemented | Missing |
| --- | --- | --- |
| Graphic modes | `MODE 2` (Screen 2), `MODE 7` (Screen 0) | Screen 1, Screen 3, MSX2 Screens 5-8 |
| Colour | `GCOL 0,c` (8 fixed TMS9918 colours) | `COLOUR`, 16/256-colour palettes |
| Plot | `CLG`, `MOVE`, `DRAW`, `PLOT` lines/points/triangles, `POINT` | `PLOT` 96+ (rectangles, fills, circles, ellipses) |
| Sound | — | `SOUND`, `ENVELOPE`, `ADVAL` (all `Sorry` stubs) |
| Sprites | — | no sprite access at all |

`SOUND`, `ENVELOPE`, `ADVAL`, `COLOUR`, `GETIMS`, and `PUTIMS` currently share
the trailing `Sorry` error block in `platform/msx/graphics.z80`. `VDU`
(`exec.z80`) writes each byte through `OSWRCH`/`CHPUT`, so BBC's native
`VDU 23` user-graphics route cannot reach the VDP and must be re-interpreted
by the adapter rather than inherited.

## Layers and existing firmware services

The payload adapter already calls published MSX BIOS entries directly
(`CHPUT`, `CHGET`, `RDVRM`, `WRTVRM`, `FILVRM`, `INITXT`, `INITGRP`). The
media work reuses the same discipline and the services RainBIOS already
provides:

| Service | Entry | Status |
| --- | --- | --- |
| PSG initialize / write / read | `GICINI` `0090h`, `WRTPSG` `0093h`, `RDPSG` `0096h` | implemented |
| Joystick / trigger | `GTSTCK` `00D5h`, `GTTRIG` `00D8h` | implemented |
| Sprite utilities | `CLRSPR` `0069h`, `CALPAT` `0084h`, `CALATR` `0087h`, `GSPSIZ` `008Ah` | implemented (M2G) |
| Extended VDP dispatch | `EXTROM` `015Fh` → SUB-ROM `CHGMOD` Screens 5-8, palette, 16-bit VRAM | implemented (M5) |

The payload descriptor (`docs/abi/payload-v1.md`) currently declares required
services for console, keyboard, timing, Graphics II VDP/VRAM, and cassette.
Bits 5-7 are reserved and zero; this plan assigns them meaning.

## Sound (PSG)

Goal: `SOUND`, `ENVELOPE`, and `ADVAL` produce audio and controller reads
instead of `Sorry`.

Adapter work (`bbcbasic-z80-msx/platform/msx/`):

1. Implement `SOUND ch,amp,pitch,dur` by mapping the BBC three-voice model
   onto the PSG's three tone channels through `WRTPSG` (or the `A0h`/`A1h`
   ports as a fallback). BBC amplitude 0-15 and logarithmic pitch must be
   converted to the PSG's 12-bit period and 4-bit volume registers.
2. Implement `ENVELOPE` shaping. The AY-3-8910/YM2149 hardware envelope (R13)
   covers only a fixed saw/triangle/decay family; a BBC-compatible ADSR shape
   needs a software envelope driven from the VBlank hook (`H.TIMI`) updating
   the volume registers. The first slice maps the standard shapes onto the
   hardware envelope and documents the remainder.
3. Implement `ADVAL` for the joystick/controller path via `GTSTCK`/`GTTRIG`
   (and PSG `R14`/`R15`), returning the BBC analogue-channel convention.
4. Initialise the PSG GPIO directions at entry (`GICINI`) so joystick reads
   are well-defined.

Firmware work:

- Confirm `GICINI` leaves R15 in a known controller state for the payload's
  entry; the existing controller snapshot in the IM 1 handler already does.
- No new BIOS entries are required.

## Sprites

Goal: expose MSX hardware sprites from BBC BASIC.

Adapter work:

1. Decide the keyword surface. BBC BASIC has no sprite keyword; the least
   invasive options are (a) a VDU-based extension (`VDU 23` and `VDU 25`
   families re-interpreted by `OSWRCH`) or (b) new `*`-command / `OSCLI`
   forms. A small dedicated set (e.g. `SPRITE n,x,y,pattern,colour` /
   `SPRITEOFF n`) is the most readable and is the recommended slice.
2. Drive the VDP sprite attribute table (`ATRBAS`, four bytes per sprite:
   Y, X, pattern, colour/EC) and pattern table (`PATBAS`, 8 bytes per sprite,
   32 bytes for 16x16) through the existing `RDVRM`/`WRTVRM`/`FILVRM` paths.
3. Use `CLRSPR`/`CALPAT`/`CALATR`/`GSPSIZ` where they save work, and preserve
   R1 sprite-size bits when switching modes (already guaranteed by the
   firmware's mode init).

Firmware work:

- The sprite utilities are already implemented; the descriptor only needs to
  declare the requirement (see the contract section).

## MSX2 graphic modes

Goal: `MODE 5`-`8` reach V9938/V9958 bitmap screens with palette and correct
resolution, and `COLOUR` works.

Adapter work:

1. In `MODE`, accept 5, 6, 7, and 8. Under RainBIOS the payload runs on an
   MSX2 whose SUB-ROM already implements `CHGMOD`; call it through `EXTROM`
   (`015Fh`) with the mode in the documented register. The standalone
   cartridge build needs a self-contained V9938 setup path (or documents its
   MSX1 limitation).
2. Map the BBC `1280x1024` logical grid to each screen's physical resolution
   (256x212, 256x424, 512x212, 256x212) in `PARSEXY`/`PARSEXYREL`, and extend
   `PLOT`/`POINT` to the 16-colour palette via `SETPLT`/`INIPLT` and 16-bit
   `WRTVRM`/`RDVRM` for the larger VRAM range.
3. Implement `COLOUR` (text foreground/background) against the current mode.
4. `PLOT` modes 96+ (rectangles, fills, circles, ellipses) remain a separate
   later slice; the current explicit "Unsupported graphics operation" error
   stays for them until then.

Firmware work:

- The SUB-ROM already provides `CHGMOD`, palette, and 16-bit VRAM; the
  descriptor must declare MSX2 extended-VDP as a required service so menu
  selection only offers the payload on MSX2-capable machines (or the adapter
  degrades gracefully on MSX1).

## Descriptor and launch contract

Extend `docs/abi/payload-v1.md` required-service bits:

- bit 5: PSG sound (`GICINI`/`WRTPSG`/`RDPSG`, `BEEP`, PLAY work area);
- bit 6: sprite utilities (`CLRSPR`/`CALPAT`/`CALATR`/`GSPSIZ`);
- bit 7: MSX2 extended VDP (`EXTROM`/`CHGMOD` Screens 5-8, palette, 16-bit VRAM).

A payload that sets these bits is offered only when RainBIOS implements the
corresponding services; bit 7 additionally requires the MSX2 build and a live
SUB-ROM. The existing fail-closed rule (invalid descriptor ⇒ no `INIT`)
already covers this.

## Sequencing and tests

Suggested order, each slice with its own gate:

1. **Sound** — `test-1983-bbcbasic-sound` / openMSX: run `SOUND`/`BEEP`, then
   inspect the PSG register writes (or capture the produced envelope) and the
   `ADVAL` controller result.
2. **Sprites** — `test-1983-bbcbasic-sprite` / openMSX: write a sprite via the
   new keywords, verify the attribute/pattern tables and a visible sprite on a
   captured frame.
3. **MSX2 modes** — `test-1983-bbcbasic-msx2` / openMSX: `MODE 7` then a bitmap
   mode, verify `SCRMOD`, the R0/R1 shadow, palette, and a `POINT` round trip.
4. **Contract** — host test that the descriptor bits are correctly parsed and
   that menu availability follows the required-service mask.

## Boundaries

- Clean-room policy (`docs/DEVELOPMENT_POLICY.md`): no proprietary BIOS or
  BASIC source, tables, or disassembly; only published interfaces and
  independently written code.
- Public release remains gated on `BBC BASIC` branding (permission or rename),
  independent of this media work.
