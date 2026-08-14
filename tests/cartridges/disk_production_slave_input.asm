; SPDX-License-Identifier: BSD-3-Clause
;
; Synthetic disk-system master. It initializes before the production NMS8250
; disk ROM, then validates the legacy-slave registration through H.RUNC.

H_RUNC          equ #fecb
H_PHYD          equ #ffa7
DRVINF          equ #fb21
DPBLIST         equ #f355
DEVICE          equ #fd99
HIMEM           equ #fc4a
MASTER_SLOT     equ #f3c0
MASTER_HIMEM    equ #f3c1
DISK_SLOT       equ #8f

                org #4000

                db #41,#42
                dw disk_production_slave_init
                dw 0,0,0
                defs #4010-$,0

disk_production_slave_init:
                push iy
                pop bc
                ld a,b
                ld (MASTER_SLOT),a
                ld hl,(HIMEM)
                ld (MASTER_HIMEM),hl

                ld a,1
                ld (DEVICE),a
                ld a,2
                ld (DRVINF),a
                ld a,b
                ld (DRVINF+1),a

                ld de,disk_production_slave_phyd
                ld hl,H_PHYD
                call disk_production_slave_set_hook
                ld de,disk_production_slave_check
                ld hl,H_RUNC
                jp disk_production_slave_set_hook

disk_production_slave_set_hook:
                ld (hl),#f7
                inc hl
                ld (hl),a
                inc hl
                ld (hl),e
                inc hl
                ld (hl),d
                inc hl
                ld (hl),#c9
                ret

disk_production_slave_check:
                ld a,(DEVICE)
                cp 2
                jp nz,disk_production_slave_fail_device
                ld a,(DRVINF)
                cp 2
                jp nz,disk_production_slave_fail_master_drives
                ld a,(MASTER_SLOT)
                ld b,a
                ld a,(DRVINF+1)
                cp b
                jp nz,disk_production_slave_fail_master_slot
                ld a,(DRVINF+2)
                cp 1
                jp nz,disk_production_slave_fail_disk_drives
                ld a,(DRVINF+3)
                cp DISK_SLOT
                jp nz,disk_production_slave_fail_disk_slot

                ld a,(H_PHYD)
                cp #f7
                jp nz,disk_production_slave_fail_hook
                ld a,(MASTER_SLOT)
                ld b,a
                ld a,(H_PHYD+1)
                cp b
                jp nz,disk_production_slave_fail_hook_slot

                ld hl,(MASTER_HIMEM)
                ld de,21
                or a
                sbc hl,de
                ld de,(HIMEM)
                or a
                sbc hl,de
                jp nz,disk_production_slave_fail_himem

                ld hl,(DPBLIST+4)              ; logical drive C
                ld a,h
                or l
                jp z,disk_production_slave_fail_dpb
                ld a,(hl)
                cp 2
                jp nz,disk_production_slave_fail_dpb
                inc hl
                ld a,(hl)
                cp #f9
                jp nz,disk_production_slave_fail_dpb
                inc hl
                ld a,(hl)
                or a
                jp nz,disk_production_slave_fail_dpb
                inc hl
                ld a,(hl)
                cp 2                           ; 512-byte sectors
                jp nz,disk_production_slave_fail_dpb

disk_production_slave_pass:
                jp disk_production_slave_pass

disk_production_slave_phyd:
                scf
                ret

disk_production_slave_fail_device:
                jp disk_production_slave_fail_device
disk_production_slave_fail_master_drives:
                jp disk_production_slave_fail_master_drives
disk_production_slave_fail_master_slot:
                jp disk_production_slave_fail_master_slot
disk_production_slave_fail_disk_drives:
                jp disk_production_slave_fail_disk_drives
disk_production_slave_fail_disk_slot:
                jp disk_production_slave_fail_disk_slot
disk_production_slave_fail_hook:
                jp disk_production_slave_fail_hook
disk_production_slave_fail_hook_slot:
                jp disk_production_slave_fail_hook_slot
disk_production_slave_fail_himem:
                jp disk_production_slave_fail_himem
disk_production_slave_fail_dpb:
                jp disk_production_slave_fail_dpb

                defs #8000-$,#ff
