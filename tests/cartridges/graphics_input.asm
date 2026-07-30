; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only slot-2 cartridge. Its H.TIMI hook selects the RainBIOS BBC BASIC
; menu entry, waits for the interpreter, then types a real graphics program
; through the published circular key buffer. The program checks POINT and
; remains in Graphics II so 1983 can validate the rendered result.

PUTPNT          equ #f3f8
GETPNT          equ #f3fa
KEYBUF          equ #fbf0
KEYBUF_END      equ #fc18
HOOK_TIMI       equ #fd9f
TEST_FRAME      equ #f398
TEST_INDEX      equ #f39a
TEST_DONE       equ #f39c

                org #4000

                db #41,#42
                dw graphics_input_init
                dw 0,0,0
                defs 6,0

graphics_input_init:
                xor a
                ld (TEST_FRAME),a
                ld (TEST_FRAME+1),a
                ld (TEST_INDEX),a
                ld (TEST_INDEX+1),a
                ld (TEST_DONE),a
                ld hl,graphics_input_hook_template
                ld de,HOOK_TIMI
                ld bc,5
                ldir
                ret

graphics_input_hook_template:
                db #f7                         ; RST 30h / CALLF
                db 2                           ; primary slot 2
                dw graphics_input_tick
                db #c9                         ; RET after inline operands

graphics_input_tick:
                ld a,(TEST_DONE)
                or a
                ret nz
                ld hl,(TEST_FRAME)
                inc hl
                ld (TEST_FRAME),hl
                ld a,h
                or a
                jr nz,graphics_input_wait_program
                ld a,l
                cp 2
                jr z,graphics_input_space
                cp 20
                jr z,graphics_input_menu
graphics_input_wait_program:
                ld de,300
                or a
                sbc hl,de
                ret c
                bit 0,l
                ret nz
graphics_input_program:
                ld de,(TEST_INDEX)
                ld hl,graphics_program
                add hl,de
                ld a,(hl)
                or a
                jr z,graphics_input_done
                call graphics_input_put
                ret nc
                ld de,(TEST_INDEX)
                inc de
                ld (TEST_INDEX),de
                ret
graphics_input_space:
                ld a,#20
                call graphics_input_put
                ret
graphics_input_menu:
                ld a,'1'
                call graphics_input_put
                ret
graphics_input_done:
                ld a,#ff
                ld (TEST_DONE),a
                ld a,#c9
                ld (HOOK_TIMI),a              ; remove the test hook
                ret

; Add A unless the next write pointer would collide with the read pointer.
graphics_input_put:
                push af
                ld hl,(PUTPNT)
                ld d,h
                ld e,l
                inc hl
                ld a,h
                cp KEYBUF_END/256
                jr nz,graphics_input_compare
                ld a,l
                cp KEYBUF_END&255
                jr nz,graphics_input_compare
                ld hl,KEYBUF
graphics_input_compare:
                ld bc,(GETPNT)
                ld a,l
                cp c
                jr nz,graphics_input_store
                ld a,h
                cp b
                jr z,graphics_input_full
graphics_input_store:
                pop af
                ld (de),a
                ld (PUTPNT),hl
                scf
                ret
graphics_input_full:
                pop af
                or a
                ret

graphics_program:
                db '10 MODE 2',#0d
                db '20 GCOL 0,1',#0d
                db '30 MOVE 480,384:DRAW 800,384:DRAW 800,640'
                db ':DRAW 480,640:DRAW 480,384',#0d
                db '40 GCOL 0,2',#0d
                db '50 MOVE 480,384:DRAW 800,640',#0d
                db '60 GCOL 0,4',#0d
                db '70 MOVE 480,640:DRAW 800,384',#0d
                db '80 GCOL 0,7',#0d
                db '90 PLOT 69,640,512',#0d
                db '95 P%=POINT(640,512)',#0d
                db '98 PLOT 69,1000,512',#0d
                db '100 GOTO 100',#0d
                db 'RUN',#0d,0

                defs #8000-$,#ff
