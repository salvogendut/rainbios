; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for the RainBIOS "stub" BIOS entries. Each documented stub entry is
; expected to follow the safe-return contract: `scf; ret` with all registers
; (other than the flags) preserved and no side effects on page-3 work area.
; The probe calls each entry through CALSLT into the BIOS slot with known
; register inputs and records, per entry, a result byte:
;   bit 0 = carry set on return (scf contract)
;   bit 1 = BC/DE/HL preserved
;   bit 2 = A restored to the pre-call value
;
; NMI (0066h) is deliberately excluded: it is an interrupt return (`retn`),
; not a callable subroutine with the scf; ret contract. CHGCAP (0132h) and
; CHGSND (0135h) were implemented in M3 and are covered by their own ABI probe.

CALSLT          equ #001c
BIOSSLT         equ #fcc0

SYNCHR          equ #0008
CHRGTR          equ #0010
OUTDO           equ #0018
GETYPR          equ #0028
INITIO          equ #003b
STRTMS          equ #0099
LPTOUT          equ #00a5
LPTSTT          equ #00a8
CNVCHR          equ #00ab
LFTQ            equ #00f6
PUTQ            equ #00f9
SCALXY          equ #010e
MAPXY           equ #0111
FETCHC          equ #0114
STOREC          equ #0117
SETATR          equ #011a
READC           equ #011d
SETC            equ #0120
NSETCX          equ #0123
GTASPC          equ #0126
PNTINI          equ #0129
SCANR           equ #012c
SCANL           equ #012f
CALBAS          equ #0159

ENTRY_COUNT     equ 23

                org #4000

                db #41,#42                     ; AB signature
                dw stub_probe_init
                dw 0,0,0
                defs #4010-$,0

stub_probe_init:
                ld a,(BIOSSLT)
                and #03
                ld (bios_slot),a
                xor a
                ld (entry_index),a
                jp stub_probe_next

stub_probe_next:
                ld a,(entry_index)
                cp ENTRY_COUNT
                jp z,stub_probe_pass
                ; Entry address for this index into IX.
                ld hl,entry_table
                ld e,a
                ld d,0
                add hl,de
                add hl,de
                ld e,(hl)
                inc hl
                ld d,(hl)
                push de
                pop ix
                xor a
                ld (stub_result),a
                ; Normal registers carry known inputs.
                ld a,#5a
                ld b,#a5
                ld c,#5a
                ld d,#a5
                ld e,#5a
                ld h,#a5
                ld l,#5a
                ; CALSLT target slot.
                ld a,(bios_slot)
                ld iy,0
                ld iyh,a
                call CALSLT
                ; A must be #5a (preserved), carry must be set.
                cp #5a
                jr z,stub_probe_a_ok
                ld a,(stub_result)
                or 4
                ld (stub_result),a
stub_probe_a_ok:
                jr c,stub_probe_carry_ok
                ld a,(stub_result)
                or 1
                ld (stub_result),a
stub_probe_carry_ok:
                ; BC/DE/HL must be #a55a / #a55a / #a55a.
                ld a,b
                cp #a5
                jr nz,stub_probe_store
                ld a,c
                cp #5a
                jr nz,stub_probe_store
                ld a,d
                cp #a5
                jr nz,stub_probe_store
                ld a,e
                cp #5a
                jr nz,stub_probe_store
                ld a,h
                cp #a5
                jr nz,stub_probe_store
                ld a,l
                cp #5a
                jr nz,stub_probe_store
                ld a,(stub_result)
                or 2
                ld (stub_result),a
stub_probe_store:
                ; Store the result byte for this entry.
                ld a,(entry_index)
                ld e,a
                ld d,0
                ld hl,results
                add hl,de
                ld a,(stub_result)
                ld (hl),a
                ld a,(entry_index)
                inc a
                ld (entry_index),a
                jp stub_probe_next

stub_probe_pass:
                ld a,1
                ld (pass_marker),a
stub_probe_spin:
                jp stub_probe_spin

entry_table:
                dw SYNCHR
                dw CHRGTR
                dw OUTDO
                dw GETYPR
                dw INITIO
                dw STRTMS
                dw LPTOUT
                dw LPTSTT
                dw CNVCHR
                dw LFTQ
                dw PUTQ
                dw SCALXY
                dw MAPXY
                dw FETCHC
                dw STOREC
                dw SETATR
                dw READC
                dw SETC
                dw NSETCX
                dw GTASPC
                dw PNTINI
                dw SCANR
                dw SCANL
                dw CALBAS

; ---- page-3 work area ----
bios_slot       equ #f380
entry_index     equ #f381
stub_result     equ #f382
pass_marker     equ #f383
results         equ #f400

                defs #8000-$,#ff
