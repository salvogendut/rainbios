<!-- SPDX-License-Identifier: BSD-3-Clause -->

# BBC BASIC media integration

This document records the implemented sound, sprite, and MSX2 graphics slice
of the embedded BBC BASIC payload. The work was tracked in issue #172 and
spans two repositories:

- `../bbcbasic-z80-msx` owns the independently written MSX adapter and its
  standalone emulator tests;
- RainBIOS pins, rebuilds, verifies, compresses, and embeds that exact payload,
  while providing the published BIOS and SUB-ROM services it calls.

The review which promoted this document from a plan to an implementation
record found and corrected several tests that had accepted internally
consistent but physically aliased VRAM. The current gates inspect raw high
VRAM as well as BASIC-level `POINT` results.

## Implemented surface

| Surface | Implemented | Deliberate limitation |
| --- | --- | --- |
| Sound | `SOUND`, `ENVELOPE`, digital `ADVAL` controller reads | AY hardware-envelope approximation, synchronous finite notes, no full BBC software ADSR/pitch sweep |
| Sprites | `*SPRITE`, `*SPRITEOFF`, `*SPRITEPAT`, `*SPRITECLR` in Screen 2 | MSX-specific OSCLI extension; 8x8 pattern definition only |
| MSX1 graphics | Screens 0-3; Graphics II `CLG`, `GCOL`, `MOVE`, `DRAW`, supported `PLOT`, `POINT` | Existing cell-colour and raster-operation limits remain |
| MSX2 graphics | Screens 5-8, full bitmap clear, high-VRAM pixel access | Screens 6/7 expose the left 256 pixels until the adapter accepts a 16-bit X coordinate; Screens 10-12 are outside scope |

Random-access file channels remain unsupported. Sequential cassette program
`SAVE`/`LOAD` is a separate completed slice.

## Sound semantics

`SOUND channel,amplitude,pitch,duration` maps channel 0 to noise and channels
1-3 to AY tone A/B/C. The adapter follows the BBC sign convention:

- amplitudes `-15..0` select fixed volume (zero is silence);
- a positive amplitude selects the most recently defined matching envelope;
- higher pitches produce higher frequencies;
- duration `-1` leaves the note playing, while `0..254` is a synchronous
  JIFFY-timed note which is silenced on completion.

The compact pitch conversion is octave-linear rather than an exact BBC
quarter-semitone table. `ENVELOPE` parses the documented parameter order and
maps attack timing and direction to the single shared AY hardware envelope.
The remaining pitch and ADSR phases are accepted but approximated. Selecting
an envelope retriggers AY register 13. Playing noise and then tone A restores
the tone/noise mixer routing correctly.

`ADVAL(0)` and `ADVAL(2)` return joystick directions for ports 1 and 2;
`ADVAL(1)` and `ADVAL(3)` return trigger state as BBC false/true (`0`/`-1`).
This is a documented digital approximation of BBC analogue channels.

The implementation uses published `WRTPSG`, `RDPSG`, `GTSTCK`, and `GTTRIG`
BIOS entries. Payload descriptor required-service bit 5 declares that sound
dependency; bits 6-7 remain reserved.

## Sprite commands

BBC BASIC has no portable sprite keyword, so the adapter exposes a small
MSX-specific OSCLI surface without changing the preserved language core:

```text
*SPRITE n,x,y,pattern,colour
*SPRITEOFF n
*SPRITEPAT n,b0,b1,b2,b3,b4,b5,b6,b7
*SPRITECLR
```

The commands write the Screen 2 sprite attribute and pattern tables through
the published main-BIOS VRAM interface. `*SPRITEPAT` defines one 8x8 pattern;
`*SPRITE` selects its position and colour; `*SPRITEOFF` hides one sprite; and
`*SPRITECLR` hides all 32. The commands are visible after `MODE 2`.

## MSX2 bitmap modes

`MODE 5`-`8` first checks the published `MSXVER` generation byte and rejects
the request on MSX1 without changing the active mode. On MSX2 it calls the
public main-BIOS `CHGMOD` entry, allowing RainBIOS to dispatch through its
SUB-ROM and initialize and clear the whole bitmap screen.

Pixel operations use the public SUB-ROM 16-bit `WRTVRM`/`RDVRM` entries, not
the main-BIOS 14-bit calls. This distinction is essential: using only the
main-BIOS calls aliases addresses at every 16 KiB boundary and can make a
write/read round trip appear correct while corrupting another scanline.

The packed formats are:

- Screen 5: 256x212, 4 bits per pixel;
- Screen 6: 512x212, 2 bits per pixel, most-significant pixel first;
- Screen 7: 512x212, 4 bits per pixel;
- Screen 8: 256x212, 8 bits per pixel.

The interpreter's current X coordinate becomes one byte during physical
scaling. It therefore covers the full width of Screens 5/8 and the left half
of Screens 6/7. Screen 6 logical colours map directly to physical colours
0-3. Bitmap-mode character output is suppressed so a subsequent BASIC prompt
cannot overwrite bitmap VRAM.

## Validation

The companion project provides the primary implementation gates:

| Target | Coverage |
| --- | --- |
| `test-msx-sound-openmsx` | fixed/envelope amplitude, rising pitch, noise-to-tone mixer restoration, periods, volumes, and envelope registers |
| `test-msx-sprite-openmsx` | command parsing plus exact sprite pattern/attribute VRAM |
| `test-msx-mode-openmsx` | Screens 0-3 and clean rejection of Screen 5 on MSX1 |
| `test-msx-msx2-openmsx` | C-BIOS MSX2 Screens 5-8, distinct raw high-VRAM bytes, Screen 6/7 packing, logical colours, and full `CLG` |
| `test-msx-msx2-modes-1983` | Screen 5-8 VDP mode selection on the Omega V9958 model |
| `test-msx-msx2-plot-1983` | distinct low/high-VRAM `PLOT`/`POINT` results in all four bitmap modes |
| `test-msx-media-1983` | visibly rendered hardware sprite and continued execution after an indefinite `SOUND` |

RainBIOS additionally rebuilds the pinned companion revision on every normal
build, verifies its exact 16 KiB digest, and checks that the compressed `RBC1`
container reconstructs the same payload. The unified Omega artifact is tested
with the internal payload selected and no external BASIC cartridge.

## Compatibility and clean-room boundary

The adapter calls only published MSX BIOS/SUB-ROM interfaces and documented
work-area variables. Implementation and tests must not use proprietary BIOS
or BASIC source, ROM data, disassembly, or derived tables. Public references
used for this slice are recorded in the companion project's
`docs/REFERENCES.md` and this repository's `docs/REFERENCES.md`.

The code-license combination remains redistributable with the recorded
notices. Permission to use the `BBC BASIC` name, or a distinct product rename,
is still a separate public-release gate.
