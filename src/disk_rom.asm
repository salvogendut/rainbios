; SPDX-License-Identifier: BSD-3-Clause
;
; RainBIOS generic WD2793 disk extension.  Provides a 16 KiB page-1 ROM with
; the standard MSX-DOS disk entries (DSKIO, DSKCHG, GETDPB, CHOICE, DSKFMT,
; MTOFF) plus optional FAT12 filesystem services (FS.LOAD, FS.DIR, FS.WRITE)
; and a cold-boot bootstrap hook.
;
; The driver defaults to the NMS 8250 WD2793 memory window at #7ff8 but can
; be redirected to any address by defining FDC_BASE before inclusion.

                org #4000

                db #41,#42                     ; AB signature
                dw disk_rom_init
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs #4010-$,0

                jp disk_phydio                 ; 4010 DSKIO
                jp disk_dskchg                 ; 4013 DSKCHG
                jp disk_getdpb                 ; 4016 GETDPB
                jp disk_choice                 ; 4019 CHOICE
                jp disk_dskfmt                 ; 401C DSKFMT
                jp disk_motor_off              ; 401F MTOFF
                ret                            ; 4022 BASIC
                defs #4025-$,#ff
                jp disk_fs_load                ; 4025 FS.LOAD
                jp disk_fs_dir                 ; 4028 FS.DIR
                jp disk_fs_write               ; 402B FS.WRITE
                defs #4030-$,#ff

                include "disk_driver.asm"
                include "disk_fat12.asm"

disk_no_choice:
                ld hl,0
                ret

disk_rom_init:
                call disk_driver_init
                jp disk_driver_init_boot

                defs #8000-$,#ff
