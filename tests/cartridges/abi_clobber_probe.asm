; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for the partial BIOS entries whose register-clobber and flag
; contracts are characterized in docs/abi/main-bios.csv:
;   DCOMPR (0020h)  compare HL vs DE, set carry/zero, clobber A, preserve BC
;   WRTPSG (0093h)  write E to PSG register A via ports A0h/A1h
;   RDPSG  (0096h)  read PSG register A into A via ports A0h/A2h
; Each entry is called through CALSLT into the BIOS slot with known register
; inputs; the probe records observable markers for the host runner.

CALSLT          equ #001c
BIOSSLT         equ #fcc0

DCOMPR          equ #0020
WRTPSG          equ #0093
RDPSG           equ #0096

                org #4000

                db #41,#42                     ; AB signature
                dw abi_probe_init
                dw 0,0,0
                defs #4010-$,0

abi_probe_init:
                ld a,(BIOSSLT)
                and #03
                ld (bios_slot),a

                ; DCOMPR: HL < DE -> carry set, zero clear.
                ld hl,#1000
                ld de,#2000
                call call_dcompr
                ld a,1
                jr c,abi_dcompr_lt_c
                xor a
abi_dcompr_lt_c:
                ld (marker_dcompr_lt),a
                ld a,1
                jr z,abi_dcompr_lt_z
                xor a
abi_dcompr_lt_z:
                ld (marker_dcompr_lt_z),a

                ; DCOMPR: HL == DE -> carry clear, zero set.
                ld hl,#1234
                ld de,#1234
                call call_dcompr
                ld a,1
                jr c,abi_dcompr_eq_c
                xor a
abi_dcompr_eq_c:
                ld (marker_dcompr_eq_c),a
                ld a,1
                jr z,abi_dcompr_eq_z
                xor a
abi_dcompr_eq_z:
                ld (marker_dcompr_eq),a

                ; DCOMPR: HL > DE -> carry clear.
                ld hl,#3000
                ld de,#2000
                call call_dcompr
                ld a,1
                jr c,abi_dcompr_gt_c
                xor a
abi_dcompr_gt_c:
                ld (marker_dcompr_gt),a

                ; DCOMPR preserves BC.
                ld hl,#1000
                ld de,#2000
                ld bc,#5aa5
                call call_dcompr
                ld a,b
                cp #5a
                jr nz,abi_dcompr_bc_bad
                ld a,c
                cp #a5
                jr nz,abi_dcompr_bc_bad
                ld a,1
                ld (marker_dcompr_bc),a
                jr abi_wrtpsg
abi_dcompr_bc_bad:
                xor a
                ld (marker_dcompr_bc),a

                ; WRTPSG then RDPSG round trip on the mixer register (7).
abi_wrtpsg:
                ld a,7
                ld e,#b8
                call call_wrtpsg
                ld a,7
                call call_rdpsg
                cp #b8
                jr z,abi_psg_ok
                xor a
                ld (marker_psg),a
                jr abi_done
abi_psg_ok:
                ld a,1
                ld (marker_psg),a

abi_done:
                ld a,1
                ld (pass_marker),a
abi_spin:
                jp abi_spin

call_dcompr:
                push ix
                ld ix,DCOMPR
                jr abi_callslt

call_wrtpsg:
                push ix
                ld ix,WRTPSG
                jr abi_callslt

call_rdpsg:
                push ix
                ld ix,RDPSG
                jr abi_callslt

; CALSLT dispatch: IX = entry, IY = BIOS slot.
abi_callslt:
                push iy
                ld a,(bios_slot)
                ld iy,0
                ld iyh,a
                call CALSLT
                pop iy
                pop ix
                ret

; ---- page-3 work area ----
bios_slot       equ #f380
marker_dcompr_lt equ #f381
marker_dcompr_lt_z equ #f382
marker_dcompr_eq_c equ #f383
marker_dcompr_eq equ #f384
marker_dcompr_gt equ #f385
marker_dcompr_bc equ #f386
marker_psg       equ #f387
pass_marker     equ #f388

                defs #8000-$,#ff
