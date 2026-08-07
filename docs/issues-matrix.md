<!-- SPDX-License-Identifier: BSD-3-Clause -->

# RainBIOS issue and milestone matrix

Living tracking document. Updated after every merged pull request: new
milestone progress and any issue moved to closed are recorded here. The
milestone percentages are estimates derived from the roadmap slices
(`docs/ROADMAP.md`); the issue table maps every GitHub issue to its milestone.

## Milestone progress

| Milestone | Est. | Remaining focus |
| --- | --- | --- |
| M0 ROM contract/build | 100% | Deterministic build, ABI metadata |
| M1 reset/slots/RAM/interrupts | ~95% | Hardware cartridge test (deferred); disk ROM now adopts the motor-arm helper |
| M2 MSX1 display/console | ~95% | VRAM-limit hardening done (full-wraparound + crossing coverage); hardware test |
| M3 keyboard/PSG/basic devices | ~95% | Printer calls (LPTOUT/LPTSTT) and touch-panel GTPAD implemented; light-pen/trackball unemulable in openMSX; remaining: selectable frequency/locale |
| M4 cartridge compatibility | ~70% | Redistributable compatibility corpus deferred (TBD) — the only remaining M4 item, gated on sourcing and clearing ROMs for redistribution |
| M5 MSX2 main BIOS/SUB-ROM | ~95% | Disk-file commands (BLTVD etc.) stay safe returns, gated on MSX2 storage boot (M6/M7) |
| M6 completeness/optional | ~76% | Disk baseline, GTPDL, INIFNK, ISCNTC/CKCNTC, CHGMOD, KEYINT gated; remaining: ABI gaps (RESET), loader inputs HL/DE (needs a kernel), GeoBench rendering gap, payload-workload promotion, real-hardware timing |
| M7 disk/IDE boot | ~60% | Filesystem services, formatting, drive B, writable media, other controllers, loader inputs, real-hardware timing |

## Pull request log

| PR | Milestone | Impact |
| --- | --- | --- |
| #90 | M3 | Implement CHGCAP/CHGSND basic-device entries; drop them from the M6 stub gate (23 stubs) |
| #91 | M3 | Restore literal `"`/`'`/`` ` ``/`^` keys; move the accent latch to the dedicated dead-key key; gate with `test-openmsx-bbcbasic-quote` |
| #92 | M2 | VDP port-ordering + VRAM-boundary hardening: DI-atomic pairs, 14-bit wrap, crossing transfers |
| #93 | M4 | Gate the payload-launch register/work-area state with `test-openmsx-payload-state` |
| #94 | M4 | Characterize and gate the cartridge INIT entry state (`test-openmsx-cartridge`/`-expanded-cartridge`) |
| #95 | M4 | Gate the page-2 INIT (mapper-style) cartridge arrangement (`test-openmsx-page2-cartridge`/`test-1983-page2-cartridge`) |
| #96 | M3 | Implement the printer calls LPTOUT/LPTSTT; M6 stub gate now 21 |
| #97 | M3 | Implement the touch-panel GTPAD selectors (UPD7001 serial protocol) |
| #98 | M1 | Disk ROM adopts the motor-arm helper (IM 1 handler stops the motor) |
| #99 | M2 | Full-wraparound VRAM boundary coverage (FULLWRAP/WRAPFILL/LDIRVMW/LDIRMVW) |
| #100 | M6 | Hook-dispatching disk ABI baseline gated (PHYDIO/FORMAT/ISFLIO/OUTDLP/GETVCP/GETVC2) |
| #101 | M6 | GTPDL clobber contract characterized + gated |
| #102 | M6 | INIFNK default function-key strings gated |
| #103 | M6 | ISCNTC/CKCNTC break-consumption contract gated |
| #104 | M6 | CHGMOD screen-mode dispatch gated |
| #105 | M6 | KEYINT VBlank bookkeeping gated |

## Issue matrix

| # | State | Milestone | Title |
| --- | --- | --- | --- |
| 1 | OPEN | M7 | missing feature floppies support |
| 2 | CLOSED | M3 | Keyboard has no CAPS state; SHIFT+letter yields lowercase, breaking typed/pasted text |
| 4 | CLOSED | M2 | Add proper lowercase glyphs to the early console font |
| 6 | CLOSED | M2 | Refine j, k, l, m, t lowercase glyphs for readability |
| 8 | CLOSED | M2 | Redraw lowercase m as the vertically flipped w glyph |
| 10 | CLOSED | M2 | Diagnostics cartridge: Screen 3 and Monitor Color tests fail (CHGCLR/INIMLT stubbed) |
| 12 | CLOSED | M2 | Arkanoid sprites are halved: INITGRP ignores the RG1SAV sprite-size bit |
| 18 | CLOSED | M3 | GeoBench pointer cannot be moved with mouse, joystick, or keyboard |
| 22 | CLOSED | M3 | Complete M3 keyboard input: auto-repeat, break, function keys |
| 24 | CLOSED | M4 | Document embedded Z80 BASIC feasibility and licensing |
| 26 | CLOSED | M3 | Implement M3 line input: INLIN, PINLIN, QINLIN, and BEEP |
| 28 | CLOSED | M3 | Implement M3 international dead-key input |
| 30 | CLOSED | M3 | Implement M3 key click and paddle input (GTPDL) |
| 32 | CLOSED | M3 | Implement M3 mid-line cursor editing and GICINI PLAY init |
| 34 | CLOSED | M2 | Implement M2 cursor movement calls |
| 36 | CLOSED | M2 | Implement M2 VRAM transfer calls with port-ordering conformance |
| 38 | CLOSED | M2 | Implement M2 screen-mode switch calls |
| 40 | CLOSED | M2 | Implement M2 sprite utility calls |
| 42 | CLOSED | M2 | Implement M2 GRPPRT graphics character print |
| 44 | CLOSED | M2 | Implement M2 remaining CHPUT text control characters |
| 46 | CLOSED | M2 | Complete the MSX international character set glyphs |
| 48 | CLOSED | M2 | Initialize TMS9918-compatible VDP state at boot |
| 50 | CLOSED | M2 | Complete M2 color-call conformance |
| 52 | CLOSED | M2 | Complete remaining M2 partials: RDVDP and Screen 3 |
| 56 | CLOSED | M1 | Process broader IM 1 interrupt sources |
| 58 | CLOSED | M1 | Service the disk in the IM 1 handler |
| 60 | CLOSED | M4 | Embed a source-rebuilt Z80 BASIC payload in the main ROM |
| 62 | CLOSED | M4 | Investigate Arkanoid sprite and Sunrise IDE boot regressions after embedded BASIC integration |
| 64 | CLOSED | M5 | M5: MSX2 main-ROM build with V9938 detection and EXBRSA |
| 66 | CLOSED | M5 | M5: SUB-ROM calling contract (SUBROM/EXTROM/CHKSLZ) |
| 68 | CLOSED | M5 | M5: RainBIOS-built SUB-ROM with bitmap modes and palette |
| 69 | CLOSED | M5 | M5: SUB-ROM VDP command transfers and real-time clock |
| 71 | CLOSED | M5 | M5: validate MSX2 firmware at 64 KiB and 128 KiB VRAM |
| 73 | CLOSED | M6 | M6: machine-readable component manifest |
| 75 | CLOSED | M6 | M6: lower-bank headroom size gate |
| 76 | CLOSED | M6 | M6: characterize BIOS stub safe-return contract |
| 78 | CLOSED | M6 | M6: cover all callable BIOS stub entries |
| 80 | CLOSED | M6 | M6: reproducible release bundle |
| 82 | CLOSED | M6 | M6: SPDX 2.3 JSON export |
| 84 | CLOSED | M6 | M6: characterize DCOMPR and PSG clobber/flag contracts |
| 86 | CLOSED | M6 | M6: characterize function-key and text-cursor contracts |
| 88 | CLOSED | M6 | M6: characterize keyboard buffer contracts |
