; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for ISCNTC (00BAh) / CKCNTC (00BDh): consume a latched INTFLG break.
; With a pending break, the entry clears INTFLG and the key buffer and returns
; carry set; without a break it returns carry clear. CKCNTC shares the
; behavior. The probe records observable markers for the host runner.

ISCNTC          equ #00ba
CKCNTC          equ #00bd
INTFLG          equ #fc9b
PUTPNT          equ #f3f8
GETPNT          equ #f3fa
KEYBUF          equ #fbf0

                org #4000

                db #41,#42                     ; AB signature
                dw iscntc_probe_init
                dw 0,0,0
                defs #4010-$,0

iscntc_probe_init:
                ; Seed a Ctrl-STOP break and one pending key character.
                ld a,3
                ld (INTFLG),a
                ld hl,KEYBUF+1
                ld (GETPNT),hl
                ld hl,KEYBUF
                ld (PUTPNT),hl

                ; ISCNTC with a break: carry set, INTFLG cleared, buffer
                ; cleared.
                call ISCNTC
                ld a,0
                adc a,0
                ld (m_break_carry),a
                ld a,(INTFLG)
                ld (m_break_intflg),a
                ld hl,(GETPNT)
                ld de,(PUTPNT)
                ld a,l
                cp e
                jr nz,iscntc_buffer_dirty
                ld a,h
                cp d
                jr nz,iscntc_buffer_dirty
                ld a,1
                jr iscntc_buffer_checked
iscntc_buffer_dirty:
                xor a
iscntc_buffer_checked:
                ld (m_break_cleared),a

                ; ISCNTC again with no break: carry clear.
                call ISCNTC
                ld a,0
                adc a,0
                ld (m_twice_carry),a

                ; CKCNTC with a STOP break: carry set, INTFLG cleared.
                ld a,4
                ld (INTFLG),a
                call CKCNTC
                ld a,0
                adc a,0
                ld (m_ckcntc_carry),a
                ld a,(INTFLG)
                ld (m_ckcntc_intflg),a

                ; ISCNTC with no break latched: carry clear.
                xor a
                ld (INTFLG),a
                call ISCNTC
                ld a,0
                adc a,0
                ld (m_clean_carry),a

                ; All checks passed.
                ld a,#5a
                ld (pass_marker),a
iscntc_pass:
                jp iscntc_pass

                defs #8000-$,#ff

; ---- page-3 work area ----
m_break_carry   equ #f381
m_break_intflg  equ #f382
m_break_cleared equ #f383
m_twice_carry   equ #f384
m_ckcntc_carry  equ #f385
m_ckcntc_intflg equ #f386
m_clean_carry   equ #f387
pass_marker     equ #f388
