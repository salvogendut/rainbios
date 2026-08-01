; SPDX-License-Identifier: BSD-3-Clause
;
; Cold-boot IDE bootstrap for Sunrise IDE cartridges. RainBIOS menu option 3
; probes the slot discovered during the boot scan, maps the cartridge into
; page 1, enables the Sunrise ATA window, reads logical sector 0 into C000h,
; and transfers control to the loader at C000h+1Eh with A = 0 for a cold boot
; and carry set. The cartridge stays mapped in page 1 so the loader can keep
; reading through the ATA window, mirroring how the MSX-DOS disk ROM keeps
; page 1 available to the C000h loader.
;
; The including ROM must place this code in page 0.

; Sunrise IDE register window while the cartridge is mapped into page 1. The
; control register enables the register/data windows and selects the ROM bank.
IDE_DATA_LOW    equ #7c00
IDE_DATA_HIGH   equ #7c01
IDE_SEC_CNT     equ #7e02
IDE_LBA0        equ #7e03
IDE_LBA1        equ #7e04
IDE_LBA2        equ #7e05
IDE_DEVICE      equ #7e06
IDE_STATUS      equ #7e07
IDE_CTRL        equ #4104

IDE_STATUS_BSY_BIT equ 7
IDE_STATUS_DRQ_BIT equ 3
IDE_STATUS_ERR_BIT equ 0

IDE_SECTOR_SIZE equ 512

; Public boot entry used by the interactive menu. Returns to the menu when no
; IDE cartridge is installed or the medium does not carry a bootable sector.
ide_boot:
                ld a,(IDE_SLOT)
                inc a
                ret z
                dec a
                ld h,#40
                call enaslt
                call ide_setup
                xor a
                ld b,a
                ld c,a
                ld hl,#c000
                call ide_read_sector
                jr c,ide_boot_restore
                ld a,(#c000)
                cp #eb
                jr z,ide_boot_go
                cp #e9
                jr z,ide_boot_go
ide_boot_restore:
                ld a,(BIOSSLT)
                ld h,#40
                call enaslt
                ret
ide_boot_go:
                ld sp,#e000
                xor a                          ; A = cold-boot flag
                scf                            ; carry set
                jp #c01e

; Enable the Sunrise register window and select bank 0. Called with the
; cartridge mapped in page 1. The ATA registers and data window both live in
; page 1, so the controller call keeps this ROM visible in page 0.
ide_setup:
                ld a,1
                ld (IDE_CTRL),a
                ret

; Read one 512-byte sector. A is the LBA high byte, B the middle, and C the
; low byte; HL is the destination. Returns carry set on failure.
ide_read_sector:
                ld (IDE_LBA2),a
                ld a,b
                ld (IDE_LBA1),a
                ld a,c
                ld (IDE_LBA0),a
                ld a,1
                ld (IDE_SEC_CNT),a
                ld a,#e0                       ; LBA, master (DRV bit clear)
                ld (IDE_DEVICE),a
                ld a,#20                       ; READ SECTORS
                ld (IDE_STATUS),a
                call ide_wait_drq
                ret c
                ld de,IDE_SECTOR_SIZE/2
ide_read_word:
                ld a,(IDE_DATA_LOW)
                ld (hl),a
                inc hl
                ld a,(IDE_DATA_HIGH)
                ld (hl),a
                inc hl
                dec de
                ld a,d
                or e
                jr nz,ide_read_word
                xor a
                ret

; Wait for BSY clear and DRQ set with a bounded loop. A missing drive leaves
; the status register at 7Fh (error set, no DRQ), so the loop fails instead
; of spinning.
ide_wait_drq:
                ld bc,#ffff
ide_wait_drq_poll:
                ld a,(IDE_STATUS)
                bit IDE_STATUS_BSY_BIT,a
                jr nz,ide_wait_drq_cont
                bit IDE_STATUS_DRQ_BIT,a
                jr nz,ide_wait_drq_ready
                bit IDE_STATUS_ERR_BIT,a
                jr nz,ide_wait_drq_error
ide_wait_drq_cont:
                dec bc
                ld a,b
                or c
                jr nz,ide_wait_drq_poll
                scf
                ret
ide_wait_drq_ready:
                xor a
                ret
ide_wait_drq_error:
                scf
                ret
