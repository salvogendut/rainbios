; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only slot-2 cartridge. Its H.TIMI hook selects BBC BASIC, types LOAD
; and RUN, then requires the loaded program to write the expected RAM marker.
; A successful hook deliberately retains slot 2 in page 1 at PC=4400h so
; 1983 can distinguish the complete path without inspecting private state.

PUTPNT          equ #f3f8
GETPNT          equ #f3fa
KEYBUF          equ #fbf0
KEYBUF_END      equ #fc18
HOOK_TIMI       equ #fd9f
TEST_FRAME      equ #f3a0
TEST_INDEX      equ #f3a2
TEST_DONE       equ #f3a4
PROGRAM_MARKER  equ #f3ac

                org #4000

                db #41,#42
                dw tape_load_input_init
                dw 0,0,0
                defs 6,0

tape_load_input_init:
                xor a
                ld (TEST_FRAME),a
                ld (TEST_FRAME+1),a
                ld (TEST_INDEX),a
                ld (TEST_INDEX+1),a
                ld (TEST_DONE),a
                ld (PROGRAM_MARKER),a
                ld hl,tape_load_hook_template
                ld de,HOOK_TIMI
                ld bc,5
                ldir
                ret

tape_load_hook_template:
                db #f7                         ; RST 30h / CALLF
                db 2                           ; primary slot 2
                dw tape_load_tick
                db #c9                         ; RET after inline operands

tape_load_tick:
                ld a,(PROGRAM_MARKER)
                cp 90
                jp z,tape_load_success
                ld hl,(TEST_FRAME)
                inc hl
                ld (TEST_FRAME),hl
                ld de,1800
                or a
                sbc hl,de
                jp nc,tape_load_failure
                add hl,de
                ld a,h
                or a
                jr nz,tape_load_program
                ld a,l
                cp 1
                jr z,tape_load_space
                cp 20
                jr z,tape_load_menu
                ret
tape_load_program:
                ld de,300
                or a
                sbc hl,de
                ret c
                bit 0,l
                ret nz
                ld a,(TEST_DONE)
                or a
                ret nz
                ld de,(TEST_INDEX)
                ld hl,tape_load_commands
                add hl,de
                ld a,(hl)
                or a
                jr z,tape_load_commands_done
                call tape_load_put
                ret nc
                ld de,(TEST_INDEX)
                inc de
                ld (TEST_INDEX),de
                ret
tape_load_space:
                ld a,#20
                call tape_load_put
                ret
tape_load_menu:
                ld a,'1'
                call tape_load_put
                ret
tape_load_commands_done:
                ld a,#ff
                ld (TEST_DONE),a
                ret

; Add A unless the next write pointer would collide with the read pointer.
tape_load_put:
                push af
                ld hl,(PUTPNT)
                ld d,h
                ld e,l
                inc hl
                ld a,h
                cp KEYBUF_END/256
                jr nz,tape_load_compare
                ld a,l
                cp KEYBUF_END&255
                jr nz,tape_load_compare
                ld hl,KEYBUF
tape_load_compare:
                ld bc,(GETPNT)
                ld a,l
                cp c
                jr nz,tape_load_store
                ld a,h
                cp b
                jr z,tape_load_full
tape_load_store:
                pop af
                ld (de),a
                ld (PUTPNT),hl
                scf
                ret
tape_load_full:
                pop af
                or a
                ret

tape_load_commands:
                db 'LOAD "TAPET"',#0d
                db 'RUN',#0d,0

                defs #4300-$,#ff
tape_load_failure:
                jp tape_load_failure

                defs #4400-$,#ff
tape_load_success:
                jp tape_load_success

                defs #8000-$,#ff
