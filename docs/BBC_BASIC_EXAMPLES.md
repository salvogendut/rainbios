<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Embedded BASIC examples

These small programs exercise the embedded Z80 BASIC and the MSX-specific
media extensions shipped with RainBIOS. They are intended for manual testing
on real hardware, 1983, its WebAssembly build, or openMSX.

With no bootable cartridge or storage device, RainBIOS starts BASIC
automatically after the logo. Alternatively, press Space during the logo and
choose `START BASIC`. Enter or paste the numbered lines, then enter `RUN` as
an immediate command. Useful immediate commands are:

```text
LIST
RUN
NEW
```

Re-entering a numbered line replaces it. Entering only its line number deletes
it. In native 1983, Ctrl+V pastes host clipboard text into the emulated
keyboard queue.

## Text and scrolling

This prints enough lines to force the Screen 0 console to scroll:

```bbc
10 CLS
20 FOR I%=1 TO 40
30 PRINT "RAINBIOS LINE ";I%
40 NEXT
50 PRINT "SCROLL TEST COMPLETE"
```

Expected result: all 40 iterations complete, the older lines scroll off the
top, and `SCROLL TEST COMPLETE` appears before the prompt.

## MSX1 Graphics II

This Screen 2 program draws a box and two diagonals, then waits for a printable
key before returning to text mode:

```bbc
10 MODE 2
20 GCOL 0,1
30 MOVE 480,384:DRAW 800,384:DRAW 800,640
40 DRAW 480,640:DRAW 480,384
50 GCOL 0,2
60 MOVE 480,384:DRAW 800,640
70 GCOL 0,4
80 MOVE 480,640:DRAW 800,384
90 REPEAT
100 K%=INKEY(10)
110 UNTIL K%<>-1
120 MODE 0
130 PRINT "KEY CODE ";K%
```

This works on MSX1 and MSX2. `GCOL 0,c` selects the drawing colour. The
graphics coordinate system uses the BBC-style logical range rather than raw
MSX pixel coordinates.

## PSG sound and envelope

The first loop plays a rising sequence on PSG tone channel A. The second note
uses the current hardware-envelope approximation on tone channel B:

```bbc
10 FOR P%=80 TO 200 STEP 20
20 SOUND 1,-12,P%,8
30 NEXT
40 ENVELOPE 1,5,0,0,0,0,0,0,10,0,0,-10,126,0
50 SOUND 2,1,150,40
60 PRINT "SOUND TEST COMPLETE"
```

RainBIOS maps BASIC sound channels 1, 2, and 3 to PSG tones A, B, and C.
Channel 0 is noise. Negative amplitudes select a fixed volume; a positive
amplitude selects the most recently defined matching envelope. A duration of
`-1` leaves the sound playing until another `SOUND` changes or silences the
channel.

## Screen 2 sprite and sound

The MSX-specific `*SPRITE` commands are BASIC OSCLI extensions. This example
defines an 8x8 hollow-square pattern, displays it as sprite 0, and plays a
continuous tone. Press a printable key to clean up and return to text mode:

```bbc
10 MODE 2
20 *SPRITECLR
30 *SPRITEPAT 0,255,129,129,129,129,129,129,255
40 *SPRITE 0,100,100,0,15
50 SOUND 2,-12,136,-1
60 REPEAT
70 K%=INKEY(10)
80 UNTIL K%<>-1
90 SOUND 2,0,136,-1
100 *SPRITEOFF 0
110 MODE 0
120 PRINT "SPRITE TEST COMPLETE"
```

`*SPRITE n,x,y,pattern,colour` uses raw MSX sprite coordinates. The current
extension supports 8x8 patterns and Screen 2.

## MSX2 bitmap colour fan

This program requires a V9938 or V9958 MSX2. Change `M%` on line 10 to 5, 6,
7, or 8 to exercise a different bitmap screen. Press a printable key to leave
the bitmap and display its character code in Screen 0:

```bbc
10 M%=8
20 MODE M%:CLG
30 N%=15:IF M%=6 THEN N%=3
40 FOR C%=1 TO N%
50 GCOL 0,C%
60 MOVE 80,40*C%:DRAW 1200,1000-40*C%
70 NEXT
80 REPEAT
90 K%=INKEY(10)
100 UNTIL K%<>-1
110 MODE 0
120 PRINT "MODE ";M%;" KEY CODE ";K%
```

Screen 6 has four logical colours, hence the special value on line 30.
Screens 6 and 7 currently expose only their left 256-pixel half through the
BASIC graphics adapter. Text output is intentionally suppressed while a
bitmap mode is active, so always return to `MODE 0` before printing results.

## MSX2 high-VRAM PLOT/POINT check

This is a compact diagnostic for Screens 5-8. Set `M%` on line 10 to the mode
you want to test. It places two differently coloured points on opposite sides
of a 16 KiB VRAM boundary, reads them back, and prints the results in text
mode:

```bbc
10 M%=8
20 Y%=683:IF M%>6 THEN Y%=342
30 MODE M%:CLG
40 GCOL 0,1:PLOT 69,500,0
50 GCOL 0,2:PLOT 69,500,Y%
60 A%=POINT(500,0):B%=POINT(500,Y%)
70 MODE 0
80 PRINT "MODE ";M%;" COLOURS ";A%;" ";B%
```

Expected output is `COLOURS 1 2`. Repeat with `M%` set to 5, 6, 7, and 8. A
repeated or zero value may indicate incorrect MSX2 SUB-ROM selection or
high-VRAM address aliasing.

## Notes and current limits

- `MODE 0`-`3` are available on MSX1 and MSX2; `MODE 5`-`8` require MSX2.
- Press an ordinary printable key for the `INKEY` examples. Modifier keys by
  themselves do not necessarily produce a BASIC character.
- If an error occurs while a bitmap mode is active, its prompt may be
  invisible because bitmap text rendering is deliberately disabled. Press
  Reset or switch back to `MODE 0` before diagnosing the line.
- Full sound semantics, sprite command syntax, bitmap formats, and current
  limitations are documented in [BBC BASIC media integration](BBC_BASIC_MEDIA.md).
