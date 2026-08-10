; SPDX-License-Identifier: BSD-3-Clause
;
; RainBIOS generic WD2793 disk extension.  Provides a 16 KiB page-1 ROM with
; the standard MSX-DOS disk entries (DSKIO, DSKCHG, GETDPB, CHOICE, DSKFMT,
; MTOFF), a clean-room DOS1 boot/BDOS layer, optional FAT12 filesystem
; services (FS.LOAD, FS.DIR, FS.WRITE), and a cold-boot bootstrap hook.
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

                jp disk_dos_init               ; 4030 $INIT
                defs #4034-$,#ff
                jp disk_dos_bios               ; 4034 $$BIOS
disk_rom_init:
                call disk_driver_init
                jp disk_driver_init_boot
                defs #4078-$,#ff
                jp disk_dos_console_in         ; 4078 $IN
                defs #408f-$,#ff
                jp disk_dos_console_out_a      ; 408F $OUT

                defs #41ef-$,#ff
                jp disk_bdos_version           ; 41EF CPM version

                ; Published DOS1 FCB service addresses.
                defs #4462-$,#ff
                jp disk_bdos_open               ; 4462 OPEN
                defs #456f-$,#ff
                jp disk_bdos_close              ; 456F CLOSE
                defs #4775-$,#ff
                jp disk_bdos_sequential_read    ; 4775 READ
                defs #4788-$,#ff
                jp disk_bdos_random_read        ; 4788 RREAD
                defs #47b2-$,#ff
                jp disk_bdos_random_block_read  ; 47B2 RDBLK
                defs #4fb8-$,#ff
                jp disk_bdos_find_first         ; 4FB8 SFIRST
                defs #5006-$,#ff
                jp disk_bdos_find_next          ; 5006 SNEXT
                defs #504e-$,#ff
                jp disk_bdos_login_vector       ; 504E LOGIN
                defs #5058-$,#ff
                jp disk_bdos_set_dta            ; 5058 SETDTA
                defs #505d-$,#ff
                jp disk_bdos_allocation         ; 505D ALLOC
                defs #509f-$,#ff
                jp disk_bdos_disk_reset         ; 509F DSKRES
                defs #50c4-$,#ff
                jp disk_bdos_default_drive      ; 50C4 GETDRV
                defs #50c8-$,#ff
                jp disk_bdos_set_random_record  ; 50C8 SETRND
                defs #50d5-$,#ff
                jp disk_bdos_select_disk        ; 50D5 SELDSK

                ; Fixed DOS-kernel console ABI used by MSXDOS.SYS. CONOUT is
                ; the one-byte E-to-A prefix immediately before OUT.
                defs #53a7-$,#ff
                ld a,e                          ; 53A7 CONOUT
                jp disk_dos_console_out_a       ; 53A8 OUT
                defs #543c-$,#ff
                jp disk_dos_bios                ; 543C CONSTA
                defs #5445-$,#ff
                jp disk_dos_console_in          ; 5445 CONIN
                defs #544e-$,#ff
                jp disk_dos_console_in          ; 544E IN
                defs #5454-$,#ff
                jp disk_bdos_direct_console     ; 5454 RAWIO
                defs #5462-$,#ff
                jp disk_dos_console_in          ; 5462 RAWINP
                defs #5465-$,#ff
                jp disk_dos_console_out         ; 5465 LIST
                defs #546e-$,#ff
                jp disk_dos_console_in          ; 546E READER
                defs #5474-$,#ff
                jp disk_dos_console_out         ; 5474 PUNCH

                defs #56d0-$,#ff
                jp disk_bdos_dispatch_l         ; 56D0 $$DISP
                jp disk_dos_runtime_init        ; 56D3 FUNCTI fallback
                defs #576f-$,#ff
                jp disk_dos_runtime_init        ; 576F $$INIT

                defs #6300-$,#ff

                include "disk_driver.asm"
                include "disk_fat12.asm"
                include "disk_bdos.asm"

disk_no_choice:
                ld hl,0
                ret

                defs #8000-$,#ff
