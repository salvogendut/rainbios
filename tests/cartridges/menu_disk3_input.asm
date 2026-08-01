; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only primary-slot cartridge. Its INIT installs a standard five-byte
; H.TIMI hook in slot 2. The hook injects Space and "3" through the published
; key buffer at separated VBlanks so 1983 can reach the boot menu and confirm
; the reserved IDE-cartridge option stays a no-op that returns to the menu.

PUTPNT          equ #f3f8
HOOK_TIMI       equ #fd9f
TEST_STATE      equ #f398

                org #4000

                db #41,#42
                dw menu_disk3_input_init
                dw 0,0,0
                defs 6,0

menu_disk3_input_init:
                xor a
                ld (TEST_STATE),a
                ld hl,menu_disk3_input_hook_template
                ld de,HOOK_TIMI
                ld bc,5
                ldir
                ret

menu_disk3_input_hook_template:
                db #f7                         ; RST 30h / CALLF
                db 2                           ; primary slot 2
                dw menu_disk3_input_tick
                db #c9                         ; RET after inline operands

menu_disk3_input_tick:
                ld a,(TEST_STATE)
                cp #ff
                ret z
                inc a
                ld (TEST_STATE),a
                cp 2
                jr z,menu_disk3_input_space
                cp 20
                ret nz
                ld a,#ff
                ld (TEST_STATE),a
                ld a,'3'
                jr menu_disk3_input_put
menu_disk3_input_space:
                ld a,#20
menu_disk3_input_put:
                ld hl,(PUTPNT)
                ld (hl),a
                inc hl
                ld (PUTPNT),hl
                ret

                defs #8000-$,#ff
