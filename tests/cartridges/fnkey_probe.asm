; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for the partial text/function-key BIOS entries:
;   FNKSB  (00C9h)  display or erase the function keys per CNSDFG
;   ERAFNK (00CCh)  clear CNSDFG and erase the bottom text row
;   DSPFNK (00CFh)  set CNSDFG and render FNKSTR on the bottom row
;   TOTEXT (00D2h)  force the text mode and refresh the function keys
;   POSIT  (00C6h)  set CSRX/CSRY to (H, L) without bounds checking
; Each entry is called through CALSLT into the BIOS slot; the probe records
; observable work-area and name-table markers for the host runner.

CALSLT          equ #001c
BIOSSLT         equ #fcc0

CHGMOD          equ #005f
RDVRM           equ #004a
ERAFNK          equ #00cc
DSPFNK          equ #00cf
FNKSB           equ #00c9
TOTEXT          equ #00d2
POSIT           equ #00c6

CSRY            equ #f3dc
CSRX            equ #f3dd
CNSDFG          equ #f3de
FNKSTR          equ #f87f
NAMBAS          equ #f922
LINLEN          equ #f3b0
CRTCNT          equ #f3b1
SCRMOD          equ #fcaf

                org #4000

                db #41,#42                     ; AB signature
                dw fnkey_probe_init
                dw 0,0,0
                defs #4010-$,0

fnkey_probe_init:
                ld a,(BIOSSLT)
                and #03
                ld (bios_slot),a

                ; Switch to Screen 0 so the name table is active.
                ld a,0
                call call_chgmod

                ; --- POSIT: position the cursor to row 3, column 5 (one-based).
                ld h,5
                ld l,3
                call call_posit
                ld a,(CSRX)
                ld (marker_posit_x),a
                ld a,(CSRY)
                ld (marker_posit_y),a

                ; --- ERAFNK: clears CNSDFG and erases the bottom row.
                call call_erafnk
                ld a,(CNSDFG)
                ld (marker_erafnk_cns),a
                ; Read the first byte of the last row in the name table.
                call bottom_row_addr
                call call_rdvrm
                ld (marker_erafnk_vram),a

                ; --- DSPFNK: sets CNSDFG, positions the cursor to the last
                ; row, and renders the function-key strings.
                call call_dspfnk
                ld a,(CNSDFG)
                ld (marker_dspfnk_cns),a
                ld a,(CSRY)
                ld (marker_dspfnk_row),a

                ; --- FNKSB with CNSDFG set: shows keys (CNSDFG stays set).
                call call_fnksb
                ld a,(CNSDFG)
                ld (marker_fnksb_on),a

                ; --- FNKSB with CNSDFG clear: erases (CNSDFG stays clear).
                xor a
                ld (CNSDFG),a
                call call_fnksb
                ld a,(CNSDFG)
                ld (marker_fnksb_off),a

                ; --- TOTEXT: forces Screen 0 and refreshes per CNSDFG.
                ld a,#ff
                ld (CNSDFG),a
                ld a,2
                call call_chgmod
                call call_totext
                ld a,(SCRMOD)
                ld (marker_totext_mode),a
                ld a,(CNSDFG)
                ld (marker_totext_cns),a

fnkey_probe_done:
                ld a,1
                ld (pass_marker),a
fnkey_spin:
                jp fnkey_spin

; Compute the VRAM address of the first byte of the bottom text row in HL.
bottom_row_addr:
                ld hl,(NAMBAS)
                ld a,(CRTCNT)
                dec a
                ld b,a
                ld a,(LINLEN)
                ld e,a
                ld d,0
bottom_row_loop:
                add hl,de
                djnz bottom_row_loop
                ret

call_chgmod:
                push ix
                ld ix,CHGMOD
                jr abi_callslt

call_rdvrm:
                push ix
                ld ix,RDVRM
                jr abi_callslt

call_posit:
                push ix
                ld ix,POSIT
                jr abi_callslt

call_erafnk:
                push ix
                ld ix,ERAFNK
                jr abi_callslt

call_dspfnk:
                push ix
                ld ix,DSPFNK
                jr abi_callslt

call_fnksb:
                push ix
                ld ix,FNKSB
                jr abi_callslt

call_totext:
                push ix
                ld ix,TOTEXT
                jr abi_callslt

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
marker_posit_x  equ #f381
marker_posit_y  equ #f382
marker_erafnk_cns equ #f383
marker_erafnk_vram equ #f384
marker_dspfnk_cns equ #f385
marker_dspfnk_row equ #f386
marker_fnksb_on equ #f387
marker_fnksb_off equ #f388
marker_totext_mode equ #f389
marker_totext_cns equ #f38a
pass_marker     equ #f38b

                defs #8000-$,#ff
