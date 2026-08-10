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

                org #0100

disk_bdos_system_start:
                ld c,#0c                     ; GET VERSION
                call #0005
                ld (M_VERSION),hl
                ld a,h
                or a
                jr nz,disk_bdos_system_fail
                ld a,l
                cp #22
                jr nz,disk_bdos_system_fail

                ld c,#18                     ; GET LOGIN VECTOR
                call #0005
                ld (M_LOGIN),hl
                ld a,h
                or a
                jr nz,disk_bdos_system_fail
                ld a,l
                cp 1
                jr nz,disk_bdos_system_fail

                ld c,#19                     ; GET DEFAULT DRIVE
                call #0005
                ld (M_DRIVE),a
                or a
                jr nz,disk_bdos_system_fail

                ld a,#5a
                ld (M_PASS),a
disk_bdos_system_pass:
                jr disk_bdos_system_pass

disk_bdos_system_fail:
                xor a
                ld (M_PASS),a
                jr disk_bdos_system_fail
