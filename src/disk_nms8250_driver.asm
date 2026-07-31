; SPDX-License-Identifier: BSD-3-Clause
;
; Shared read-only PHYDIO implementation for the Philips NMS 8250 WD2793
; memory window. The including ROM must place this code in page 1.

H_PHYD          equ #ffa7
DRVINF          equ #fb21

FDC_STATUS      equ #7ff8
FDC_COMMAND     equ #7ff8
FDC_TRACK       equ #7ff9
FDC_SECTOR      equ #7ffa
FDC_DATA        equ #7ffb
FDC_SIDE        equ #7ffc
FDC_DRIVE       equ #7ffd
FDC_LINES       equ #7fff

DISK_MEDIA      equ #f9
DISK_SECTORS    equ 1440
DISK_TRACK_SIZE equ 18
DISK_SIDE_SIZE  equ 9
DISK_RAM_LIMIT  equ #f000

disk_driver_init:
                push iy
                pop bc
                ld a,1
                ld (DRVINF),a
                ld a,b                         ; full extension slot ID
                ld (DRVINF+1),a
                ld de,disk_phydio
                ld hl,H_PHYD
                jp disk_set_hook

; Input A is the full slot ID, DE the target, and HL the hook address.
disk_set_hook:
                ld (hl),#f7                    ; RST 30h / CALLF
                inc hl
                ld (hl),a
                inc hl
                ld (hl),e
                inc hl
                ld (hl),d
                inc hl
                ld (hl),#c9
                ret

; Read-only PHYDIO for drive A and 720 KiB F9 media. B returns the number of
; fully completed sectors. Valid writes report write-protected without touching
; the controller; malformed requests report bad parameter.
disk_phydio:
                push af                         ; preserve operation carry
                or a
                jr nz,disk_phydio_bad_parameter
                ld a,c
                cp DISK_MEDIA
                jr nz,disk_phydio_bad_parameter
                ld a,b
                or a
                jr z,disk_phydio_bad_parameter
                call disk_validate_sector_range
                jr c,disk_phydio_bad_parameter
                call disk_validate_buffer
                jr c,disk_phydio_bad_parameter
                pop af
                jr c,disk_phydio_write_protected

                push de
                pop iy                          ; current logical sector
                call disk_lba_to_chs
                ld c,0                         ; completed sectors
                ld a,#80                       ; drive A, motor on
                ld (FDC_DRIVE),a
                call disk_motor_spinup
                call disk_seek_track
                jr c,disk_phydio_runtime_error

disk_phydio_read_loop:
                call disk_read_sector
                jr c,disk_phydio_runtime_error
                inc c
                dec b
                jr z,disk_phydio_success
                inc iy
                ld a,e
                cp DISK_SIDE_SIZE
                jr z,disk_phydio_advance_side
                inc e
                jr disk_phydio_read_loop

disk_phydio_advance_side:
                ld e,1
                bit 7,d
                jr z,disk_phydio_select_side_one
                res 7,d
                inc d
                call disk_seek_track
                jr c,disk_phydio_runtime_error
                jr disk_phydio_read_loop
disk_phydio_select_side_one:
                set 7,d
                jr disk_phydio_read_loop

disk_phydio_success:
                call disk_motor_off
                ld b,c
                xor a
                ret

disk_phydio_runtime_error:
                push af
                ld a,#d0                       ; force interrupt
                ld (FDC_COMMAND),a
                call disk_motor_off
                pop af
                ld b,c
                scf
                ret

disk_phydio_bad_parameter:
                pop af
                ld a,12
                ld b,0
                scf
                ret

disk_phydio_write_protected:
                xor a
                ld b,0
                scf
                ret

disk_unsupported:
                ld a,12
                scf
                ret

disk_motor_off:
                xor a
                ld (FDC_DRIVE),a
                ret

; Allow a cold drive approximately one second to reach operating speed at the
; standard Z80 clock. The controller call runs with interrupts inhibited, so a
; bounded instruction delay is used instead of JIFFY.
disk_motor_spinup:
                push bc
                push de
                ld d,2
disk_motor_spinup_epoch:
                ld bc,#ffff
disk_motor_spinup_loop:
                dec bc
                ld a,b
                or c
                jr nz,disk_motor_spinup_loop
                dec d
                jr nz,disk_motor_spinup_epoch
                pop de
                pop bc
                ret

; Accept only requests wholly within logical sectors 0..1439.
disk_validate_sector_range:
                push de
                push hl
                ld h,d
                ld l,e
                ld d,0
                ld e,b
                add hl,de
                jr c,disk_validate_sector_range_bad
                ld a,h
                cp #05
                jr c,disk_validate_sector_range_ok
                jr nz,disk_validate_sector_range_bad
                ld a,l
                cp #a1
                jr c,disk_validate_sector_range_ok
disk_validate_sector_range_bad:
                scf
                jr disk_validate_sector_range_exit
disk_validate_sector_range_ok:
                or a
disk_validate_sector_range_exit:
                pop hl
                pop de
                ret

; Page 1 contains this ROM. Keep the complete transfer in page 2 or low page 3
; and below the system stack/work area.
disk_validate_buffer:
                ld a,h
                cp #80
                jr c,disk_validate_buffer_bad_direct
                push de
                push hl
                ld a,b
                ld de,512
disk_validate_buffer_loop:
                add hl,de
                jr c,disk_validate_buffer_bad
                dec a
                jr nz,disk_validate_buffer_loop
                ld a,h
                cp DISK_RAM_LIMIT/256
                jr c,disk_validate_buffer_ok
                jr nz,disk_validate_buffer_bad
                ld a,l
                or a
                jr z,disk_validate_buffer_ok
disk_validate_buffer_bad:
                scf
                jr disk_validate_buffer_exit
disk_validate_buffer_ok:
                or a
disk_validate_buffer_exit:
                pop hl
                pop de
                ret
disk_validate_buffer_bad_direct:
                scf
                ret

; Convert IY LBA to packed CHS: D bits 6:0 are track, D bit 7 is side, and E
; is the one-based physical sector. Preserve BC and HL.
disk_lba_to_chs:
                push bc
                push hl
                push iy
                pop hl
                ld b,0
disk_lba_to_chs_loop:
                ld a,h
                or a
                jr nz,disk_lba_to_chs_subtract
                ld a,l
                cp DISK_TRACK_SIZE
                jr c,disk_lba_to_chs_divided
disk_lba_to_chs_subtract:
                ld a,l
                sub DISK_TRACK_SIZE
                ld l,a
                jr nc,disk_lba_to_chs_no_borrow
                dec h
disk_lba_to_chs_no_borrow:
                inc b
                jr disk_lba_to_chs_loop
disk_lba_to_chs_divided:
                ld d,b
                ld e,l
                ld a,e
                cp DISK_SIDE_SIZE
                jr c,disk_lba_to_chs_side_zero
                sub DISK_SIDE_SIZE
                ld e,a
                set 7,d
disk_lba_to_chs_side_zero:
                inc e
                pop hl
                pop bc
                ret

; Seek to track D&7Fh. Preserve BC, DE, and HL; return standard error in A.
disk_seek_track:
                push bc
                push de
                push hl
                ld a,d
                and #7f
                ld e,a
                ld (FDC_DATA),a
                ld a,#1c                       ; seek, load head, and verify
                ld (FDC_COMMAND),a
                call disk_wait_irq
                jr c,disk_seek_track_timeout
                ld a,(FDC_STATUS)
                bit 7,a
                jr nz,disk_seek_track_not_ready
                bit 4,a
                jr nz,disk_seek_track_error
                bit 3,a
                jr nz,disk_seek_track_data_error
                ld a,(FDC_TRACK)
                cp e
                jr nz,disk_seek_track_error
                xor a
                jr disk_seek_track_exit
disk_seek_track_not_ready:
                ld a,2
                scf
                jr disk_seek_track_exit
disk_seek_track_data_error:
                ld a,4
                scf
                jr disk_seek_track_exit
disk_seek_track_timeout:
                ld a,(FDC_STATUS)
                bit 7,a
                jr nz,disk_seek_track_not_ready
disk_seek_track_error:
                ld a,6
                scf
disk_seek_track_exit:
                pop hl
                pop de
                pop bc
                ret

; Read one sector at packed CHS D/E into HL and advance HL by 512 bytes.
; Preserve the outer remaining/completed counts in BC and packed CHS in DE.
disk_read_sector:
                push bc
                push de
                xor a
                bit 7,d
                jr z,disk_read_sector_side_ready
                inc a
disk_read_sector_side_ready:
                ld (FDC_SIDE),a
                ld a,e
                ld (FDC_SECTOR),a
                ld a,#84                       ; read after head-settling delay
                ld (FDC_COMMAND),a
                ld de,512
                ld bc,#ffff

disk_read_sector_wait_data:
                ld a,(FDC_LINES)
                bit 7,a                        ; DRQ is active low
                jr z,disk_read_sector_data
                bit 6,a                        ; early completion is an error
                jr z,disk_read_sector_early_irq
                dec bc
                ld a,b
                or c
                jr nz,disk_read_sector_wait_data
                jr disk_read_sector_timeout

disk_read_sector_data:
                ld a,(FDC_DATA)
                ld (hl),a
                inc hl
                dec de
                ld a,d
                or e
                jr nz,disk_read_sector_wait_data

disk_read_sector_wait_complete:
                ld a,(FDC_LINES)
                bit 6,a
                jr z,disk_read_sector_status
                dec bc
                ld a,b
                or c
                jr nz,disk_read_sector_wait_complete
                jr disk_read_sector_timeout

disk_read_sector_early_irq:
                ld a,(FDC_STATUS)
                call disk_map_read_status
                jr c,disk_read_sector_exit
                ld a,4                         ; incomplete sector
                scf
                jr disk_read_sector_exit

disk_read_sector_status:
                ld a,(FDC_STATUS)
                call disk_map_read_status
                jr disk_read_sector_exit

disk_read_sector_timeout:
                ld a,#d0
                ld (FDC_COMMAND),a
                ld a,16
                scf

disk_read_sector_exit:
                pop de
                pop bc
                ret

; Map type-II read status to the public PHYDIO error numbers.
disk_map_read_status:
                bit 7,a
                jr nz,disk_map_read_not_ready
                bit 3,a
                jr nz,disk_map_read_data_error
                bit 2,a
                jr nz,disk_map_read_data_error
                bit 4,a
                jr nz,disk_map_read_not_found
                and #03                       ; BUSY/DRQ must both be clear
                jr nz,disk_map_read_other
                xor a
                ret
disk_map_read_not_ready:
                ld a,2
                scf
                ret
disk_map_read_data_error:
                ld a,4
                scf
                ret
disk_map_read_not_found:
                ld a,8
                scf
                ret
disk_map_read_other:
                ld a,16
                scf
                ret

disk_wait_irq:
                ld bc,#ffff
disk_wait_irq_loop:
                ld a,(FDC_LINES)
                bit 6,a
                jr z,disk_wait_irq_done
                dec bc
                ld a,b
                or c
                jr nz,disk_wait_irq_loop
                scf
                ret
disk_wait_irq_done:
                or a
                ret
