; SPDX-License-Identifier: BSD-3-Clause
;
; Redistributable MSXDOS.SYS fixture for the clean-room BDOS boot gate.  It is
; intentionally a tiny DOS-side executable, not a copy or derivative of the
; Microsoft system file.  Reaching the pass loop proves page-0 loading, CALL 5,
; the resident F37Dh dispatcher, and the version/login/default-drive calls.

M_VERSION       equ #f3d0
M_LOGIN         equ #f3d2
M_DRIVE         equ #f3d4
M_PASS          equ #f3d5
M_INPUT         equ #f3d6
DISK_INIT       equ #4030
DISABLE_KERNEL  equ #f36b
RUNTIME_ENTRY   equ #ca06

                org #0100

disk_bdos_system_start:
                ld hl,#f1c9
                call DISK_INIT
                ld de,#d0d5
                or a
                sbc hl,de
                jp nz,disk_bdos_system_fail

                call DISABLE_KERNEL
                ld hl,RUNTIME_ENTRY
                ld (#0006),hl
                ld a,(RUNTIME_ENTRY)
                cp #c3
                jp nz,disk_bdos_system_fail
                ld hl,(RUNTIME_ENTRY+1)
                ld de,#f37d
                or a
                sbc hl,de
                jp nz,disk_bdos_system_fail

                ld c,#0c                     ; GET VERSION
                call #0005
                ld (M_VERSION),hl
                ld a,h
                or a
                jp nz,disk_bdos_system_fail
                ld a,l
                cp #22
                jp nz,disk_bdos_system_fail

                ld c,#18                     ; GET LOGIN VECTOR
                call #0005
                ld (M_LOGIN),hl
                ld a,h
                or a
                jp nz,disk_bdos_system_fail
                ld a,l
                cp 1
                jp nz,disk_bdos_system_fail

                ld c,#19                     ; GET DEFAULT DRIVE
                call #0005
                ld (M_DRIVE),a
                or a
                jp nz,disk_bdos_system_fail

                ld c,#0b                     ; CONSOLE STATUS, NO KEY
                call #0005
                or a
                jp nz,disk_bdos_system_fail
                ld e,#ff
                ld c,#06                     ; DIRECT INPUT, NO KEY
                call #0005
                or a
                jp nz,disk_bdos_system_fail

                ld hl,M_INPUT
                ld (hl),4
                inc hl
                ld (hl),0
                ld de,M_INPUT
                ld c,#0a                     ; BUFFERED CONSOLE INPUT
                call #0005
                ld a,(M_INPUT+1)
                cp 2
                jp nz,disk_bdos_system_fail
                ld a,(M_INPUT+2)
                cp 'O'
                jp nz,disk_bdos_system_fail
                ld a,(M_INPUT+3)
                cp 'K'
                jp nz,disk_bdos_system_fail
                ld a,(M_INPUT+4)
                cp #0d
                jp nz,disk_bdos_system_fail

                ld a,#5a
                ld (M_PASS),a
disk_bdos_system_pass:
                jr disk_bdos_system_pass

disk_bdos_system_fail:
                xor a
                ld (M_PASS),a
                jr disk_bdos_system_fail
