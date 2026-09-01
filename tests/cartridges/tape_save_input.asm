; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only slot-2 cartridge. It launches BBC BASIC, enters a program, saves
; it to cassette, then executes a marker command. SAVE errors clear the key
; buffer, so the dedicated success loop is reachable only after SAVE returns.

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
                dw tape_save_input_init
                dw 0,0,0
                defs 6,0

tape_save_input_init:
                xor a
                ld (TEST_FRAME),a
                ld (TEST_FRAME+1),a
                ld (TEST_INDEX),a
                ld (TEST_INDEX+1),a
                ld (TEST_DONE),a
                ld (PROGRAM_MARKER),a
                ld hl,tape_save_hook_template
                ld de,HOOK_TIMI
                ld bc,5
                ldir
                ret

tape_save_hook_template:
                db #f7                         ; RST 30h / CALLF
                db 2                           ; primary slot 2
                dw tape_save_tick
                db #c9                         ; RET after inline operands

tape_save_tick:
                ld a,(PROGRAM_MARKER)
                cp 90
                jp z,tape_save_success
                ld hl,(TEST_FRAME)
                inc hl
                ld (TEST_FRAME),hl
                ld de,1800
                or a
                sbc hl,de
                jp nc,tape_save_failure
                add hl,de
                ld a,h
                or a
                jr nz,tape_save_commands
                ld a,l
                cp 1
                jr z,tape_save_space
                cp 20
                jr z,tape_save_menu
                ret
tape_save_commands:
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
                ld hl,tape_save_text
                add hl,de
                ld a,(hl)
                or a
                jr z,tape_save_commands_done
                call tape_save_put
                ret nc
                ld de,(TEST_INDEX)
                inc de
                ld (TEST_INDEX),de
                ret
tape_save_space:
                ld a,#20
                call tape_save_put
                ret
tape_save_menu:
                ld a,'1'
                call tape_save_put
                ret
tape_save_commands_done:
                ld a,#ff
                ld (TEST_DONE),a
                ret

tape_save_put:
                push af
                ld hl,(PUTPNT)
                ld d,h
                ld e,l
                inc hl
                ld a,h
                cp KEYBUF_END/256
                jr nz,tape_save_compare
                ld a,l
                cp KEYBUF_END&255
                jr nz,tape_save_compare
                ld hl,KEYBUF
tape_save_compare:
                ld bc,(GETPNT)
                ld a,l
                cp c
                jr nz,tape_save_store
                ld a,h
                cp b
                jr z,tape_save_full
tape_save_store:
                pop af
                ld (de),a
                ld (PUTPNT),hl
                scf
                ret
tape_save_full:
                pop af
                or a
                ret

tape_save_text:
                db '10 PRINT "SAVE OK"',#0d
                db 'SAVE "SAVET"',#0d
                db '?&F3AC=90',#0d,0

                defs #4300-$,#ff
tape_save_failure:
                jp tape_save_failure

                defs #4400-$,#ff
tape_save_success:
                jp tape_save_success

                defs #8000-$,#ff
