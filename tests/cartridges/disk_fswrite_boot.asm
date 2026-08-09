; SPDX-License-Identifier: BSD-3-Clause
; Minimal FS.WRITE probe — 32-byte file, verify via FS.DIR + FS.LOAD.

CALSLT   equ #001c
FSLOAD   equ #4025
FSDIR    equ #4028
FSWRITE  equ #402B
H_PHYD   equ #ffa7
WORKAREA equ #c200
DEST     equ #d000
SRC      equ #d400

M_CARRY  equ #f3d0
M_ERROR  equ #f3d1
M_PASS   equ #f3d5

SZ       equ 32

                org #c000
                db #eb, #1c, #90
                db "RBFAT12 "
                dw 512
                db 2
                dw 1
                db 2
                dw 112
                dw 1440
                db #f9
                dw 3
                dw 9
                dw 2
                dw 0

disk_fswrite_entry:
                ld hl, SZ
                ld (WORKAREA), hl
                ld a, #ab
                ld (SRC), a
                ld a, (H_PHYD+1)
                push af
                pop iy
                xor a
                ld hl, fname
                ld de, SRC
                ld bc, WORKAREA
                ld ix, FSWRITE
                call CALSLT
                jr c, fsw_err
                xor a
                ld (M_CARRY), a
                ld (M_ERROR), a
                jr fsw_done
fsw_err:
                ld (M_ERROR), a
                ld a, 1
                ld (M_CARRY), a
fsw_done:
                ld a, #5a
                ld (M_PASS), a
fsw_spin:
                jr fsw_spin

fname:
                db "MINI    TXT"

                defs #c1fe-$, #ff
                db #55, #aa
