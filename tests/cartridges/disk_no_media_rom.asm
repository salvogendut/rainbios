; SPDX-License-Identifier: BSD-3-Clause
;
; Test shell requiring a bounded not-ready result when drive A has no media.

PHYDIO          equ #0144
H_RUNC          equ #fecb

                org #4000

                db #41,#42
                dw disk_no_media_init
                dw 0,0,0
                defs #4010-$,0

                jp disk_phydio
                defs #4030-$,#ff

                include "disk_nms8250_driver.asm"

disk_no_media_init:
                call disk_driver_init
                ld a,(DRVINF+1)
                ld de,disk_no_media_run
                ld hl,H_RUNC
                call disk_set_hook
                ret

disk_no_media_run:
                xor a
                ld b,1
                ld c,#f9
                ld de,8
                ld hl,#8800
                call PHYDIO
                jp nc,disk_no_media_fail_carry
                cp 2
                jp nz,disk_no_media_fail_code
                ld a,b
                or a
                jp nz,disk_no_media_fail_count

disk_no_media_pass:
                jp disk_no_media_pass

disk_no_media_fail_carry:
                jp disk_no_media_fail_carry
disk_no_media_fail_code:
                jp disk_no_media_fail_code
disk_no_media_fail_count:
                jp disk_no_media_fail_count

                defs #8000-$,#ff
