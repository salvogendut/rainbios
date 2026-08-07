; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for INIFNK (003Eh): fills FNKSTR (F87Fh) with the ten default
; 16-byte function-key strings. The probe zeroes FNKSTR, sets a sentinel in
; FNKFLG, calls INIFNK, and records the first default string, a sample of the
; last string, and the untouched FNKFLG for the host runner.

INIFNK          equ #003e
FNKSTR          equ #f87f
FNKFLG          equ #fbce

                org #4000

                db #41,#42                     ; AB signature
                dw inifnk_probe_init
                dw 0,0,0
                defs #4010-$,0

inifnk_probe_init:
                ; Zero FNKSTR and set a sentinel in FNKFLG.
                ld hl,FNKSTR
                ld (hl),0
                ld de,FNKSTR+1
                ld bc,159
                ldir
                ld a,#5a
                ld (FNKFLG),a

                ; Call INIFNK.
                call INIFNK

                ; Record the first default string "LIST" CR.
                ld a,(FNKSTR)
                ld (m_f0),a
                ld a,(FNKSTR+1)
                ld (m_f1),a
                ld a,(FNKSTR+2)
                ld (m_f2),a
                ld a,(FNKSTR+3)
                ld (m_f3),a
                ld a,(FNKSTR+4)
                ld (m_f4),a
                ld a,(FNKSTR+5)
                ld (m_f5),a

                ; Record a sample of the last string "SCREEN 0" (starts at
                ; FNKSTR + 9*16 = FNKSTR + 144).
                ld a,(FNKSTR+144)
                ld (m_last0),a
                ld a,(FNKSTR+148)
                ld (m_last4),a
                ld a,(FNKSTR+149)
                ld (m_last5),a

                ; FNKFLG must be untouched by INIFNK.
                ld a,(FNKFLG)
                ld (m_fnkflg),a

                ; All checks passed.
                ld a,#5a
                ld (pass_marker),a
inifnk_pass:
                jp inifnk_pass

                defs #8000-$,#ff

; ---- page-3 work area ----
m_f0            equ #f381
m_f1            equ #f382
m_f2            equ #f383
m_f3            equ #f384
m_f4            equ #f385
m_f5            equ #f386
m_last0         equ #f387
m_last4         equ #f388
m_last5         equ #f389
m_fnkflg        equ #f38a
pass_marker     equ #f38b
