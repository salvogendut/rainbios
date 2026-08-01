; SPDX-License-Identifier: BSD-3-Clause
;
; MSX-DOS boot-sector fixture for the production NMS 8250 disk ROM. The disk
; ROM reads this sector into C000h and enters at C000h+1Eh with A = 0 for a
; cold boot and carry set, then the loader reads one further sector through
; DSKIO, verifies its marker, and spins at a labelled address the 1983 harness
; can observe. Sector 1 holds the deterministic marker the loader checks.
;
; Assembled as a standalone C000h image; the Makefile passes the resulting
; binary to tools/make_boot_disk.py, which places sector 0 and sector 1 into a
; 720 KiB F9 image.

BOOT_BUF        equ #c200
DSKIO           equ #4010
CALSLT          equ #001c
H_PHYD          equ #ffa7

                org #c000

; Sector 0: standard boot-sector header and the loader.
                db #eb,#1c,#90                 ; jump to C01Eh, nop
                db "RBDOS   "                  ; OEM name
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
disk_boot_entry:
                ld a,(H_PHYD+1)                ; disk ROM slot ID
                push af
                pop iy                         ; IY high byte = slot
                xor a                          ; drive 0, read (carry clear)
                ld ix,DSKIO
                ld hl,BOOT_BUF
                ld de,1                        ; logical sector 1
                ld bc,#01f9
                call CALSLT
                jr c,disk_boot_fail
                ld hl,BOOT_BUF
                ld a,(hl)
                cp 'R'
                jr nz,disk_boot_fail
                inc hl
                ld a,(hl)
                cp 'B'
                jr nz,disk_boot_fail
disk_boot_pass:
                jr disk_boot_pass
disk_boot_fail:
                jr disk_boot_fail

                defs #c200-$,0

; Sector 1: marker data verified by the loader.
sector1_marker:
                db "RB01"
                defs #c400-$,0
