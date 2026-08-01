; SPDX-License-Identifier: BSD-3-Clause
;
; SD Mapper boot-sector fixture for the RainBIOS option-3 bootstrap. The BIOS
; initializes card A, reads this sector into C000h, and enters at C000h+1Eh
; while the controller remains mapped in page 1. The loader reads logical
; sector 1 through the bank-7 SPI window, verifies its marker, and spins at a
; labelled address the 1983 harness can observe.

SD_MAPPER_DATA  equ #7b00
SD_FLAGS        equ #f30a
SD_FLAG_BLOCK   equ #02
BOOT_BUF        equ #c200
CHPUT           equ #00a2
POSIT           equ #00c6

                org #c000

; Sector 0: standard boot-sector header and the loader.
                db #eb,#1c,#90                 ; jump to C01Eh, nop
                db "RBSD    "                  ; OEM name
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

sd_boot_entry:
                call sd_boot_read_lba1
                jr c,sd_boot_fail
                ld hl,BOOT_BUF
                ld a,(hl)
                cp 'R'
                jr nz,sd_boot_fail
                inc hl
                ld a,(hl)
                cp 'B'
                jr nz,sd_boot_fail
                ld hl,sd_boot_pass_message
                call sd_boot_show_result
sd_boot_pass:
                jr sd_boot_pass
sd_boot_fail:
                ld hl,sd_boot_fail_message
                call sd_boot_show_result
sd_boot_fail_wait:
                jr sd_boot_fail_wait

sd_boot_show_result:
                push hl
                ld h,2
                ld l,12
                call POSIT
                pop hl
sd_boot_show_result_char:
                ld a,(hl)
                or a
                ret z
                call CHPUT
                inc hl
                jr sd_boot_show_result_char

sd_boot_pass_message:
                db "SD BOOT PASS",0
sd_boot_fail_message:
                db "SD BOOT FAIL",0

; Read logical sector 1. SDHC uses block argument 1; SDSC uses byte address
; 512. The BIOS publishes the addressing mode in SD_FLAGS before handoff.
sd_boot_read_lba1:
                ld bc,0
                ld a,(SD_FLAGS)
                bit 1,a
                jr z,sd_boot_read_byte_address
                ld de,1
                jr sd_boot_read_command
sd_boot_read_byte_address:
                ld de,512
sd_boot_read_command:
                ld a,#51                       ; CMD17: read single block
                ld l,#ff
                call sd_boot_command
                ret c
                or a
                jr nz,sd_boot_read_error
                call sd_boot_wait_token
                ret c
                ld hl,BOOT_BUF
                ld de,512
sd_boot_read_data:
                ld a,(SD_MAPPER_DATA)
                ld (hl),a
                inc hl
                dec de
                ld a,d
                or e
                jr nz,sd_boot_read_data
                ld a,(SD_MAPPER_DATA)           ; discard data CRC
                ld a,(SD_MAPPER_DATA)
                xor a
                ret
sd_boot_read_error:
                scf
                ret

; Input A is the framed command byte, BCDE the big-endian argument, and L the
; CRC/end byte. Return the first R1 byte with carry clear.
sd_boot_command:
                ld h,a
                ld a,#ff
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
sd_boot_command_response:
                ld a,(SD_MAPPER_DATA)
                bit 7,a
                jr z,sd_boot_command_ready
                dec h
                jr nz,sd_boot_command_response
                scf
                ret
sd_boot_command_ready:
                or a
                ret

sd_boot_wait_token:
                ld bc,#ffff
sd_boot_wait_token_loop:
                ld a,(SD_MAPPER_DATA)
                cp #fe
                jr z,sd_boot_wait_token_ready
                cp #ff
                jr nz,sd_boot_wait_token_error
                dec bc
                ld a,b
                or c
                jr nz,sd_boot_wait_token_loop
sd_boot_wait_token_error:
                scf
                ret
sd_boot_wait_token_ready:
                or a
                ret

                defs #c200-$,0

sector1_marker:
                db "RB01"
                defs #c400-$,0
