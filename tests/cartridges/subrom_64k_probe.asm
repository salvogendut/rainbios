; SPDX-License-Identifier: BSD-3-Clause
;
; Probe cartridge for the RainBIOS MSX2 SUB-ROM on a 64 KiB VRAM machine.
; Calls EXTROM into CHGMOD and even-address 16-bit WRTVRM/RDVRM round trips
; and records observable markers in page-3 RAM for the host-side runner.
;
; openMSX's V9938 64 KiB model (issue #1157) is known to mishandle CPU access
; to odd VRAM addresses, so the round trips here use even addresses only.

EXTROM          equ #015F
SCRMOD          equ #fcaf

SUB_CHGMOD      equ #00d1
SUB_WRTVRM      equ #0109
SUB_RDVRM       equ #010d

                org #4000

                db #41,#42                     ; AB signature
                dw subrom_64k_init
                dw 0,0,0
                defs #4010-$,0

subrom_64k_init:
                ; CHGMOD 5: SCRMOD and table bases should update.
                ld a,5
                call subrom_call_chgmod
                ld a,(SCRMOD)
                ld (marker_scrmod5),a

                ; Even-address 16-bit VRAM round trips at several boundaries.
                ld hl,#0000
                ld a,#a0
                call subrom_call_wrvrm
                ld hl,#0000
                call subrom_call_rdvrm
                ld (marker_v0),a

                ld hl,#3ffe
                ld a,#a2
                call subrom_call_wrvrm
                ld hl,#3ffe
                call subrom_call_rdvrm
                ld (marker_v1),a

                ld hl,#4000
                ld a,#a4
                call subrom_call_wrvrm
                ld hl,#4000
                call subrom_call_rdvrm
                ld (marker_v2),a

                ld hl,#7ffe
                ld a,#a6
                call subrom_call_wrvrm
                ld hl,#7ffe
                call subrom_call_rdvrm
                ld (marker_v3),a

                ld hl,#8000
                ld a,#a8
                call subrom_call_wrvrm
                ld hl,#8000
                call subrom_call_rdvrm
                ld (marker_v4),a

                ld hl,#fffe
                ld a,#aa
                call subrom_call_wrvrm
                ld hl,#fffe
                call subrom_call_rdvrm
                ld (marker_v5),a

                ; CHGMOD 8 to exercise the high 64K region of the mode.
                ld a,8
                call subrom_call_chgmod
                ld a,(SCRMOD)
                ld (marker_scrmod8),a
                ld hl,#8000
                ld a,#ac
                call subrom_call_wrvrm
                ld hl,#8000
                call subrom_call_rdvrm
                ld (marker_v6),a

subrom_64k_spin:
                jp subrom_64k_spin

subrom_call_chgmod:
                push ix
                ld ix,SUB_CHGMOD
                call EXTROM
                pop ix
                ret

subrom_call_wrvrm:
                push ix
                ld ix,SUB_WRTVRM
                call EXTROM
                pop ix
                ret

subrom_call_rdvrm:
                push ix
                ld ix,SUB_RDVRM
                call EXTROM
                pop ix
                ret

marker_scrmod5   equ #f380
marker_scrmod8   equ #f381
marker_v0        equ #f382
marker_v1        equ #f383
marker_v2        equ #f384
marker_v3        equ #f385
marker_v4        equ #f386
marker_v5        equ #f387
marker_v6        equ #f388

                defs #8000-$,#ff
