; SPDX-License-Identifier: BSD-3-Clause
; DSKFMT probe -- calls CHOICE + DSKFMT, verifies sector 0 fill pattern.

CALSLT          equ #001c
CHOICE          equ #4019
DSKFMT          equ #401c
DSKIO           equ #4010
H_PHYD          equ #ffa7

WORKAREA        equ #c200
READ_BUF        equ #d000

M_CARRY         equ #f3d0
M_ERROR         equ #f3d1
M_CHOICE_LO     equ #f3d2
M_CHOICE_HI     equ #f3d3
M_PASS          equ #f3d5

                org #c000

                db #eb,#1c,#90
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

disk_dskfmt_entry:
                ; Test CHOICE -- should return HL=1.
                xor a
                ld ix, CHOICE
                ld a, (H_PHYD+1)
                push af
                pop iy
                call CALSLT
                jr c, dskfmt_err
                ld a, l
                ld (M_CHOICE_LO), a
                ld a, h
                ld (M_CHOICE_HI), a
                ld de, 1
                or a
                sbc hl, de
                jr nz, dskfmt_fail

                ; Call DSKFMT.
                xor a
                ld ix, DSKFMT
                ld a, (H_PHYD+1)
                push af
                pop iy
                call CALSLT
                jr c, dskfmt_err

                ; Verify: read sector 0.
                xor a
                ld b, 1
                ld c, #f9
                ld de, 0
                ld hl, READ_BUF
                ld ix, DSKIO
                ld a, (H_PHYD+1)
                push af
                pop iy
                call CALSLT
                jr c, dskfmt_err
                ld a, (READ_BUF)
                cp #e5
                jr nz, dskfmt_fail_data

                ; Success.
                xor a
                ld (M_CARRY), a
                ld (M_ERROR), a
                jr dskfmt_done

dskfmt_err:
                ld (M_ERROR), a
                ld a, 1
                ld (M_CARRY), a
                jr dskfmt_done

dskfmt_fail_data:
                ld a, 2
                ld (M_CARRY), a
                jr dskfmt_done

dskfmt_fail:
                ld a, 3
                ld (M_CARRY), a

dskfmt_done:
                ld a, #5a
                ld (M_PASS), a
dskfmt_spin:
                jr dskfmt_spin

                defs #c1fe-$, #ff
                db #55, #aa
