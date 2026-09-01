; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only disk extension ROM. It validates its slot identity, installs
; representative disk hooks, and takes control through H_RUNC after RainBIOS
; prepares the disk boot context.

                org #4000

                db #41,#42                     ; AB signature
                dw disk_rom_init
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs #4010-$,0

H_PHYD          equ #ffa7
H_RUNC          equ #fecb
DEVICE          equ #fd99
DISK_SETUP      equ #fb29
DRVINF          equ #fb21
DISK_SLOT       equ #8f
INIT_DUPLICATE  equ #f30f

disk_rom_init:
; F300h is disk-system work RAM, so a storage cartridge may overwrite it.
; Also remember whether RainBIOS invokes this INIT more than once.
                ld a,(H_RUNC)
                cp #c9
                jr z,disk_rom_init_first
                ld a,1
                ld (INIT_DUPLICATE),a
                jr disk_rom_init_continue
disk_rom_init_first:
                xor a
                ld (INIT_DUPLICATE),a
disk_rom_init_continue:
                ld a,#52
                ld (#f300),a

                push iy
                pop de
                ld a,d
                cp DISK_SLOT
                jr nz,disk_rom_boot_fail_iy

                ld a,1
                ld (DRVINF),a
                ld a,DISK_SLOT
                ld (DRVINF+1),a

                ld de,disk_phyd
                ld hl,H_PHYD
                call disk_set_hook
                ld de,disk_rom_boot_check
                ld hl,H_RUNC
                call disk_set_hook
                ret

disk_set_hook:
                ld (hl),#f7                   ; RST 30h
                inc hl
                ld (hl),DISK_SLOT
                inc hl
                ld (hl),e
                inc hl
                ld (hl),d
                inc hl
                ld (hl),#c9
                ret

disk_phyd:
                scf
                ret

disk_rom_boot_check:
                ld a,(INIT_DUPLICATE)
                or a
                jr nz,disk_rom_boot_fail_duplicate
                ld a,(H_PHYD)
                cp #f7
                jr nz,disk_rom_boot_fail_phyd
                ld a,(DRVINF)
                or a
                jr z,disk_rom_boot_fail_drvinf
                ld a,(DEVICE)
                cp 1
                jr nz,disk_rom_boot_fail_device
                ld a,(DISK_SETUP)
                or a
                jr nz,disk_rom_boot_fail_setup
                ld a,(H_RUNC)
                cp #f7
                jr nz,disk_rom_boot_fail_runc

disk_rom_boot_pass:
                jr disk_rom_boot_pass

disk_rom_boot_fail_iy:
                jr disk_rom_boot_fail_iy
disk_rom_boot_fail_phyd:
                jr disk_rom_boot_fail_phyd
disk_rom_boot_fail_drvinf:
                jr disk_rom_boot_fail_drvinf
disk_rom_boot_fail_device:
                jr disk_rom_boot_fail_device
disk_rom_boot_fail_setup:
                jr disk_rom_boot_fail_setup
disk_rom_boot_fail_runc:
                jr disk_rom_boot_fail_runc
disk_rom_boot_fail_duplicate:
                jr disk_rom_boot_fail_duplicate

                defs #8000-$,#ff
