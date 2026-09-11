; SPDX-License-Identifier: BSD-3-Clause
; Multi-cluster FS.WRITE/replace probe. Write the same 2500-byte file twice,
; load the replacement, and verify its exact size, sampled content, and that
; the byte immediately beyond the file was not overwritten.

CALSLT   equ #001c
FSLOAD   equ #4025
FSLOADB  equ #403D
FSDIR    equ #4028
FSWRITE  equ #402B
H_PHYD   equ #ffa7
WORKAREA equ #c200
DEST     equ #d000
SRC      equ #d400

M_CARRY  equ #f3d0
M_ERROR  equ #f3d1
M_PASS   equ #f3d5

SZ       equ 2500

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
                ld hl,SRC
                ld (hl),#ab
                ld de,SRC+1
                ld bc,SZ-1
                ldir
                ld hl, SZ
                ld (WORKAREA), hl
                call fsw_write
                jp c,fsw_err

                ; Replacing the same name must publish the new chain and
                ; reclaim the old one without leaving a duplicate entry.
                ld hl,SRC
                ld (hl),#cd
                ld de,SRC+1
                ld bc,SZ-1
                ldir
                ld hl,SZ
                ld (WORKAREA),hl
                call fsw_write
                jp c,fsw_err

                ; The private bounded loader must reject the file before it
                ; writes even the first destination byte.
                ld a,#5a
                ld (DEST),a
                ld hl,SZ-1
                ld (WORKAREA),hl
                ld a,(H_PHYD+1)
                push af
                pop iy
                xor a
                ld hl,fname
                ld de,DEST
                ld bc,WORKAREA
                ld ix,FSLOADB
                call CALSLT
                jr nc,fsw_bad
                cp 23
                jr nz,fsw_bad
                ld a,(DEST)
                cp #5a
                jr nz,fsw_bad

                ld a,#5a
                ld (DEST+SZ),a
                ld a, (H_PHYD+1)
                push af
                pop iy
                xor a
                ld hl, fname
                ld de,DEST
                ld bc, WORKAREA
                ld ix,FSLOAD
                call CALSLT
                jr c,fsw_err
                ld a,b
                cp SZ >> 8
                jr nz,fsw_bad
                ld a,c
                cp SZ & #ff
                jr nz,fsw_bad
                ld a,(DEST)
                cp #cd
                jr nz,fsw_bad
                ld a,(DEST+511)
                cp #cd
                jr nz,fsw_bad
                ld a,(DEST+1024)
                cp #cd
                jr nz,fsw_bad
                ld a,(DEST+2048)
                cp #cd
                jr nz,fsw_bad
                ld a,(DEST+SZ-1)
                cp #cd
                jr nz,fsw_bad
                ld a,(DEST+SZ)
                cp #5a
                jr nz,fsw_bad
                xor a
                ld (M_CARRY), a
                ld (M_ERROR), a
                jr fsw_done
fsw_bad:
                ld a,#ff
fsw_err:
                ld (M_ERROR), a
                ld a, 1
                ld (M_CARRY), a
fsw_done:
                ld a, #5a
                ld (M_PASS), a
fsw_spin:
                jr fsw_spin

fsw_write:
                ld a,(H_PHYD+1)
                push af
                pop iy
                xor a
                ld hl,fname
                ld de,SRC
                ld bc,WORKAREA
                ld ix,FSWRITE
                jp CALSLT

fname:
                db "MINI    TXT"

                defs #c1fe-$, #ff
                db #55, #aa
