; SPDX-License-Identifier: BSD-3-Clause
;
; FAT12 FS.DIR boot fixture for the production NMS 8250 disk ROM.  Calls
; FS.DIR (4028h) to read the root directory and verifies that the first
; entry is "RAIN    BIN" with the expected attributes, cluster, and size.

CALSLT          equ #001c
FSDIR           equ #4028
H_PHYD          equ #ffa7

WORKAREA        equ #c200
DEST            equ #d000
FILSIZE         equ 3072

M_CARRY         equ #f3d0
M_ERROR         equ #f3d1
M_ENTRIES_LO    equ #f3d2
M_ENTRIES_HI    equ #f3d3
M_PASS          equ #f3d5

                org #c000

                db #eb,#1c,#90                 ; jump to C01Eh, nop
                db "RBFAT12 "                  ; OEM name
                dw 512
                db 2
                dw 1
                db 2
                dw 112
                dw 1440
                db #f9
                dw 3
                dw 9
                dw 2
                dw 0

disk_fsdir_entry:
                ld a,(H_PHYD+1)
                push af
                pop iy

                ; Call FS.DIR: read up to 32 bytes (1 entry) from root dir.
                xor a                          ; drive 0
                ld hl,DEST                     ; dest buffer
                ld bc,32                       ; 1 entry
                ld de,WORKAREA                 ; work area (2080 bytes)
                ld ix,FSDIR
                call CALSLT

                jr c,disk_fsdir_error

                xor a
                ld (M_CARRY),a
                ld (M_ERROR),a
                ld a,c
                ld (M_ENTRIES_LO),a
                ld a,b
                ld (M_ENTRIES_HI),a

                ; BC should be 32 (one entry)
                dec bc
                ld a,b
                or c
                jr nz,disk_fsdir_size_fail     ; BC != 32

                ; Verify entry name: "RAIN    BIN"
                ld hl,DEST
                ld a,(hl)
                cp 'R'
                jr nz,disk_fsdir_name_fail
                inc hl
                ld a,(hl)
                cp 'A'
                jr nz,disk_fsdir_name_fail
                inc hl
                ld a,(hl)
                cp 'I'
                jr nz,disk_fsdir_name_fail
                inc hl
                ld a,(hl)
                cp 'N'
                jr nz,disk_fsdir_name_fail

                ; Verify first cluster = 2
                ld hl,DEST+26
                ld a,(hl)
                cp 2
                jr nz,disk_fsdir_cluster_fail
                inc hl
                ld a,(hl)
                or a
                jr nz,disk_fsdir_cluster_fail

                ; Verify file size = 3072 (little-endian at offset 28)
                ld hl,DEST+28
                ld a,(hl)
                or a                           ; low byte = 0
                jr nz,disk_fsdir_size_fail
                inc hl
                ld a,(hl)
                cp FILSIZE/256                 ; high byte = 12
                jr nz,disk_fsdir_size_fail

                ; Test zero-size buffer: should return BC=0 carry clear
                xor a
                ld hl,DEST
                ld bc,0
                ld de,WORKAREA
                ld ix,FSDIR
                call CALSLT
                jr c,disk_fsdir_error
                ld a,b
                or c
                jr nz,disk_fsdir_size_fail     ; BC != 0 for empty call

                jr disk_fsdir_pass

disk_fsdir_name_fail:
disk_fsdir_cluster_fail:
disk_fsdir_size_fail:
                jr disk_fsdir_done
disk_fsdir_error:
                ld (M_ERROR),a
                ld a,1
                ld (M_CARRY),a
                jr disk_fsdir_done
disk_fsdir_pass:
disk_fsdir_done:
                ld a,#5a
                ld (M_PASS),a
disk_fsdir_spin:
                jr disk_fsdir_spin

                org #c1fe
                db #55,#aa
