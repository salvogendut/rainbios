; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for the partial keyboard BIOS entries:
;   CHSNS (009Ch)  report circular key-buffer availability (AF-only change)
;   CHGET (009Fh)  wait for and remove one buffered character, preserving
;                  BC/DE/HL
;   KILBUF (0156h) empty the standard key buffer
; The probe injects a character directly into KEYBUF, sets PUTPNT/GETPNT, and
; calls each entry through CALSLT into the BIOS slot, recording observable
; markers for the host runner.

CALSLT          equ #001c
BIOSSLT         equ #fcc0

CHSNS           equ #009c
CHGET           equ #009f
KILBUF          equ #0156

PUTPNT          equ #f3f8
GETPNT          equ #f3fa
KEYBUF          equ #fbf0
KEYBUF_END      equ #fc18

                org #4000

                db #41,#42                     ; AB signature
                dw kbd_probe_init
                dw 0,0,0
                defs #4010-$,0

kbd_probe_init:
                ld a,(BIOSSLT)
                and #03
                ld (bios_slot),a

                ; --- CHSNS on an empty buffer reports zero.
                call call_kilbuf
                call call_chsns
                ld a,1
                jr z,kbd_empty_z
                xor a
kbd_empty_z:
                ld (marker_chsns_empty),a

                ; --- Inject 'A' (0x41) into KEYBUF.
                ld a,#41
                ld (KEYBUF),a
                ld hl,KEYBUF+1
                ld (PUTPNT),hl
                ld hl,KEYBUF
                ld (GETPNT),hl

                ; --- CHSNS with data reports nonzero.
                call call_chsns
                ld a,1
                jr nz,kbd_data_nz
                xor a
kbd_data_nz:
                ld (marker_chsns_data),a

                ; --- CHGET returns the injected character, preserves BC/DE/HL.
                ld b,#a5
                ld c,#5a
                ld d,#a5
                ld e,#5a
                ld h,#a5
                ld l,#5a
                call call_chget
                cp #41
                jr z,kbd_chget_char_ok
                xor a
                ld (marker_chget_char),a
                jr kbd_chget_regs
kbd_chget_char_ok:
                ld a,1
                ld (marker_chget_char),a
kbd_chget_regs:
                ; BC/DE/HL must be preserved.
                ld a,b
                cp #a5
                jr nz,kbd_chget_regs_bad
                ld a,c
                cp #5a
                jr nz,kbd_chget_regs_bad
                ld a,d
                cp #a5
                jr nz,kbd_chget_regs_bad
                ld a,e
                cp #5a
                jr nz,kbd_chget_regs_bad
                ld a,h
                cp #a5
                jr nz,kbd_chget_regs_bad
                ld a,l
                cp #5a
                jr nz,kbd_chget_regs_bad
                ld a,1
                ld (marker_chget_regs),a
                jr kbd_chget_ptr
kbd_chget_regs_bad:
                xor a
                ld (marker_chget_regs),a
kbd_chget_ptr:
                ; GETPNT must have advanced to KEYBUF+1 (0xFBF1).
                ld hl,(GETPNT)
                ld a,h
                cp #fb
                jr nz,kbd_chget_ptr_bad
                ld a,l
                cp #f1
                jr nz,kbd_chget_ptr_bad
                ld a,1
                ld (marker_chget_ptr),a
                jr kbd_chget_after
kbd_chget_ptr_bad:
                xor a
                ld (marker_chget_ptr),a
kbd_chget_after:
                ; --- CHSNS after the single read reports empty again.
                call call_chsns
                ld a,1
                jr z,kbd_after_empty
                xor a
kbd_after_empty:
                ld (marker_chsns_after),a

kbd_done:
                ld a,1
                ld (pass_marker),a
kbd_spin:
                jp kbd_spin

call_chsns:
                push ix
                ld ix,CHSNS
                jr abi_callslt

call_chget:
                push ix
                ld ix,CHGET
                jr abi_callslt

call_kilbuf:
                push ix
                ld ix,KILBUF
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
marker_chsns_empty equ #f381
marker_chsns_data equ #f382
marker_chget_char equ #f383
marker_chget_regs equ #f384
marker_chget_ptr equ #f385
marker_chsns_after equ #f386
pass_marker     equ #f387

                defs #8000-$,#ff
