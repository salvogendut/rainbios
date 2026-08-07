; SPDX-License-Identifier: BSD-3-Clause
;
; IDE boot-sector fixture for the RainBIOS Sunrise IDE bootstrap. The BIOS
; reads this sector into C000h and enters at C000h+1Eh with A = 0 for a cold
; boot and carry set, leaving the cartridge mapped in page 1. The loader then
; reads logical sector 1 through the Sunrise ATA window, verifies its marker,
; and spins at a labelled address the 1983 harness can observe. Sector 1 holds
; the deterministic marker the loader checks.
;
; Assembled as a standalone C000h image; the Makefile passes the resulting
; binary to tools/make_ide_image.py, which places sector 0 and sector 1 into
; a raw IDE image.

; Sunrise ATA window, reachable while the cartridge stays in page 1.
IDE_DATA_LOW    equ #7c00
IDE_DATA_HIGH   equ #7c01
IDE_SEC_CNT     equ #7e02
IDE_LBA0        equ #7e03
IDE_LBA1        equ #7e04
IDE_LBA2        equ #7e05
IDE_DEVICE      equ #7e06
IDE_STATUS      equ #7e07
CHPUT           equ #00a2
POSIT           equ #00c6

BOOT_BUF        equ #c200
LOADER_HL       equ #f3cc
LOADER_DE       equ #f3ce

                org #c000

; Sector 0: standard boot-sector header and the loader.
                db #eb,#1c,#90                 ; jump to C01Eh, nop
                db "RBIDE   "                  ; OEM name
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

; Entry point, matching the MSX-DOS kernel convention C000h+1Eh. HL (disk
; error handler pointer) and DE (ENAKRN entry) are captured for the host
; runner before the loader clobbers them.
ide_boot_entry:
                ld (LOADER_HL),hl
                ld (LOADER_DE),de
                call ide_read_lba1
                jr c,ide_boot_fail
                ld hl,BOOT_BUF
                ld a,(hl)
                cp 'R'
                jr nz,ide_boot_fail
                inc hl
                ld a,(hl)
                cp 'B'
                jr nz,ide_boot_fail
                ld hl,ide_boot_pass_message
                call ide_boot_show_result
ide_boot_pass:
                jr ide_boot_pass
ide_boot_fail:
                ld hl,ide_boot_fail_message
                call ide_boot_show_result
ide_boot_fail_wait:
                jr ide_boot_fail_wait

ide_boot_show_result:
                push hl
                ld h,2
                ld l,12
                call POSIT
                pop hl
ide_boot_show_result_char:
                ld a,(hl)
                or a
                ret z
                call CHPUT
                inc hl
                jr ide_boot_show_result_char

ide_boot_pass_message:
                db "IDE BOOT PASS",0
ide_boot_fail_message:
                db "IDE BOOT FAIL",0

; Read logical sector 1 into BOOT_BUF through the Sunrise ATA window.
ide_read_lba1:
                xor a
                ld (IDE_LBA2),a
                ld (IDE_LBA1),a
                ld a,1
                ld (IDE_LBA0),a
                ld (IDE_SEC_CNT),a
                ld a,#e0                       ; LBA, master (DRV bit clear)
                ld (IDE_DEVICE),a
                ld a,#20                       ; READ SECTORS
                ld (IDE_STATUS),a
                call ide_wait_drq
                ret c
                ld hl,BOOT_BUF
                ld de,256
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

; Wait for BSY clear and DRQ set. The medium is always present in this test,
; so the wait is bounded only by the fixed count.
ide_wait_drq:
                ld bc,#ffff
ide_wait_drq_poll:
                ld a,(IDE_STATUS)
                bit 7,a
                jr nz,ide_wait_drq_cont
                bit 3,a
                jr nz,ide_wait_drq_ready
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

                defs #c200-$,0

; Sector 1: marker data verified by the loader.
sector1_marker:
                db "RB01"
                defs #c400-$,0
