; SPDX-License-Identifier: BSD-3-Clause
;
; Primary-slot probe which runs through H.STKE after the production disk ROM
; initializes, then requires its PHYDIO hook and drive table registration.

H_STKE          equ #feda
H_PHYD          equ #ffa7
DRVINF          equ #fb21
DISK_SLOT       equ #8f

                org #4000

                db #41,#42
                dw disk_production_init
                dw 0,0,0
                defs #4010-$,0

disk_production_init:
                ld a,#f7                       ; RST 30h / CALLF
                ld (H_STKE),a
                push iy
                pop de
                ld a,d
                ld (H_STKE+1),a
                ld hl,disk_production_check
                ld (H_STKE+2),hl
                ld a,#c9
                ld (H_STKE+4),a
                ret

disk_production_check:
                ld a,(H_PHYD)
                cp #f7
                jp nz,disk_production_fail_hook
                ld a,(H_PHYD+1)
                cp DISK_SLOT
                jp nz,disk_production_fail_slot
                ld a,(DRVINF)
                cp 1
                jp nz,disk_production_fail_drives
                ld a,(DRVINF+1)
                cp DISK_SLOT
                jp nz,disk_production_fail_drvinf_slot

disk_production_init_pass:
                jp disk_production_init_pass

disk_production_fail_hook:
                jp disk_production_fail_hook
disk_production_fail_slot:
                jp disk_production_fail_slot
disk_production_fail_drives:
                jp disk_production_fail_drives
disk_production_fail_drvinf_slot:
                jp disk_production_fail_drvinf_slot

                defs #8000-$,#ff
