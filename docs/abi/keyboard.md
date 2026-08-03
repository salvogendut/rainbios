<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Keyboard service status

RainBIOS M3A provides a first compatible keyboard-input path for applications
which use the published MSX BIOS interfaces.

At cold boot, RainBIOS initializes `OLDKEY` and `NEWKEY` to `FFh` and resets
the standard 40-byte circular key buffer at `KEYBUF`. On every VBlank,
`KEYINT` samples international keyboard rows 0 through 8, retains active-low
matrix state, and enqueues newly pressed keys.

The current translation covers:

- printable international-layout keys, including shifted punctuation;
- Shift and Control modifiers, with Control-A through Control-Z;
- Return, Backspace, Tab, Escape, Space, Home, Insert, Delete, Stop, and the
  four cursor keys.

`SNSMAT` exposes a raw active-low matrix row. `CHSNS` reports whether the
buffer contains a character, `CHGET` waits for and removes one character, and
`KILBUF` empties the buffer. The service probe verifies raw matrix input,
Shift-A translation, register preservation, pointer movement, and a blocking
`CHGET` awakened by Return. The BBC BASIC integration probe additionally
exercises interactive editing through these calls.

## Stop and break (M3D)

The STOP key latches `INTFLG` (`FC9Bh`): Ctrl-STOP writes `03h`, STOP alone
writes `04h`, and both clear the key buffer so a break discards pending input.
`BREAKX` tests the physical Ctrl-STOP matrix directly and returns carry while
both keys are held without changing the caller's interrupt state. A released
STOP returns `A=10h`; a released Control key after held STOP returns `A=02h`,
matching the open C-BIOS convention used by some software. `ISCNTC` and
`CKCNTC` consume a latched `INTFLG` event and return carry on a break; a
subsequent call returns clear until another STOP edge arrives. Disk kernels
and Nextor use this to abort I/O.

## Auto-repeat (M3D)

Held keys auto-repeat through `SCNCNT` (`F3F6h`) and `REPCNT` (`F3F7h`). A new
press restarts the delay; when `SCNCNT` reaches zero the first key held across
two scans is re-enqueued and the interval resets to `REPCNT`. Modifiers and
STOP never repeat.

## Function keys (M3D)

`INIFNK` fills `FNKSTR` (`F87Fh`, ten 16-byte strings) with the default
BASIC-oriented strings. `FNKSB` shows or hides the keys according to
`CNSDFG` (`F3DEh`); `ERAFNK` clears the flag and bottom text line directly in
VRAM without changing the caller's cursor position;
`DSPFNK` sets the flag and renders the strings; `TOTEXT` forces the current
text width and refreshes the display.

The openMSX keyboard probe now covers the break latch and consumption, both
STOP variants, buffer clearing, the `CNSDFG` transitions, `ERAFNK` cursor
preservation and full-row clearing, text-mode forcing, and auto-repeat.

## Line input (M3E)

`PINLIN` reads keyboard input into `BUFFER` (`F55Eh`) until Return or a
Ctrl-STOP break. `INLIN` behaves the same and sets `AUTFLG` (`F6AAh`);
`QINLIN` prints a question mark and a space before `INLIN`. On Return, the
line is echoed (unless `AUTFLG` is set), terminated with CR, `HL` returns
`BUFFER-1`, `B` holds the character count, and carry is clear. On a break,
carry is set and the partial line is discarded.

The input line supports mid-line editing. The cursor starts at the input
start and `B` counts the characters while a separate cursor tracks the
insertion point (kept across the `BREAKX` keyboard-matrix calls via the
stack). Typing inserts at the cursor, Backspace removes the character
before it, Delete removes the character under it, the cursor-left and
cursor-right keys move the cursor, and Home moves to the start. After each
edit the line is redrawn from its saved start position and the screen
cursor is placed at the cursor offset. The buffer is updated in place
regardless of `AUTFLG`; only the echo is suppressed for automatic input.

The keyboard probe covers the basic line, end-of-line Backspace, and a
mid-line sequence (insert, Backspace, Delete, Home) plus cursor-right
append.

`BEEP` emits a short tone on PSG channel A.

## Dead keys (M3F)

The international accent glyphs are dead keys: pressing `` ` `` (grave), `'`
(acute), `^` (circumflex), or `"` (umlaut) latches `DEADST` (`FCACh`) and
emits nothing. The next key combines with the accent when it is a, e, i, o, u,
or y, producing the standard MSX international accented character (for example
`` ` `` + a gives à, `'` + e gives é, `^` + e gives ê, `"` + u gives ü, `"` + y
gives ÿ). A letter with no accented form, any other key, or Ctrl emits the
plain character and clears `DEADST`. The accented byte codes follow the MSX
international character set (0x80-0xA3); the project font glyphs for those
codes are part of the M2 character-set work.

The keyboard probe covers grave+`a`, acute+`e`, a non-combinable letter, and
a letter with no accented form.

With `CLIKSW` (`F3DBh`) nonzero, each new key press drives the 1-bit click
line (PPI port-C bit 7) high for a couple of frames. The keyboard probe
verifies the click bit fires and returns to low.

## PSG and PLAY work-area initialization (M3)

`GICINI` (`0090h`) programs the PSG registers R0-R15 and then initializes
the PLAY statement work area: `QUEUES` (`F3F3h`) is pointed at the queue
table (`QUETAB`, `F959h`), `FRCNEW` (`F3F5h`) is set to 255, and the voice
static data block (`FB35h`-`FB90h`, PRSCNT through VCBC) and the three
voice queues (`F959h`-`FAF4h`, QUETAB through VOICCQ) are cleared, so
`MUSICF` (`FB3Fh`) and `PLYCNT` (`FB40h`) start at zero. RainBIOS itself
does not run BASIC's PLAY interpreter, but the work area matches the
published MSX layout so a caller can install a music player or interpreter
over a clean state.

Dead-key+Shift is not yet distinguished (each accent glyph maps to one accent
type), Code lock, and CAPS behavior beyond the implemented state/LED remain
future compatibility work.

## Text cursor movement (M2)

`RIGHTC` (`00FCh`) and `LEFTC` (`00FFh`) move the cursor one column right or
left within `CSRX`, stopping at the line end (`LINLEN`) and column one.
`UPC` (`0102h`) and `DOWNC` (`0108h`) move `CSRY` one row, stopping at the
top and at the bottom row (`CRTCNT`). `TUPC` (`0105h`) and `TDOWNC` (`010Bh`)
behave the same but scroll the text when the cursor is already on the
boundary row: `TUPC` scrolls the display down one row and `TDOWNC` scrolls
it up one row, using the same Screen 0/1/2 name, pattern, and colour layouts
as the wrap scroll in `CHPUT`. The cursor-move probe verifies each move, both
edges, and both scrolling directions against the seeded name table.
