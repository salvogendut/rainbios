; SPDX-License-Identifier: BSD-3-Clause
;
; Test shell for the DSKCHG and GETDPB entries of the production NMS 8250
; driver. Runs with a mounted disk image so the first DSKCHG observes a
; changed medium and the second observes an unchanged medium.

PHYDIO          equ #0144
DSKCHG          equ #4013
GETDPB          equ #4016
H_RUNC          equ #fecb
DEVICE          equ #fd99
DISK_SETUP      equ #fb29

DPB_BASE        equ #8000

                org #4000

                db #41,#42                     ; AB signature
                dw disk_dskchg_getdpb_init
                dw 0,0,0
                defs #4010-$,0

                jp disk_phydio                  ; 4010 DSKIO
                jp disk_dskchg                  ; 4013 DSKCHG
                jp disk_getdpb                  ; 4016 GETDPB
                defs #4030-$,#ff

                include "disk_nms8250_driver.asm"

disk_dskchg_getdpb_init:
                call disk_driver_init
                ld a,(DRVINF+1)
                ld de,disk_dskchg_getdpb_run
                ld hl,H_RUNC
                call disk_set_hook
                ret

disk_dskchg_getdpb_run:
                ld a,(DEVICE)
                cp 1
                jp nz,disk_dskchg_getdpb_fail_device
                ld a,(DISK_SETUP)
                or a
                jp nz,disk_dskchg_getdpb_fail_setup

                ; GETDPB rejects a drive other than A.
                ld a,1
                ld b,#f9
                ld c,#f9
                ld hl,DPB_BASE
                call GETDPB
                jp nc,disk_dskchg_getdpb_fail_getdpb_bad_drive
                cp 12
                jp nz,disk_dskchg_getdpb_fail_getdpb_bad_drive
                ld a,b
                or a
                jp nz,disk_dskchg_getdpb_fail_getdpb_bad_drive

                ; GETDPB publishes the F9 DPB at HL+1..HL+18, preserves DE and
                ; HL, and leaves the kernel-owned DRIVE byte at HL and the FAT
                ; pointer at HL+19..HL+20 untouched.
                ld a,#5a
                ld (DPB_BASE),a
                ld a,#a5
                ld (DPB_BASE+19),a
                ld (DPB_BASE+20),a
                xor a
                ld b,#f9
                ld c,#f9
                ld hl,DPB_BASE
                ld de,#cafe
                call GETDPB
                jp c,disk_dskchg_getdpb_fail_getdpb_carry
                or a
                jp nz,disk_dskchg_getdpb_fail_getdpb_a
                ld a,b
                or a
                jp nz,disk_dskchg_getdpb_fail_getdpb_b
                ld a,h
                cp #80
                jp nz,disk_dskchg_getdpb_fail_getdpb_hl
                ld a,l
                cp #00
                jp nz,disk_dskchg_getdpb_fail_getdpb_hl
                ld a,d
                cp #ca
                jp nz,disk_dskchg_getdpb_fail_getdpb_de
                ld a,e
                cp #fe
                jp nz,disk_dskchg_getdpb_fail_getdpb_de
                ld a,(DPB_BASE)
                cp #5a
                jp nz,disk_dskchg_getdpb_fail_getdpb_drive
                ld a,(DPB_BASE+19)
                cp #a5
                jp nz,disk_dskchg_getdpb_fail_getdpb_fat
                ld a,(DPB_BASE+20)
                cp #a5
                jp nz,disk_dskchg_getdpb_fail_getdpb_fat
                ld hl,DPB_BASE+1
                ld de,disk_dskchg_getdpb_expected
                ld b,18
                call disk_dskchg_getdpb_check
                jp c,disk_dskchg_getdpb_fail_getdpb_block

                ; DSKCHG rejects a drive other than A without touching the
                ; controller, so the medium still reports changed below.
                ld a,1
                ld b,0
                ld c,#f9
                ld hl,DPB_BASE
                call DSKCHG
                jp nc,disk_dskchg_getdpb_fail_dskchg_bad_drive
                cp 12
                jp nz,disk_dskchg_getdpb_fail_dskchg_bad_drive
                ld a,b
                or a
                jp nz,disk_dskchg_getdpb_fail_dskchg_bad_drive

                ; The first DSKCHG after mounting reports the medium changed.
                xor a
                ld b,0
                ld c,#f9
                ld hl,DPB_BASE
                call DSKCHG
                jp c,disk_dskchg_getdpb_fail_dskchg_changed
                or a
                jp nz,disk_dskchg_getdpb_fail_dskchg_changed
                ld a,b
                cp #ff
                jp nz,disk_dskchg_getdpb_fail_dskchg_changed

                ; A later DSKCHG reports the medium unchanged.
                xor a
                ld b,0
                ld c,#f9
                ld hl,DPB_BASE
                call DSKCHG
                jp c,disk_dskchg_getdpb_fail_dskchg_unchanged
                or a
                jp nz,disk_dskchg_getdpb_fail_dskchg_unchanged
                ld a,b
                cp 1
                jp nz,disk_dskchg_getdpb_fail_dskchg_unchanged

disk_dskchg_getdpb_pass:
                jp disk_dskchg_getdpb_pass

; Input HL points to the first byte and DE to the expected block; BC counts.
; Carry is set on the first mismatch. Preserves BC, DE, and HL.
disk_dskchg_getdpb_check:
                push bc
disk_dskchg_getdpb_check_loop:
                ld a,(de)
                cp (hl)
                jr nz,disk_dskchg_getdpb_check_fail
                inc hl
                inc de
                djnz disk_dskchg_getdpb_check_loop
                pop bc
                or a
                ret
disk_dskchg_getdpb_check_fail:
                pop bc
                scf
                ret

disk_dskchg_getdpb_expected:
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

disk_dskchg_getdpb_fail_device:
                jp disk_dskchg_getdpb_fail_device
disk_dskchg_getdpb_fail_setup:
                jp disk_dskchg_getdpb_fail_setup
disk_dskchg_getdpb_fail_getdpb_bad_drive:
                jp disk_dskchg_getdpb_fail_getdpb_bad_drive
disk_dskchg_getdpb_fail_getdpb_carry:
                jp disk_dskchg_getdpb_fail_getdpb_carry
disk_dskchg_getdpb_fail_getdpb_a:
                jp disk_dskchg_getdpb_fail_getdpb_a
disk_dskchg_getdpb_fail_getdpb_b:
                jp disk_dskchg_getdpb_fail_getdpb_b
disk_dskchg_getdpb_fail_getdpb_hl:
                jp disk_dskchg_getdpb_fail_getdpb_hl
disk_dskchg_getdpb_fail_getdpb_de:
                jp disk_dskchg_getdpb_fail_getdpb_de
disk_dskchg_getdpb_fail_getdpb_drive:
                jp disk_dskchg_getdpb_fail_getdpb_drive
disk_dskchg_getdpb_fail_getdpb_fat:
                jp disk_dskchg_getdpb_fail_getdpb_fat
disk_dskchg_getdpb_fail_getdpb_block:
                jp disk_dskchg_getdpb_fail_getdpb_block
disk_dskchg_getdpb_fail_dskchg_bad_drive:
                jp disk_dskchg_getdpb_fail_dskchg_bad_drive
disk_dskchg_getdpb_fail_dskchg_changed:
                jp disk_dskchg_getdpb_fail_dskchg_changed
disk_dskchg_getdpb_fail_dskchg_unchanged:
                jp disk_dskchg_getdpb_fail_dskchg_unchanged

                defs #8000-$,#ff
