; SPDX-License-Identifier: BSD-3-Clause
;
; Test shell requiring exact completed-sector accounting when the second side
; is absent from an intentionally unusual raw DSK geometry.

PHYDIO          equ #0144
H_RUNC          equ #fecb

                org #4000

                db #41,#42
                dw disk_partial_error_init
                dw 0,0,0
                defs #4010-$,0

                jp disk_phydio
                defs #4030-$,#ff

                include "disk_nms8250_driver.asm"

disk_partial_error_init:
                call disk_driver_init
                ld a,(DRVINF+1)
                ld de,disk_partial_error_run
                ld hl,H_RUNC
                call disk_set_hook
                ret

disk_partial_error_run:
                ld hl,#8800
                ld de,#8801
                ld bc,1023
                ld (hl),#a5
                ldir

                xor a
                ld b,2
                ld c,#f9
                ld de,8
                ld hl,#8800
                call PHYDIO
                jp nc,disk_partial_error_fail_carry
                cp 8
                jp nz,disk_partial_error_fail_code
                ld a,b
                cp 1
                jp nz,disk_partial_error_fail_count
                ld hl,#8800
                ld de,disk_partial_error_marker
                ld b,4
disk_partial_error_compare:
                ld a,(de)
                cp (hl)
                jp nz,disk_partial_error_fail_data
                inc de
                inc hl
                djnz disk_partial_error_compare
                ld a,(#8a00)
                cp #a5
                jp nz,disk_partial_error_fail_data

disk_partial_error_pass:
                jp disk_partial_error_pass

disk_partial_error_marker:
                db 'R','B',8,0

disk_partial_error_fail_carry:
                jp disk_partial_error_fail_carry
disk_partial_error_fail_code:
                jp disk_partial_error_fail_code
disk_partial_error_fail_count:
                jp disk_partial_error_fail_count
disk_partial_error_fail_data:
                jp disk_partial_error_fail_data

                defs #8000-$,#ff
