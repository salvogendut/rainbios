; SPDX-License-Identifier: BSD-3-Clause
;
; Probe for the partial keyboard BIOS entries:
;   CHSNS (009Ch)  report circular key-buffer availability (AF-only change)
;   CHGET (009Fh)  wait for and remove one buffered character, preserving
;                  BC/DE/HL
;   KILBUF (0156h) empty the standard key buffer
;   CHGCAP (0132h) set the CAPS lamp from A (00 = lamp on, non-00 = lamp off)
;                  on keyboard PPI port-C bit 6, preserving BC/DE/HL
;   CHGSND (0135h) set the key-click switch from A (00 = click off, non-00 =
;                  click on) through CLIKSW, preserving BC/DE/HL
; The probe injects a character directly into KEYBUF, sets PUTPNT/GETPNT, and
; calls each entry through CALSLT into the BIOS slot, recording observable
; markers for the host runner. CHGCAP is verified by reading the keyboard
; lamp port back so only bit 6 changes; CHGSND by reading CLIKSW.

CALSLT          equ #001c
BIOSSLT         equ #fcc0

CHSNS           equ #009c
CHGET           equ #009f
KILBUF          equ #0156
CHGCAP          equ #0132
CHGSND          equ #0135

PPI_CONTROL_C   equ #aa
CLIKSW          equ #f3db
PUTPNT          equ #f3f8
GETPNT          equ #f3fa
KEYBUF          equ #fbf0
KEYBUF_END      equ #fc18

; The CAPS lamp is keyboard PPI port-C bit 6: 0 = lamp on, 1 = lamp off.
CAPS_LAMP_BIT   equ #40

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

                ; --- CHGCAP with A=0 turns the CAPS lamp on (bit 6 clear).
                ld a,#5a
                ld b,#a5
                ld c,#5a
                ld d,#a5
                ld e,#5a
                ld h,#a5
                ld l,#5a
                xor a
                call call_chgcap
                in a,(PPI_CONTROL_C)
                and CAPS_LAMP_BIT
                jr z,kbd_chgcap_on_ok
                xor a
                ld (marker_chgcap_on),a
                jr kbd_chgcap_on_regs
kbd_chgcap_on_ok:
                ld a,1
                ld (marker_chgcap_on),a
kbd_chgcap_on_regs:
                ld a,b
                cp #a5
                jr nz,kbd_chgcap_on_regs_bad
                ld a,c
                cp #5a
                jr nz,kbd_chgcap_on_regs_bad
                ld a,d
                cp #a5
                jr nz,kbd_chgcap_on_regs_bad
                ld a,e
                cp #5a
                jr nz,kbd_chgcap_on_regs_bad
                ld a,h
                cp #a5
                jr nz,kbd_chgcap_on_regs_bad
                ld a,l
                cp #5a
                jr nz,kbd_chgcap_on_regs_bad
                ld a,1
                ld (marker_chgcap_regs),a
                jr kbd_chgsnd
kbd_chgcap_on_regs_bad:
                xor a
                ld (marker_chgcap_regs),a

                ; --- CHGSND with a non-zero flag turns the click on (CLIKSW
                ;     becomes non-zero); with zero it turns the click off.
kbd_chgsnd:
                ld b,#a5
                ld c,#5a
                ld d,#a5
                ld e,#5a
                ld h,#a5
                ld l,#5a
                ld a,1
                call call_chgsnd
                ld a,(CLIKSW)
                or a
                jr nz,kbd_chgsnd_on_ok
                xor a
                ld (marker_chgsnd_on),a
                jr kbd_chgsnd_regs
kbd_chgsnd_on_ok:
                ld a,1
                ld (marker_chgsnd_on),a
kbd_chgsnd_regs:
                ld b,#a5
                ld c,#5a
                ld d,#a5
                ld e,#5a
                ld h,#a5
                ld l,#5a
                xor a
                call call_chgsnd
                ld a,(CLIKSW)
                or a
                jr nz,kbd_chgsnd_off_bad
                ld a,1
                ld (marker_chgsnd_off),a
                jr kbd_chgsnd_regs_check
kbd_chgsnd_off_bad:
                xor a
                ld (marker_chgsnd_off),a
kbd_chgsnd_regs_check:
                ld a,b
                cp #a5
                jr nz,kbd_chgsnd_regs_bad
                ld a,c
                cp #5a
                jr nz,kbd_chgsnd_regs_bad
                ld a,d
                cp #a5
                jr nz,kbd_chgsnd_regs_bad
                ld a,e
                cp #5a
                jr nz,kbd_chgsnd_regs_bad
                ld a,h
                cp #a5
                jr nz,kbd_chgsnd_regs_bad
                ld a,l
                cp #5a
                jr nz,kbd_chgsnd_regs_bad
                ld a,1
                ld (marker_chgsnd_regs),a
                jr kbd_done
kbd_chgsnd_regs_bad:
                xor a
                ld (marker_chgsnd_regs),a

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

call_chgcap:
                push ix
                ld ix,CHGCAP
                jr abi_callslt_arg

call_chgsnd:
                push ix
                ld ix,CHGSND
                jr abi_callslt_arg

abi_callslt:
                push iy
                ld a,(bios_slot)
                ld iy,0
                ld iyh,a
                call CALSLT
                pop iy
                pop ix
                ret

; CALSLT variant for entries that read their argument from A. The caller's
; AF/BC/DE/HL inputs are parked on the stack while the slot is loaded into
; IY, then restored before the call so the target receives the real values.
abi_callslt_arg:
                push af
                push bc
                push de
                push hl
                ld a,(bios_slot)
                ld iy,0
                ld iyh,a
                pop hl
                pop de
                pop bc
                pop af
                call CALSLT
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
marker_chgcap_on equ #f388
marker_chgcap_regs equ #f389
marker_chgsnd_on equ #f38a
marker_chgsnd_off equ #f38b
marker_chgsnd_regs equ #f38c
pass_marker     equ #f387

                defs #8000-$,#ff
