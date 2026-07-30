; SPDX-License-Identifier: BSD-3-Clause
;
; Original RainBIOS primary-slot cartridge fixture.
;
; It deliberately uses no firmware calls: the public AB/INIT header is enough
; to prove that RainBIOS found the cartridge and transferred control to it.

                org #4000

                db #41,#42                     ; public MSX "AB" ROM signature
                dw primary_init
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs #4010-$,0

primary_init:
                ld a,#52                       ; "RAIN" marker in main RAM
                ld (#f300),a
                ld a,#41
                ld (#f301),a
                ld a,#49
                ld (#f302),a
                ld a,#4e
                ld (#f303),a
                ld a,#5e
                ld (#f304),a

primary_init_loop:
                jp primary_init_loop

                defs #8000-$,#ff
