; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only slot-2 cartridge. Its H.TIMI hook selects the RainBIOS BBC BASIC
; menu entry, waits for the interpreter, then types a scrolling text program
; through the published circular key buffer. The program prints forty lines
; (scrolling the text screen), writes a completion marker to page-3 RAM, and
; spins so 1983 can validate the scrolled state.

PUTPNT          equ #f3f8
GETPNT          equ #f3fa
KEYBUF          equ #fbf0
KEYBUF_END      equ #fc18
HOOK_TIMI       equ #fd9f
TEST_FRAME      equ #f3c0
TEST_INDEX      equ #f3c2
TEST_DONE       equ #f3c4
SCROLL_MARKER   equ #f3c8

                org #4000

                db #41,#42
                dw scroll_input_init
                dw 0,0,0
                defs 6,0

scroll_input_init:
                xor a
                ld (TEST_FRAME),a
                ld (TEST_FRAME+1),a
                ld (TEST_INDEX),a
                ld (TEST_INDEX+1),a
                ld (TEST_DONE),a
                ld hl,scroll_input_hook_template
                ld de,HOOK_TIMI
                ld bc,5
                ldir
                ret

scroll_input_hook_template:
                db #f7                         ; RST 30h / CALLF
                db 2                           ; primary slot 2
                dw scroll_input_tick
                db #c9                         ; RET after inline operands

scroll_input_tick:
                ld a,(TEST_DONE)
                or a
                ret nz
                ld hl,(TEST_FRAME)
                inc hl
                ld (TEST_FRAME),hl
                ld a,h
                or a
                jr nz,scroll_input_wait_program
                ld a,l
                cp 1
                jr z,scroll_input_space
                cp 20
                jr z,scroll_input_menu
scroll_input_wait_program:
                ld de,300
                or a
                sbc hl,de
                ret c
                bit 0,l
                ret nz
scroll_input_program:
                ld de,(TEST_INDEX)
                ld hl,scroll_program
                add hl,de
                ld a,(hl)
                or a
                jr z,scroll_input_done
                call scroll_input_put
                ret nc
                ld de,(TEST_INDEX)
                inc de
                ld (TEST_INDEX),de
                ret
scroll_input_space:
                ld a,#20
                call scroll_input_put
                ret
scroll_input_menu:
                ld a,'1'
                call scroll_input_put
                ret
scroll_input_done:
                ld a,#ff
                ld (TEST_DONE),a
                ld a,#c9
                ld (HOOK_TIMI),a              ; remove the test hook
                ret

; Add A unless the next write pointer would collide with the read pointer.
scroll_input_put:
                push af
                ld hl,(PUTPNT)
                ld d,h
                ld e,l
                inc hl
                ld a,h
                cp KEYBUF_END/256
                jr nz,scroll_input_compare
                ld a,l
                cp KEYBUF_END&255
                jr nz,scroll_input_compare
                ld hl,KEYBUF
scroll_input_compare:
                ld bc,(GETPNT)
                ld a,l
                cp c
                jr nz,scroll_input_store
                ld a,h
                cp b
                jr z,scroll_input_full
scroll_input_store:
                pop af
                ld (de),a
                ld (PUTPNT),hl
                scf
                ret
scroll_input_full:
                pop af
                or a
                ret

scroll_program:
                db '10 FOR I=1 TO 40',#0d
                db '20 PRINT "RAINBIOS SCROLL ";I',#0d
                db '30 NEXT I',#0d
                db '40 ?&F3C8=&A5',#0d
                db '50 GOTO 50',#0d
                db 'RUN',#0d,0

                defs #8000-$,#ff
