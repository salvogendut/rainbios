; SPDX-License-Identifier: BSD-3-Clause
;
; Cold-boot storage bootstrap for Sunrise IDE and SD Mapper V2 cartridges.
; RainBIOS menu option 3 maps the slot discovered during the boot scan into
; page 1, selects the matching controller backend, reads logical sector 0 into
; C000h, and transfers control to the loader at C000h+1Eh with A = 0 for a cold
; boot and carry set. The cartridge stays mapped in page 1 so the loader can
; keep reading through its controller window, mirroring how the MSX-DOS disk
; ROM keeps page 1 available to the C000h loader.
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

STORAGE_SECTOR_SIZE equ 512

; SD Mapper V2 registers while controller subslot 0 is mapped into page 1.
; Bank 7 exposes a byte-wide SPI endpoint throughout 7B00h-7EFFh.
SD_MAPPER_BANK  equ #6000
SD_MAPPER_DATA  equ #7b00
SD_MAPPER_SELECT equ #7ff0

SD_FLAG_V2      equ #01
SD_FLAG_BLOCK   equ #02

; Public boot entry used by the interactive menu. Returns to the menu when no
; supported cartridge is installed or the medium has no bootable sector.
ide_boot:
                ld a,(IDE_SLOT)
                inc a
                ret z
                dec a
                ld h,#40
                call enaslt
                call sd_mapper_probe
                jr c,ide_boot_sunrise
                call sd_mapper_setup
                jr c,ide_boot_restore
                xor a
                ld b,a
                ld c,a
                ld hl,#c000
                call sd_mapper_read_sector
                jr ide_boot_read_done
ide_boot_sunrise:
                call ide_setup
                xor a
                ld b,a
                ld c,a
                ld hl,#c000
                call ide_read_sector
ide_boot_read_done:
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
                ld de,STORAGE_SECTOR_SIZE/2
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

; Bank 7 exposes SD Mapper's configuration/status register at 7FF0h. Challenge
; it with deselected and card-A states; valid configuration uses bits 0-1 and
; valid card status bits 0-2. Two status reads also drain the changed flag. The
; expanded-slot ID confirms the otherwise ambiguous all-equal response.
; Carry is clear only for SD Mapper.
sd_mapper_probe:
                ld a,7
                ld (SD_MAPPER_BANK),a
                xor a
                ld (SD_MAPPER_SELECT),a
                ld a,(SD_MAPPER_SELECT)
                and #fc
                jr nz,sd_mapper_probe_absent
                ld b,a                         ; mapper switch configuration
                ld a,1
                ld (SD_MAPPER_SELECT),a
                ld a,(SD_MAPPER_SELECT)
                ld c,a                         ; first status, changed bit set
                and #f8
                jr nz,sd_mapper_probe_absent
                ld a,(SD_MAPPER_SELECT)
                ld d,a                         ; second status drains changed
                and #f8
                jr nz,sd_mapper_probe_absent
                ld a,d
                cp b
                jr nz,sd_mapper_probe_present
                ld a,c
                cp b
                jr nz,sd_mapper_probe_present
                ld a,(IDE_SLOT)
                bit 7,a
                jr z,sd_mapper_probe_absent
sd_mapper_probe_present:
                or a
                ret
sd_mapper_probe_absent:
                scf
                ret

; Initialize card A in SPI mode. The sequence supports both SDHC block
; addressing and SDSC byte addressing, with bounded ACMD41 retries.
sd_mapper_setup:
                xor a
                ld (SD_FLAGS),a
                ld (SD_MAPPER_SELECT),a
                ld b,10
sd_mapper_setup_clocks:
                ld a,#ff
                ld (SD_MAPPER_DATA),a
                djnz sd_mapper_setup_clocks

                ld a,1
                ld (SD_MAPPER_SELECT),a
                ld a,(SD_MAPPER_SELECT)
                bit 1,a                        ; selected card absent
                jp nz,sd_mapper_setup_error

                ld a,#40                       ; CMD0: enter idle state
                ld bc,0
                ld de,0
                ld l,#95
                call sd_mapper_command
                jp c,sd_mapper_setup_error
                cp 1
                jp nz,sd_mapper_setup_error

                ld a,#48                       ; CMD8: interface condition
                ld bc,0
                ld de,#01aa
                ld l,#87
                call sd_mapper_command
                jp c,sd_mapper_setup_error
                cp 1
                jr z,sd_mapper_setup_v2
                cp 5                           ; legacy card: illegal CMD8
                jp nz,sd_mapper_setup_error
                jr sd_mapper_setup_acmd
sd_mapper_setup_v2:
                ld a,(SD_MAPPER_DATA)
                ld a,(SD_MAPPER_DATA)
                ld a,(SD_MAPPER_DATA)
                cp 1
                jp nz,sd_mapper_setup_error
                ld a,(SD_MAPPER_DATA)
                cp #aa
                jp nz,sd_mapper_setup_error
                ld a,SD_FLAG_V2
                ld (SD_FLAGS),a

sd_mapper_setup_acmd:
                ld hl,#ffff
                ld (SD_INIT_TRIES),hl
sd_mapper_setup_acmd_loop:
                ld a,#77                       ; CMD55: next is application
                ld bc,0
                ld de,0
                ld l,#ff
                call sd_mapper_command
                jp c,sd_mapper_setup_error
                cp 2                           ; idle or ready are valid
                jp nc,sd_mapper_setup_error

                ld bc,0
                ld de,0
                ld a,(SD_FLAGS)
                and SD_FLAG_V2
                jr z,sd_mapper_setup_acmd_arg
                ld b,#40                       ; request SDHC block addressing
sd_mapper_setup_acmd_arg:
                ld a,#69                       ; ACMD41: initialize card
                ld l,#ff
                call sd_mapper_command
                jp c,sd_mapper_setup_error
                or a
                jr z,sd_mapper_setup_ocr
                cp 1
                jp nz,sd_mapper_setup_error
                ld hl,(SD_INIT_TRIES)
                dec hl
                ld (SD_INIT_TRIES),hl
                ld a,h
                or l
                jr nz,sd_mapper_setup_acmd_loop
                jr sd_mapper_setup_error

sd_mapper_setup_ocr:
                ld a,#7a                       ; CMD58: read OCR/CCS
                ld bc,0
                ld de,0
                ld l,#ff
                call sd_mapper_command
                jr c,sd_mapper_setup_error
                or a
                jr nz,sd_mapper_setup_error
                ld a,(SD_MAPPER_DATA)
                bit 6,a
                jr z,sd_mapper_setup_ocr_tail
                ld a,(SD_FLAGS)
                or SD_FLAG_BLOCK
                ld (SD_FLAGS),a
sd_mapper_setup_ocr_tail:
                ld a,(SD_MAPPER_DATA)
                ld a,(SD_MAPPER_DATA)
                ld a,(SD_MAPPER_DATA)
                ld a,(SD_FLAGS)
                bit 1,a
                jr nz,sd_mapper_setup_ready

                ld a,#50                       ; CMD16: 512-byte SDSC block
                ld bc,0
                ld de,512
                ld l,#ff
                call sd_mapper_command
                jr c,sd_mapper_setup_error
                or a
                jr nz,sd_mapper_setup_error
sd_mapper_setup_ready:
                xor a
                ret
sd_mapper_setup_error:
                scf
                ret

; Send a six-byte command and wait for an R1 response. Input A is the framed
; command byte, BCDE the big-endian argument, and L the CRC/end byte.
sd_mapper_command:
                ld h,a
                ld a,#ff                       ; inter-command clocks
                ld (SD_MAPPER_DATA),a
                ld a,h
                ld (SD_MAPPER_DATA),a
                ld a,b
                ld (SD_MAPPER_DATA),a
                ld a,c
                ld (SD_MAPPER_DATA),a
                ld a,d
                ld (SD_MAPPER_DATA),a
                ld a,e
                ld (SD_MAPPER_DATA),a
                ld a,l
                ld (SD_MAPPER_DATA),a
                ld h,32
sd_mapper_command_response:
                ld a,(SD_MAPPER_DATA)
                bit 7,a
                jr z,sd_mapper_command_ready
                dec h
                jr nz,sd_mapper_command_response
                scf
                ret
sd_mapper_command_ready:
                or a
                ret

; Read one 512-byte sector. A is the LBA high byte, B the middle, and C the
; low byte; HL is the destination. SDHC uses the LBA directly, while SDSC uses
; a byte address formed by shifting the LBA left nine bits.
sd_mapper_read_sector:
                push hl
                ld e,c
                ld d,b
                ld c,a
                ld b,0
                ld a,(SD_FLAGS)
                bit 1,a
                jr nz,sd_mapper_read_arg_ready
                ld a,9
sd_mapper_read_shift:
                sla e
                rl d
                rl c
                rl b
                dec a
                jr nz,sd_mapper_read_shift
sd_mapper_read_arg_ready:
                ld a,#51                       ; CMD17: read single block
                ld l,#ff
                call sd_mapper_command
                jr c,sd_mapper_read_fail_pop
                or a
                jr nz,sd_mapper_read_fail_pop
                call sd_mapper_wait_token
                jr c,sd_mapper_read_fail_pop
                pop hl
                ld de,STORAGE_SECTOR_SIZE
sd_mapper_read_data:
                ld a,(SD_MAPPER_DATA)
                ld (hl),a
                inc hl
                dec de
                ld a,d
                or e
                jr nz,sd_mapper_read_data
                ld a,(SD_MAPPER_DATA)           ; discard data CRC
                ld a,(SD_MAPPER_DATA)
                xor a
                ret
sd_mapper_read_fail_pop:
                pop hl
                scf
                ret

sd_mapper_wait_token:
                ld bc,#ffff
sd_mapper_wait_token_loop:
                ld a,(SD_MAPPER_DATA)
                cp #fe
                jr z,sd_mapper_wait_token_ready
                cp #ff
                jr nz,sd_mapper_wait_token_error
                dec bc
                ld a,b
                or c
                jr nz,sd_mapper_wait_token_loop
sd_mapper_wait_token_error:
                scf
                ret
sd_mapper_wait_token_ready:
                or a
                ret
