<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Controller and mouse ABI

RainBIOS implements the standard main-BIOS cursor, joystick, trigger, and MSX
mouse interfaces over the international keyboard matrix and PSG ports
`A0h-A2h`.

## PSG initialization

The current partial `GICINI` (`0090h`) initializes PSG R0-R15, including the
standard R0=`55h`, R7=`B8h`, and R11=`0Bh` defaults. R7 keeps PSG port A as
input and port B as output. R15=`8Fh` makes both button pairs inputs, holds both
pin-8 mouse strobes low, selects connector 1, and leaves the active-low Kana LED
off. PLAY statement work-area initialization remains pending. The PSG write
sequence is atomic, and the public entry enables maskable interrupts before
returning. Cold boot uses the same private initialization body without leaving
its interrupt-disabled section.

Controller calls read and modify R15 instead of replacing it. They preserve the
Kana LED and the unrelated connector while selecting the requested connector,
making its button lines inputs, and holding its pin 8 low after a read.

## Directions and triggers

`GTSTCK` (`00D5h`) accepts the standard selectors:

| A | Source |
| --- | --- |
| `0` | Cursor keys |
| `1` | Joystick connector 1 |
| `2` | Joystick connector 2 |

It returns `0` for center, then `1` through `8` for Up, Up-right, Right,
Down-right, Down, Down-left, Left, and Up-left. Invalid selectors and
electrically contradictory direction pairs return center. The published call
permits all registers to change.

`GTTRIG` (`00D8h`) returns `FFh` while pressed and `00h` while released:

| A | Source |
| --- | --- |
| `0` | Space |
| `1` / `2` | Button A on connector 1 / 2 |
| `3` / `4` | Button B on connector 1 / 2 |

Invalid selectors return `00h`. Only `AF` changes; `BC`, `DE`, and `HL` are
preserved.

`GICINI`, `GTSTCK`, `GTTRIG`, and `GTPAD` enable maskable interrupts before
returning, matching the current main-BIOS call convention and the earlier
neutral controller stubs.

## Mouse

`GTPAD` (`00DBh`) implements the standard mouse subset:

| A | Result |
| --- | --- |
| `12` / `16` | Request and cache movement from connector 1 / 2; returns `FFh` |
| `13` / `17` | Cached signed X movement, positive right |
| `14` / `18` | Cached signed Y movement, positive down |
| `15` / `19` | `00h` |

Requests perform the standard X-high, X-low, Y-high, Y-low pin-8 transaction
and cache the two's-complement bytes in the published `PADX`/`PADY` work areas.
Call the request and coordinate selectors together; another request replaces
the shared cache. Mouse buttons use `GTTRIG`.

Selectors 12 and 16 are requests, not presence probes, and therefore return
`FFh` even when no mouse is connected. A floating joystick connector currently
produces the common `01h,01h` empty-port coordinate signature. Software should
not infer device presence from the request return alone.

Touch panels, light pens, explicit mouse-versus-trackball detection, and
selectors outside 12-19 currently return `00h`.

`GTPDL` (`00DEh`) reads paddles 1-8: it selects the interface, fires the pin-8
trigger, and measures the one-shot low pulse width on the PSG port-A pin with a
bounded loop, returning 0-255. With no paddle the line stays high and the
result is 0; paddles 9-12 are unsupported and return 0. R15 is restored before
returning.

## Validation

`make test-openmsx-controller` calls only public BIOS entries and covers all
eight cursor directions, active and neutral connector reads, Space and trigger
register preservation, both mouse request/cache groups, empty and idle mouse
results, button lines, strict PSG port directions, seeded R15 preservation,
and the no-paddle GTPDL neutral result.
