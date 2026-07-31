; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only cartridge to validate the M1 read-only disk baseline.
;
; It executes disk-related BIOS stubs and jumps to a unique label for each
; unexpected condition. On success it lands in DISK_BASELINE_PASS.

                org #4000

                db #41,#42                     ; AB signature
                dw disk_baseline_entry
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs #4010-$,0

disk_baseline_entry:
                ; PHYDIO should return with carry set.
                ld b,#03
                ld c,#01
                ld de,#1234
                ld hl,#9000
                call #0144
                jp nc,disk_fail_phyio

                ; FORMAT should return with carry set.
                ld b,#02
                ld c,#00
                ld de,#1111
                ld hl,#2222
                call #0147
                jp nc,disk_fail_format

                ; ISFLIO should return A=00 and carry clear.
                ld a,#ff
                call #014A
                jp nz,disk_fail_isflio_a
                jp c,disk_fail_isflio_c

                ; OUTDLP should return with carry set.
                ld a,#2b
                call #014D
                jp nc,disk_fail_outdlp

                ; GETVCP should return with carry set.
                ld a,#02
                call #0150
                jp nc,disk_fail_getvcp

                ; GETVC2 should return with carry set.
                ld a,#03
                ld l,#08
                call #0153
                jp nc,disk_fail_getvc2

                jp disk_baseline_pass

disk_fail_phyio:
                jp disk_fail_phyio

disk_fail_format:
                jp disk_fail_format

disk_fail_isflio_a:
                jp disk_fail_isflio_a

disk_fail_isflio_c:
                jp disk_fail_isflio_c

disk_fail_outdlp:
                jp disk_fail_outdlp

disk_fail_getvcp:
                jp disk_fail_getvcp

disk_fail_getvc2:
                jp disk_fail_getvc2

disk_baseline_pass:
                jp disk_baseline_pass

