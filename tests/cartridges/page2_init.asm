; SPDX-License-Identifier: BSD-3-Clause
;
; Original RainBIOS page-2 cartridge fixture: the public AB/INIT header lives
; in page 1 (4000h) but the INIT routine is at 8000h in page 2, the layout a
; mapper-style cartridge uses before it installs its own bank switching.
; The INIT entry snapshots the register state (A/F/BC/DE/HL/IX/IY/SP at
; F310-F31D) so the cartridge probe can verify the startup contract for this
; arrangement, then writes a marker and spins.

                org #4000

                db #41,#42                     ; public MSX "AB" ROM signature
                dw page2_init
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs #8000-$,0

page2_init:
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

; Exercise the same clean-console transition for mapper-style page-2 INIT.
                ld hl,page2_init_message
page2_init_print:
                ld a,(hl)
                or a
                jr z,page2_init_loop
                call #00a2                     ; BIOS CHPUT
                inc hl
                jr page2_init_print

page2_init_loop:
                jp page2_init_loop

page2_init_message:
                db "CARTRIDGE INIT",0

                defs #c000-$,#ff
