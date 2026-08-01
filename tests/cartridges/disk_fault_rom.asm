; SPDX-License-Identifier: BSD-3-Clause
;
; Controller fault-injection test shell. It redirects the shared WD2793 driver
; to a RAM test double and drives every timeout and status-mapping branch that
; raw DSK images cannot reach. An openMSX probe script plays the controller:
; it maintains the double's LINES/STATUS/TRACK registers in reaction to the
; driver's command writes, keyed by the scenario in TEST_MAILBOX.

PHYDIO          equ #0144
H_RUNC          equ #fecb
DEVICE          equ #fd99

FDC_BASE        equ #e000                   ; RAM controller test double
TEST_MAILBOX    equ #e008

                org #4000

                db #41,#42                  ; AB signature
                dw disk_fault_init
                dw 0,0,0
                defs #4010-$,0

                jp disk_phydio
                defs #4030-$,#ff

                include "disk_nms8250_driver.asm"

                macro check_phydio_error scenario, errcode, failtarget
                ld a,{scenario}
                ld (TEST_MAILBOX),a
                xor a
                ld b,1
                ld c,#f9
                ld de,8
                ld hl,#8800
                call PHYDIO
                jp nc,{failtarget}
                cp {errcode}
                jp nz,{failtarget}
                ld a,b
                or a
                jp nz,{failtarget}
                mend

                macro check_read_error scenario, errcode, failtarget
                ld a,{scenario}
                ld (TEST_MAILBOX),a
                ld de,#0009
                ld hl,#9000
                call disk_read_sector
                jp nc,{failtarget}
                cp {errcode}
                jp nz,{failtarget}
                mend

disk_fault_init:
                call disk_driver_init
                ld a,(DRVINF+1)
                ld de,disk_fault_run
                ld hl,H_RUNC
                call disk_set_hook
                ret

disk_fault_run:
                ld a,(DEVICE)
                cp 1
                jp nz,disk_fault_fail_device

                ; Scenario 0: a clean seek and read through the double.
                ld a,0
                ld (TEST_MAILBOX),a
                xor a
                ld b,1
                ld c,#f9
                ld de,8
                ld hl,#8800
                call PHYDIO
                jp c,disk_fault_fail_control
                ld a,b
                cp 1
                jp nz,disk_fault_fail_control

                ; Seek faults reached through the public PHYDIO path.
                check_phydio_error 1, 6, disk_fault_fail_seek_stuck_irq
                check_phydio_error 2, 2, disk_fault_fail_seek_not_ready_timeout
                check_phydio_error 3, 2, disk_fault_fail_seek_not_ready
                check_phydio_error 4, 4, disk_fault_fail_seek_crc
                check_phydio_error 5, 6, disk_fault_fail_seek_record_missing
                check_phydio_error 6, 6, disk_fault_fail_seek_verify

                ; Read faults reached through the direct controller call so the
                ; seek phase can still assert IRQ while the data phase faults.
                check_read_error 7, 16, disk_fault_fail_read_stuck_drq
                check_read_error 8, 16, disk_fault_fail_read_stuck_irq
                check_read_error 9, 4, disk_fault_fail_read_early_irq
                check_read_error 10, 4, disk_fault_fail_read_crc
                check_read_error 11, 4, disk_fault_fail_read_lost_data
                check_read_error 12, 8, disk_fault_fail_read_not_found
                check_read_error 13, 2, disk_fault_fail_read_not_ready
                check_read_error 14, 16, disk_fault_fail_read_inconsistent

disk_fault_pass:
                jp disk_fault_pass

disk_fault_fail_device:                  jp disk_fault_fail_device
disk_fault_fail_control:                 jp disk_fault_fail_control
disk_fault_fail_seek_stuck_irq:          jp disk_fault_fail_seek_stuck_irq
disk_fault_fail_seek_not_ready_timeout:  jp disk_fault_fail_seek_not_ready_timeout
disk_fault_fail_seek_not_ready:          jp disk_fault_fail_seek_not_ready
disk_fault_fail_seek_crc:                jp disk_fault_fail_seek_crc
disk_fault_fail_seek_record_missing:     jp disk_fault_fail_seek_record_missing
disk_fault_fail_seek_verify:             jp disk_fault_fail_seek_verify
disk_fault_fail_read_stuck_drq:          jp disk_fault_fail_read_stuck_drq
disk_fault_fail_read_stuck_irq:          jp disk_fault_fail_read_stuck_irq
disk_fault_fail_read_early_irq:          jp disk_fault_fail_read_early_irq
disk_fault_fail_read_crc:                jp disk_fault_fail_read_crc
disk_fault_fail_read_lost_data:          jp disk_fault_fail_read_lost_data
disk_fault_fail_read_not_found:          jp disk_fault_fail_read_not_found
disk_fault_fail_read_not_ready:          jp disk_fault_fail_read_not_ready
disk_fault_fail_read_inconsistent:       jp disk_fault_fail_read_inconsistent

                defs #8000-$,#ff
