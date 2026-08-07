; SPDX-License-Identifier: BSD-3-Clause
;
; Original RainBIOS primary-slot cartridge fixture.
;
; It deliberately uses no firmware calls: the public AB/INIT header is enough
; to prove that RainBIOS found the cartridge and transferred control to it.
; The INIT entry snapshots the register state (A/F/BC/DE/HL/IX/IY/SP at
; F310-F31D) so the cartridge probe can characterize the documented startup
; contract, then writes the RAIN marker and spins.

                org #4000

                db #41,#42                     ; public MSX "AB" ROM signature
                dw primary_init
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs #4010-$,0

primary_init:
                ex af,af'                      ; park AF
                ld a,h
                ld (#f316),a                   ; H
                ld a,l
                ld (#f317),a                   ; L
                ld a,b
                ld (#f312),a                   ; B
                ld a,c
                ld (#f313),a                   ; C
                ld a,d
                ld (#f314),a                   ; D
                ld a,e
                ld (#f315),a                   ; E
                ex af,af'                      ; restore AF
                push af
                pop hl
                ld a,h
                ld (#f310),a                   ; A
                ld a,l
                ld (#f311),a                   ; F
                push ix
                pop de
                ld a,d
                ld (#f318),a                   ; IX high
                ld a,e
                ld (#f319),a                   ; IX low
                push iy
                pop de
                ld a,d
                ld (#f31a),a                   ; IY high
                ld a,e
                ld (#f31b),a                   ; IY low
                ld hl,0
                add hl,sp
                ld a,h
                ld (#f31c),a                   ; SP high
                ld a,l
                ld (#f31d),a                   ; SP low
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
