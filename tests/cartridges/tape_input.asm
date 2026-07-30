; SPDX-License-Identifier: BSD-3-Clause
;
; Original RainBIOS cassette-input fixture. The cartridge reads one standard
; CAS data block only through TAPION/TAPIN/TAPIOF and exposes distinct success
; and failure loops for emulator-side validation.

TAPION          equ #00e1
TAPIN           equ #00e4
TAPIOF          equ #00e7
RESULT          equ #f300
TRACE           equ #f310

                org #4000

                db #41,#42
                dw tape_input_init
                dw 0,0,0
                defs #4010-$,0

tape_input_init:
                call TAPION
                jr c,tape_input_fail_open
                ld hl,tape_expected
                ld de,TRACE
                ld b,tape_expected_end-tape_expected
tape_input_byte:
                push bc
                push de
                push hl
                call TAPIN
                pop hl
                pop de
                pop bc
                jr c,tape_input_fail_read
                ld (de),a
                inc de
                cp (hl)
                jr nz,tape_input_fail_compare
                inc hl
                djnz tape_input_byte
                call TAPIOF
                ld hl,tape_success_marker
                ld de,RESULT
                ld bc,4
                ldir
tape_input_success:
                jp tape_input_success_loop

tape_input_fail_close:
                push af
                call TAPIOF
                pop af
tape_input_fail:
                ld (RESULT),a
                ret

tape_input_fail_open:
                ld a,#e0
                ld (RESULT),a
                jp tape_input_open_failure
tape_input_fail_read:
                ld a,#e1
                call tape_input_fail_close
                ld h,#41
                jr tape_input_index_failure
tape_input_fail_compare:
                ld a,#e2
                call tape_input_fail_close
                ld h,#42
tape_input_index_failure:
                ld a,8
                sub b
                ld l,a
                add a,a
                add a,l
                ld l,a
                jp (hl)

tape_expected:
                db 'RAINTAPE'
tape_expected_end:
tape_success_marker:
                db 'TAPE'

                defs #4100-$,#ff
tape_input_read_failure_1:
                jp tape_input_read_failure_1
tape_input_read_failure_2:
                jp tape_input_read_failure_2
tape_input_read_failure_3:
                jp tape_input_read_failure_3
tape_input_read_failure_4:
                jp tape_input_read_failure_4
tape_input_read_failure_5:
                jp tape_input_read_failure_5
tape_input_read_failure_6:
                jp tape_input_read_failure_6
tape_input_read_failure_7:
                jp tape_input_read_failure_7
tape_input_read_failure_8:
                jp tape_input_read_failure_8

                defs #4200-$,#ff
tape_input_compare_failure_1:
                jp tape_input_compare_failure_1
tape_input_compare_failure_2:
                jp tape_input_compare_failure_2
tape_input_compare_failure_3:
                jp tape_input_compare_failure_3
tape_input_compare_failure_4:
                jp tape_input_compare_failure_4
tape_input_compare_failure_5:
                jp tape_input_compare_failure_5
tape_input_compare_failure_6:
                jp tape_input_compare_failure_6
tape_input_compare_failure_7:
                jp tape_input_compare_failure_7
tape_input_compare_failure_8:
                jp tape_input_compare_failure_8

                defs #4300-$,#ff
tape_input_open_failure:
                jp tape_input_open_failure

                defs #4400-$,#ff
tape_input_success_loop:
                jp tape_input_success_loop

                defs #8000-$,#ff
