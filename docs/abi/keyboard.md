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
both keys are held, with interrupts inhibited. `ISCNTC` and `CKCNTC` consume a
latched `INTFLG` event and return carry on a break; a subsequent call returns
clear until another STOP edge arrives. Disk kernels and Nextor use this to
abort I/O.

## Auto-repeat (M3D)

Held keys auto-repeat through `SCNCNT` (`F3F6h`) and `REPCNT` (`F3F7h`). A new
press restarts the delay; when `SCNCNT` reaches zero the first key held across
two scans is re-enqueued and the interval resets to `REPCNT`. Modifiers and
STOP never repeat.

## Function keys (M3D)

`INIFNK` fills `FNKSTR` (`F87Fh`, ten 16-byte strings) with the default
BASIC-oriented strings. `FNKSB` shows or hides the keys according to
`CNSDFG` (`F3DEh`); `ERAFNK` clears the flag and the bottom text line;
`DSPFNK` sets the flag and renders the strings; `TOTEXT` forces the current
text width and refreshes the display.

The openMSX keyboard probe now covers the break latch and consumption, both
STOP variants, buffer clearing, the `CNSDFG` transitions, text-mode forcing,
and auto-repeat.

Dead keys, key click, Code lock, and CAPS behavior beyond the implemented
state/LED remain future compatibility work.
