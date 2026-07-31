; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only NMS 8250 disk extension. It installs PHYDIO and bootstrap hooks,
; reads logical sector 1 through the WD2793, and validates the deterministic
; read-only DSK fixture through RainBIOS's public PHYDIO entry.

PHYDIO          equ #0144
H_RUNC          equ #fecb
H_PHYD          equ #ffa7
DEVICE          equ #fd99
DISK_SETUP      equ #fb29
DISK_SLOT       equ #8f
SECTOR_BUFFER   equ #9000
PROBE_SECTOR    equ 1

FDC_STATUS      equ #7ff8
FDC_COMMAND     equ #7ff8
FDC_TRACK       equ #7ff9
FDC_SECTOR      equ #7ffa
FDC_DATA        equ #7ffb
FDC_SIDE        equ #7ffc
FDC_DRIVE       equ #7ffd
FDC_LINES       equ #7fff

                org #4000

                db #41,#42                     ; AB signature
                dw disk_phydio_init
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs #4010-$,0

disk_phydio_init:
                ld de,disk_phydio_transfer
                ld hl,H_PHYD
                call disk_phydio_set_hook
                ld de,disk_phydio_read
                ld hl,H_RUNC
                call disk_phydio_set_hook
                ret

disk_phydio_set_hook:
                ld (hl),#f7                    ; RST 30h / CALLF
                inc hl
                ld (hl),DISK_SLOT
                inc hl
                ld (hl),e
                inc hl
                ld (hl),d
                inc hl
                ld (hl),#c9
                ret

; Exact read-only implementation needed by this fixture. The public PHYDIO
; contract reports the requested transfer count in B and carry on failure.
disk_phydio_transfer:
                jp c,disk_phydio_transfer_error
                or a
                jr nz,disk_phydio_transfer_error
                ld a,b
                cp 1
                jr nz,disk_phydio_transfer_error
                ld a,c
                cp #f9
                jr nz,disk_phydio_transfer_error
                ld a,d
                or a
                jr nz,disk_phydio_transfer_error
                ld a,e
                cp PROBE_SECTOR
                jr nz,disk_phydio_transfer_error

                ld a,#80                       ; drive A, motor on
                ld (FDC_DRIVE),a
                xor a
                ld (FDC_TRACK),a
                ld (FDC_SIDE),a
                ld a,2                         ; logical sector 1
                ld (FDC_SECTOR),a
                ld a,#80                       ; read one sector
                ld (FDC_COMMAND),a

                ld de,512
disk_phydio_wait_data:
                ld a,(FDC_LINES)
                bit 7,a                        ; DRQ is active low
                jr nz,disk_phydio_wait_data
                ld a,(FDC_DATA)
                ld (hl),a
                inc hl
                dec de
                ld a,d
                or e
                jr nz,disk_phydio_wait_data

disk_phydio_wait_complete:
                ld a,(FDC_LINES)
                bit 6,a                        ; IRQ is active low
                jr nz,disk_phydio_wait_complete
                ld a,(FDC_STATUS)
                and #9c                        ; not ready/RNF/CRC/lost data
                jr nz,disk_phydio_transfer_error
                ld b,1
                xor a
                ret

disk_phydio_transfer_error:
                ld a,16
                scf
                ret

disk_phydio_read:
                ld a,(DEVICE)
                cp 1
                jp nz,disk_phydio_fail_device
                ld a,(DISK_SETUP)
                or a
                jp nz,disk_phydio_fail_setup

                ld hl,SECTOR_BUFFER
                ld de,SECTOR_BUFFER+1
                ld bc,511
                ld (hl),#a5
                ldir

                xor a                           ; drive A, read operation
                ld b,1                         ; one sector
                ld c,#f9                       ; 720 KiB media ID
                ld de,PROBE_SECTOR
                ld hl,SECTOR_BUFFER
                call PHYDIO
                jp c,disk_phydio_fail_read
                ld a,b
                cp 1
                jp nz,disk_phydio_fail_count

                ld hl,SECTOR_BUFFER
                ld de,disk_phydio_marker
                ld b,disk_phydio_marker_end-disk_phydio_marker
disk_phydio_compare_marker:
                ld a,(de)
                cp (hl)
                jp nz,disk_phydio_fail_marker
                inc de
                inc hl
                djnz disk_phydio_compare_marker

                ld a,(SECTOR_BUFFER+256)
                cp #3c
                jp nz,disk_phydio_fail_middle
                ld a,(SECTOR_BUFFER+510)
                cp #a5
                jp nz,disk_phydio_fail_suffix
                ld a,(SECTOR_BUFFER+511)
                cp #5a
                jp nz,disk_phydio_fail_suffix

disk_phydio_read_pass:
                jp disk_phydio_read_pass

disk_phydio_fail_device:
                jp disk_phydio_fail_device
disk_phydio_fail_setup:
                jp disk_phydio_fail_setup
disk_phydio_fail_read:
                jp disk_phydio_fail_read
disk_phydio_fail_count:
                jp disk_phydio_fail_count
disk_phydio_fail_marker:
                jp disk_phydio_fail_marker
disk_phydio_fail_middle:
                jp disk_phydio_fail_middle
disk_phydio_fail_suffix:
                jp disk_phydio_fail_suffix

disk_phydio_marker:
                db "RAINBIOS-PHYDIO"
disk_phydio_marker_end:

                defs #8000-$,#ff
