; SPDX-License-Identifier: BSD-3-Clause
;
; Test shell for DSKCHG without media. A not-ready drive reports an unknown
; change state instead of an error, and GETDPB still publishes the F9 DPB.

PHYDIO          equ #0144
DSKCHG          equ #4013
GETDPB          equ #4016
H_RUNC          equ #fecb

DPB_BASE        equ #8000

                org #4000

                db #41,#42                     ; AB signature
                dw disk_dskchg_no_media_init
                dw 0,0,0
                defs #4010-$,0

                jp disk_phydio                  ; 4010 DSKIO
                jp disk_dskchg                  ; 4013 DSKCHG
                jp disk_getdpb                  ; 4016 GETDPB
                defs #4030-$,#ff

                include "disk_nms8250_driver.asm"

disk_dskchg_no_media_init:
                call disk_driver_init
                ld a,(DRVINF+1)
                ld de,disk_dskchg_no_media_run
                ld hl,H_RUNC
                call disk_set_hook
                ret

disk_dskchg_no_media_run:
                ; With no media the change state is unknown, not an error.
                xor a
                ld b,0
                ld c,#f9
                ld hl,DPB_BASE
                call DSKCHG
                jp c,disk_dskchg_no_media_fail_carry
                or a
                jp nz,disk_dskchg_no_media_fail_a
                ld a,b
                or a
                jp nz,disk_dskchg_no_media_fail_b

                ; GETDPB does not depend on media and still publishes the DPB.
                ld hl,DPB_BASE
                ld de,disk_dskchg_no_media_expected
                xor a
                ld b,#f9
                ld c,#f9
                call GETDPB
                jp c,disk_dskchg_no_media_fail_getdpb
                ld hl,DPB_BASE+1
                ld de,disk_dskchg_no_media_expected
                ld b,18
                call disk_dskchg_no_media_check
                jp c,disk_dskchg_no_media_fail_getdpb

disk_dskchg_no_media_pass:
                jp disk_dskchg_no_media_pass

; Input HL points to the first byte and DE to the expected block; BC counts.
; Carry is set on the first mismatch. Preserves BC, DE, and HL.
disk_dskchg_no_media_check:
                push bc
disk_dskchg_no_media_check_loop:
                ld a,(de)
                cp (hl)
                jr nz,disk_dskchg_no_media_check_fail
                inc hl
                inc de
                djnz disk_dskchg_no_media_check_loop
                pop bc
                or a
                ret
disk_dskchg_no_media_check_fail:
                pop bc
                scf
                ret

disk_dskchg_no_media_expected:
                db #f9                          ; MEDIA
                dw 512                          ; SECBIZ
                db 15                           ; DIRMSK
                db 4                            ; DIRSHFT
                db 1                            ; CLUSMSK
                db 2                            ; CLUSSHFT
                dw 1                            ; FIRFAT
                db 2                            ; FATCNT
                db 112                          ; MAXENT
                dw 14                           ; FIRREC
                dw 714                          ; MAXCLUS
                db 3                            ; FATSIZ
                dw 7                            ; FIRDIR

disk_dskchg_no_media_fail_carry:
                jp disk_dskchg_no_media_fail_carry
disk_dskchg_no_media_fail_a:
                jp disk_dskchg_no_media_fail_a
disk_dskchg_no_media_fail_b:
                jp disk_dskchg_no_media_fail_b
disk_dskchg_no_media_fail_getdpb:
                jp disk_dskchg_no_media_fail_getdpb

                defs #8000-$,#ff
