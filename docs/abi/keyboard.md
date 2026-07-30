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

This is intentionally a partial M3 implementation. Auto-repeat, Caps/Code
locks, dead keys, function-key expansion, key click, and full Stop/Break
semantics remain future compatibility work.
