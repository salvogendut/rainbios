; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for the M6 hook-dispatching disk ABI entries and the PSG voice
; pointer entries, characterized in docs/abi/main-bios.csv:
;   PHYDIO (0144h)  dispatches to H_PHYD; safe default reports not supported
;   FORMAT (0147h)  dispatches to H_FORM; safe default reports not supported
;   ISFLIO (014Ah)  dispatches to H_ISFL; safe default reports no active I/O
;   OUTDLP (014Dh)  dispatches to H_OUTD; safe default reports not supported
;   GETVCP (0150h)  HL = VCBA + 2 + VOICEN*37
;   GETVC2 (0153h)  HL = VCBA + L + VOICEN*37
; The entries live in the page-0 BIOS, so a cartridge calls them directly and
; records observable markers for the host runner.

H_FORM          equ #ffac
VCBA            equ #fb41
VOICEN          equ #fb38

PHYDIO          equ #0144
FORMAT          equ #0147
ISFLIO          equ #014a
OUTDLP          equ #014d
GETVCP          equ #0150
GETVC2          equ #0153

                org #4000

                db #41,#42                     ; AB signature
                dw disk_abi_probe_init
                dw 0,0,0
                defs #4010-$,0

disk_abi_probe_init:
                ; PHYDIO: the H_PHYD safe default returns carry set.
                call PHYDIO
                ld a,0
                adc a,0
                ld (m_phydio),a

                ; FORMAT: the H_FORM safe default returns carry set.
                call FORMAT
                ld a,0
                adc a,0
                ld (m_format),a

                ; OUTDLP: the H_OUTD safe default returns carry set.
                call OUTDLP
                ld a,0
                adc a,0
                ld (m_outdlp),a

                ; ISFLIO: the H_ISFL safe default returns A = 0.
                call ISFLIO
                ld (m_isflio),a

                ; GETVCP: with VOICEN = 0, HL = VCBA + 2 = FB43h.
                xor a
                ld (VOICEN),a
                call GETVCP
                ld a,l
                ld (m_getvcp),a
                ld a,h
                ld (m_getvcp+1),a
                ld a,0
                adc a,0
                ld (m_getvcp_c),a

                ; GETVC2 with L = 5: HL = VCBA + 5 = FB46h.
                ld l,5
                call GETVC2
                ld a,l
                ld (m_getvc2),a
                ld a,h
                ld (m_getvc2+1),a

                ; FORMAT dispatches to an installed H_FORM hook.
                ld a,#3e
                ld (H_FORM),a
                ld a,#42
                ld (H_FORM+1),a
                ld a,#c9
                ld (H_FORM+2),a
                call FORMAT
                ld (m_format_hook),a

                ; All checks passed.
                ld a,#5a
                ld (pass_marker),a
disk_abi_pass:
                jp disk_abi_pass

                defs #8000-$,#ff

; ---- page-3 work area ----
m_phydio        equ #f381
m_format        equ #f382
m_outdlp        equ #f383
m_isflio        equ #f384
m_getvcp        equ #f385       ; 2 bytes
m_getvcp_c      equ #f387
m_getvc2        equ #f388       ; 2 bytes
m_format_hook   equ #f38a
pass_marker     equ #f38b
