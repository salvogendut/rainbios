; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for CHGMOD (005Fh): dispatch the screen mode in A to the
; corresponding initialize routine (0 -> Screen 0, 1 -> Screen 1, 2 -> Screen
; 2, 3 -> Screen 3, 7 -> guarded Screen 7) and return carry set for
; unsupported modes without changing SCRMOD. The probe records observable
; markers for the host runner.

CHGMOD          equ #005f
SCRMOD          equ #fcaf

                org #4000

                db #41,#42                     ; AB signature
                dw chgmod_probe_init
                dw 0,0,0
                defs #4010-$,0

chgmod_probe_init:
                ; CHGMOD 0..3 dispatch to the text/graphics inits.
                xor a
                call CHGMOD
                ld a,(SCRMOD)
                ld (m_scr0),a

                ld a,1
                call CHGMOD
                ld a,(SCRMOD)
                ld (m_scr1),a

                ld a,2
                call CHGMOD
                ld a,(SCRMOD)
                ld (m_scr2),a

                ld a,3
                call CHGMOD
                ld a,(SCRMOD)
                ld (m_scr3),a

                ; Unsupported modes return carry set and leave SCRMOD alone.
                ld a,4
                call CHGMOD
                ld a,0
                adc a,0
                ld (m_carry4),a
                ld a,(SCRMOD)
                ld (m_scr4),a

                ld a,5
                call CHGMOD
                ld a,0
                adc a,0
                ld (m_carry5),a

                ld a,9
                call CHGMOD
                ld a,0
                adc a,0
                ld (m_carry9),a

                ; All checks passed.
                ld a,#5a
                ld (pass_marker),a
chgmod_pass:
                jp chgmod_pass

                defs #8000-$,#ff

; ---- page-3 work area ----
m_scr0          equ #f381
m_scr1          equ #f382
m_scr2          equ #f383
m_scr3          equ #f384
m_carry4        equ #f385
m_scr4          equ #f386
m_carry5        equ #f387
m_carry9        equ #f388
pass_marker     equ #f389
