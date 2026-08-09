; SPDX-License-Identifier: BSD-3-Clause
; FAT12 FS.WRITE boot fixture.  Creates TEST.TXT (512 bytes) via FS.WRITE,
; verifies it appears via FS.DIR, and re-reads + compares via FS.LOAD.

CALSLT   equ #001c
FSLOAD   equ #4025
FSDIR    equ #4028
FSWRITE  equ #402B
H_PHYD   equ #ffa7
WORKAREA equ #c200
DEST     equ #d000
SRC      equ #d400
SIZE     equ 512

M_CARRY  equ #f3d0
M_ERROR  equ #f3d1
M_PASS   equ #f3d5

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
                ; Probe: entry reached.
                ld a, #ed
                ld (#f3d6), a

                ; Fill source buffer with bytes 0..255, twice.
                ld hl, SRC
                ld b, 0
fsw_f1:         ld a, b
                ld (hl), a
                inc hl
                djnz fsw_f1
                ld b, 0
fsw_f2:         ld a, b
                ld (hl), a
                inc hl
                djnz fsw_f2

                ; Pre-load file size at (WORKAREA+0/1).
                ld hl, SIZE
                ld (WORKAREA), hl

                ; Get disk ROM slot.
                ld a, (H_PHYD+1)
                push af
                pop iy

                ; FS.WRITE: create TEST.TXT (512 bytes).
                xor a
                ld hl, fname
                ld de, SRC
                ld bc, WORKAREA
                ld ix, FSWRITE
                call CALSLT
                jr c, fsw_err

                ; FS.DIR: verify one entry (32 bytes) returned.
                xor a
                ld hl, DEST
                ld bc, 32
                ld de, WORKAREA
                ld ix, FSDIR
                call CALSLT
                jr c, fsw_err
                dec bc
                ld a, b
                or c
                jr nz, fsw_fail

                ; Verify directory entry name.
                ld hl, DEST
                ld de, exp_name
                ld b, 11
fsw_dircmp:     ld a, (de)
                cp (hl)
                jr nz, fsw_fail
                inc de
                inc hl
                djnz fsw_dircmp

                ; FS.LOAD: read back and compare content.
                xor a
                ld hl, fname
                ld de, DEST
                ld bc, WORKAREA
                ld ix, FSLOAD
                call CALSLT
                jr c, fsw_err

                ; Verify size = 512 (BC = 0x0200).
                ld a, b
                cp 2
                jr nz, fsw_fail
                ld a, c
                or a
                jr nz, fsw_fail

                ; Compare 512 bytes.
                ld hl, SRC
                ld de, DEST
                ld bc, SIZE
fsw_vcmp:       ld a, (de)
                cp (hl)
                jr nz, fsw_fail
                inc de
                inc hl
                dec bc
                ld a, b
                or c
                jr nz, fsw_vcmp

                ; Success.
                xor a
                ld (M_CARRY), a
                ld (M_ERROR), a
                jr fsw_done

fsw_err:        ld (M_ERROR), a
                ld a, 1
                ld (M_CARRY), a
                jr fsw_done
fsw_fail:       ld a, 2
                ld (M_CARRY), a
fsw_done:       ld a, #5a
                ld (M_PASS), a
fsw_spin:       jr fsw_spin

fname:          db "TEST    TXT"
exp_name:       db "TEST    TXT"

                defs #c1fe-$, #ff
                db #55, #aa
