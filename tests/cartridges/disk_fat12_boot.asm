; SPDX-License-Identifier: BSD-3-Clause
;
; FAT12 FS.LOAD boot fixture for the production NMS 8250 disk ROM. The disk
; ROM reads this sector into C000h and enters at C000h+1Eh, where the loader
; calls FS.LOAD (4025h) through an inter-slot call to load RAIN.BIN (3072
; bytes) from the deterministic FAT12 fixture disk into page-3 RAM. After the
; call the loader verifies the byte pattern at the destination and writes the
; results into the F3D0h marker block so the 1983 harness can validate the
; complete read path: BPB parse, root-directory walk, FAT12 cluster chain, and
; PHYDIO sector delivery.
;
; Assembled as a standalone C000h image; tools/make_fat12_disk.py places the
; first 512 bytes as the boot sector of the FAT12 probe disk.

CALSLT          equ #001c
FSLOAD          equ #4025
H_PHYD          equ #ffa7

FILENAME        equ #c100
WORKAREA        equ #c200
DEST            equ #d000

M_CARRY         equ #f3d0
M_ERROR         equ #f3d1
M_SIZE_LO       equ #f3d2
M_SIZE_HI       equ #f3d3
M_COMPARE       equ #f3d4
M_PASS          equ #f3d5

                org #c000

; Sector 0: standard boot-sector BPB matching the FAT12 fixture geometry.
                db #eb,#1c,#90                 ; jump to C01Eh, nop
                db "RBFAT12 "                  ; OEM name
                dw 512                         ; bytes per sector
                db 2                           ; sectors per cluster
                dw 1                           ; reserved sectors
                db 2                           ; FAT copies
                dw 112                         ; root directory entries
                dw 1440                        ; total sectors
                db #f9                         ; media descriptor
                dw 3                           ; FAT size in sectors
                dw 9                           ; sectors per track
                dw 2                           ; heads
                dw 0                           ; hidden sectors

; Entry point, matching the MSX-DOS kernel convention C000h+1Eh.
disk_fat12_entry:
                ld a,(H_PHYD+1)                ; disk ROM slot ID
                push af
                pop iy                         ; IY high byte = slot

                xor a                          ; drive 0
                ld hl,FILENAME
                ld de,DEST
                ld bc,WORKAREA
                ld ix,FSLOAD
                call CALSLT

                jr c,disk_fat12_error

                xor a
                ld (M_CARRY),a
                ld (M_ERROR),a
                ld a,c
                ld (M_SIZE_LO),a
                ld a,b
                ld (M_SIZE_HI),a
                jr disk_fat12_verify

disk_fat12_error:
                ld (M_ERROR),a                 ; A = error code from FS.LOAD
                ld a,1
                ld (M_CARRY),a
                xor a
                ld (M_COMPARE),a
                jr disk_fat12_done

disk_fat12_verify:
                ld hl,DEST
                ld a,(hl)
                cp #52
                jr nz,disk_fat12_compare_fail
                inc hl
                ld a,(hl)
                cp #42
                jr nz,disk_fat12_compare_fail
                inc hl
                ld a,(hl)
                cp #4f
                jr nz,disk_fat12_compare_fail
                inc hl
                ld a,(hl)
                cp #31
                jr nz,disk_fat12_compare_fail

                ld hl,DEST+1023
                ld a,(hl)
                cp #fa
                jr nz,disk_fat12_compare_fail

                ld hl,DEST+1024
                ld a,(hl)
                cp #01
                jr nz,disk_fat12_compare_fail

                ld hl,DEST+2047
                ld a,(hl)
                cp #fa
                jr nz,disk_fat12_compare_fail

                ld hl,DEST+2048
                ld a,(hl)
                cp #01
                jr nz,disk_fat12_compare_fail

                ld hl,DEST+3071
                ld a,(hl)
                cp #fa
                jr nz,disk_fat12_compare_fail

                ld a,#5a
                ld (M_COMPARE),a
                jr disk_fat12_done

disk_fat12_compare_fail:
                xor a
                ld (M_COMPARE),a

disk_fat12_done:
                ld a,#5a
                ld (M_PASS),a
disk_fat12_pass:
                jr disk_fat12_pass

; Filename string embedded at the advertised address.
                org FILENAME
                db "RAIN    BIN"

; Boot sector signature at the end of sector 0.
                org #c1fe
                db #55,#aa
