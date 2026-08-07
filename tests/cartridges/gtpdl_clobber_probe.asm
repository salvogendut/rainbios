; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for the GTPDL (00DEh) paddle read contract, characterized in
; docs/abi/main-bios.csv: reads paddle A as 0-255 by firing the pin-8
; trigger and measuring the one-shot low pulse; without a paddle the line
; stays high and the result is 0. BC/DE are clobbered, HL/IX/IY are
; preserved, and the PSG IOB (R15) is restored. The probe records observable
; markers for the host runner.

GTPDL           equ #00de
PSG_ADDRESS     equ #a0
PSG_READ        equ #a2
PSG_WRITE       equ #a1

                org #4000

                db #41,#42                     ; AB signature
                dw gtpdl_probe_init
                dw 0,0,0
                defs #4010-$,0

gtpdl_probe_init:
                ; Snapshot the PSG IOB (R15) before the call.
                ld a,15
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                ld (r15_before),a

                ; Known HL/IX/IY to check preservation.
                ld hl,#1234
                ld ix,#5678
                ld iy,#9abc

                ; Read paddle 1 with no paddle attached: result must be 0.
                ld a,1
                call GTPDL
                ld (result),a

                ; HL/IX/IY must be preserved.
                ld a,l
                ld (hl_lo),a
                ld a,h
                ld (hl_hi),a
                push ix
                pop de
                ld a,e
                ld (ix_lo),a
                ld a,d
                ld (ix_hi),a
                push iy
                pop de
                ld a,e
                ld (iy_lo),a
                ld a,d
                ld (iy_hi),a

                ; The PSG IOB (R15) must be restored.
                ld a,15
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                ld (r15_after),a

                ; All checks passed.
                ld a,#5a
                ld (pass_marker),a
gtpdl_pass:
                jp gtpdl_pass

                defs #8000-$,#ff

; ---- page-3 work area ----
r15_before      equ #f381
result          equ #f382
hl_lo           equ #f383
hl_hi           equ #f384
ix_lo           equ #f385
ix_hi           equ #f386
iy_lo           equ #f387
iy_hi           equ #f388
r15_after       equ #f389
pass_marker     equ #f38a
