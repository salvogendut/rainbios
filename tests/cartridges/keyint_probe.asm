; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for KEYINT (0038h): the VBlank service must run H.KEYI, scan the
; keyboard rows, run H.TIMI, and update STATFL and JIFFY. The probe enables
; interrupts, lets the VDP interrupt fire, and records JIFFY's growth and the
; STATFL value for the host runner.

JIFFY           equ #fc9e
STATFL          equ #f3e7
VDP_CONTROL     equ #99

                org #4000

                db #41,#42                     ; AB signature
                dw keyint_probe_init
                dw 0,0,0
                defs #4010-$,0

keyint_probe_init:
                ei
                ld a,(JIFFY)
                ld (m_jiffy0),a

                ; Wait for the first VBlank tick; KEYINT increments JIFFY.
                ld de,9000
keyint_wait:
                ld a,(JIFFY)
                ld b,a
                ld a,(m_jiffy0)
                cp b
                jr nz,keyint_ticked
                dec de
                ld a,d
                or e
                jr nz,keyint_wait
keyint_ticked:
                ld a,(JIFFY)
                ld (m_jiffy1),a
                ld a,(STATFL)
                ld (m_statfl),a

                ld a,#5a
                ld (pass_marker),a
keyint_pass:
                jp keyint_pass

                defs #8000-$,#ff

m_jiffy0        equ #f381
m_jiffy1        equ #f382
m_statfl        equ #f383
pass_marker     equ #f384
