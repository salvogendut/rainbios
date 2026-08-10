; SPDX-License-Identifier: BSD-3-Clause
;
; Source-built DOS1 boot sector.  It uses only the published F37Dh ABI to
; open MSXDOS.SYS, set the DTA to 0100h, read the exact file byte count, and
; transfer control.  tools/make_bdos_disk.py supplies the matching FAT12 file.

BDOS            equ #f37d
FCB             equ #c100
LOADER_HL       equ #f3cc
LOADER_DE       equ #f3ce

                org #c000

                db #eb,#1c,#90
                db "RBDOS   "
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

disk_bdos_boot_entry:
                ld (LOADER_HL),hl
                ld (LOADER_DE),de

                ld de,FCB
                ld c,#0f                     ; OPEN
                call BDOS
                or a
                jr nz,disk_bdos_boot_fail

                ld de,#0100
                ld c,#1a                     ; SET DTA
                call BDOS

                ld hl,(FCB+16)               ; exact file size
                ld a,1                        ; byte-sized records
                ld (FCB+14),a
                xor a
                ld (FCB+15),a
                ld de,FCB
                ld c,#27                     ; RANDOM BLOCK READ
                call BDOS
                or a
                jr nz,disk_bdos_boot_fail
                call #f368                    ; keep Disk ROM visible for $INIT
                jp #0100

disk_bdos_boot_fail:
                jr disk_bdos_boot_fail

                org FCB
                db 0,"MSXDOS  SYS"
                defs 24,0

                org #c1fe
                db #55,#aa
