; SPDX-License-Identifier: BSD-3-Clause
;
; Test shell for the production NMS 8250 driver on read-only media. It
; installs a bootstrap hook, exercises parameter/write errors, then verifies
; multi-sector reads across side, track, and RAM-page boundaries.

PHYDIO          equ #0144
H_RUNC          equ #fecb
DEVICE          equ #fd99
DISK_SETUP      equ #fb29
JIFFY           equ #fc9e
DISK_MOTOR_DEADLINE equ #f310

                org #4000

                db #41,#42                     ; AB signature
                dw disk_phydio_test_init
                dw 0,0,0
                defs #4010-$,0

                jp disk_phydio
                defs #4030-$,#ff

                include "disk_nms8250_driver.asm"

disk_phydio_test_init:
                call disk_driver_init
                ld a,(DRVINF+1)
                ld de,disk_phydio_test_run
                ld hl,H_RUNC
                call disk_set_hook
                ret

disk_phydio_test_run:
                ld a,(DEVICE)
                cp 1
                jp nz,disk_phydio_fail_device
                ld a,(DISK_SETUP)
                or a
                jp nz,disk_phydio_fail_setup

                ; Invalid drive.
                ld a,1
                ld b,1
                ld c,#f9
                ld de,8
                ld hl,#8800
                or a
                call PHYDIO
                jp nc,disk_phydio_fail_bad_drive
                cp 12
                jp nz,disk_phydio_fail_bad_drive
                ld a,b
                or a
                jp nz,disk_phydio_fail_bad_drive

                ; Invalid media descriptor.
                xor a
                ld b,1
                ld c,#f8
                ld de,8
                ld hl,#8800
                call PHYDIO
                jp nc,disk_phydio_fail_bad_media
                cp 12
                jp nz,disk_phydio_fail_bad_media
                ld a,b
                or a
                jp nz,disk_phydio_fail_bad_media

                ; A zero-sector request is invalid.
                xor a
                ld b,0
                ld c,#f9
                ld de,8
                ld hl,#8800
                call PHYDIO
                jp nc,disk_phydio_fail_zero_count
                cp 12
                jp nz,disk_phydio_fail_zero_count
                ld a,b
                or a
                jp nz,disk_phydio_fail_zero_count

                ; Reject a range extending beyond the final logical sector.
                ld a,#a5
                ld (#8800),a
                xor a
                ld b,2
                ld c,#f9
                ld de,1439
                ld hl,#8800
                call PHYDIO
                jp nc,disk_phydio_fail_range_carry
                cp 12
                jp nz,disk_phydio_fail_range_code
                ld a,b
                or a
                jp nz,disk_phydio_fail_range_count
                ld a,(#8800)
                cp #a5
                jp nz,disk_phydio_fail_range_data

                ; Page 1 contains the disk ROM and is not a valid buffer.
                xor a
                ld b,1
                ld c,#f9
                ld de,8
                ld hl,#7f00
                call PHYDIO
                jp nc,disk_phydio_fail_buffer
                cp 12
                jp nz,disk_phydio_fail_buffer
                ld a,b
                or a
                jp nz,disk_phydio_fail_buffer

                ; Valid writes against read-only media report write protect.
                xor a
                ld b,1
                ld c,#f9
                ld de,8
                ld hl,#8800
                scf
                call PHYDIO
                jp nc,disk_phydio_fail_write
                cp 3
                jp nz,disk_phydio_fail_write
                ld a,b
                or a
                jp nz,disk_phydio_fail_write

                ; Eleven sectors cross side 0/1, track 0/1, and BFFFh/C000h.
                ld a,#5a
                ld (#abff),a
                ld a,#a5
                ld (#c200),a
                xor a
                ld b,11
                ld c,#f9
                ld de,8
                ld hl,#ac00
                call PHYDIO
                jp c,disk_phydio_fail_boundary_read
                ld a,b
                cp 11
                jp nz,disk_phydio_fail_boundary_count
                ld b,11
                ld de,8
                ld hl,#ac00
                call disk_phydio_check_sequence
                jp c,disk_phydio_fail_boundary_data
                ld a,(#abff)
                cp #5a
                jp nz,disk_phydio_fail_boundary_guard
                ld a,(#c200)
                cp #a5
                jp nz,disk_phydio_fail_boundary_guard

                ; Seek directly into the middle of the disk.
                xor a
                ld b,1
                ld c,#f9
                ld de,731
                ld hl,#9000
                call PHYDIO
                jp c,disk_phydio_fail_middle_read
                ld a,b
                cp 1
                jp nz,disk_phydio_fail_middle_count
                ld b,1
                ld de,731
                ld hl,#9000
                call disk_phydio_check_sequence
                jp c,disk_phydio_fail_middle_data

                ; Read through the final logical sector.
                xor a
                ld b,2
                ld c,#f9
                ld de,1438
                ld hl,#9200
                call PHYDIO
                jp c,disk_phydio_fail_final_read
                ld a,b
                cp 2
                jp nz,disk_phydio_fail_final_count
                ld b,2
                ld de,1438
                ld hl,#9200
                call disk_phydio_check_sequence
                jp c,disk_phydio_fail_final_data

disk_phydio_motor_check:
                ; The final access armed the motor-off timer: the drive must
                ; still report the motor on, then the RainBIOS IM 1 handler
                ; must stop it after the timeout instead of the driver doing
                ; so inline. Re-enable interrupts so JIFFY and the timer run.
                ei
                ld a,(DISK_MOTOR)
                or a
                jp z,disk_phydio_fail_motor_not_armed
                ld hl,(JIFFY)
                ld de,#0080
                add hl,de
                ld (DISK_MOTOR_DEADLINE),hl
disk_phydio_motor_wait:
                ld hl,(JIFFY)
                ld de,(DISK_MOTOR_DEADLINE)
                or a
                sbc hl,de
                jr c,disk_phydio_motor_wait
                ld a,(DISK_MOTOR)
                or a
                jp nz,disk_phydio_fail_motor_timeout
                ld a,(FDC_DRIVE)
                and #80
                jp nz,disk_phydio_fail_motor_on
disk_phydio_motor_pass:
                jp disk_phydio_motor_pass

disk_phydio_fail_motor_not_armed:
                jp disk_phydio_fail_motor_not_armed
disk_phydio_fail_motor_timeout:
                jp disk_phydio_fail_motor_timeout
disk_phydio_fail_motor_on:
                jp disk_phydio_fail_motor_on

; Input HL points to B sectors whose first logical sector is DE.
disk_phydio_check_sequence:
                push bc
                call disk_phydio_check_sector
                pop bc
                ret c
                push de
                ld de,512
                add hl,de
                pop de
                inc de
                djnz disk_phydio_check_sequence
                or a
                ret

; Each generated sector carries its LBA at the front and independent markers
; at offsets 256, 510, and 511. Preserve BC, DE, and HL for the caller.
disk_phydio_check_sector:
                push bc
                push de
                push hl
                ld a,(hl)
                cp 'R'
                jr nz,disk_phydio_check_sector_fail
                inc hl
                ld a,(hl)
                cp 'B'
                jr nz,disk_phydio_check_sector_fail
                inc hl
                ld a,(hl)
                cp e
                jr nz,disk_phydio_check_sector_fail
                inc hl
                ld a,(hl)
                cp d
                jr nz,disk_phydio_check_sector_fail
                ld bc,253
                add hl,bc                       ; offset 256
                ld a,e
                xor #3c
                cp (hl)
                jr nz,disk_phydio_check_sector_fail
                ld bc,254
                add hl,bc                       ; offset 510
                ld a,e
                xor #a5
                cp (hl)
                jr nz,disk_phydio_check_sector_fail
                inc hl
                ld a,d
                xor #5a
                cp (hl)
                jr nz,disk_phydio_check_sector_fail
                or a
                jr disk_phydio_check_sector_exit
disk_phydio_check_sector_fail:
                scf
disk_phydio_check_sector_exit:
                pop hl
                pop de
                pop bc
                ret

disk_phydio_fail_device:         jp disk_phydio_fail_device
disk_phydio_fail_setup:          jp disk_phydio_fail_setup
disk_phydio_fail_bad_drive:      jp disk_phydio_fail_bad_drive
disk_phydio_fail_bad_media:      jp disk_phydio_fail_bad_media
disk_phydio_fail_zero_count:     jp disk_phydio_fail_zero_count
disk_phydio_fail_range_carry:    jp disk_phydio_fail_range_carry
disk_phydio_fail_range_code:     jp disk_phydio_fail_range_code
disk_phydio_fail_range_count:    jp disk_phydio_fail_range_count
disk_phydio_fail_range_data:     jp disk_phydio_fail_range_data
disk_phydio_fail_buffer:         jp disk_phydio_fail_buffer
disk_phydio_fail_write:          jp disk_phydio_fail_write
disk_phydio_fail_boundary_read:  jp disk_phydio_fail_boundary_read
disk_phydio_fail_boundary_count: jp disk_phydio_fail_boundary_count
disk_phydio_fail_boundary_data:  jp disk_phydio_fail_boundary_data
disk_phydio_fail_boundary_guard: jp disk_phydio_fail_boundary_guard
disk_phydio_fail_middle_read:    jp disk_phydio_fail_middle_read
disk_phydio_fail_middle_count:   jp disk_phydio_fail_middle_count
disk_phydio_fail_middle_data:    jp disk_phydio_fail_middle_data
disk_phydio_fail_final_read:     jp disk_phydio_fail_final_read
disk_phydio_fail_final_count:    jp disk_phydio_fail_final_count
disk_phydio_fail_final_data:     jp disk_phydio_fail_final_data

                defs #8000-$,#ff
