; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only slot-1 cartridge. At INIT time it dirties the Screen 0 name table
; and the Screen 2 pattern/colour planes, calls the published CLS entry after
; each, and records the post-CLS VRAM bytes and cursor in main RAM for the
; openMSX probe. Results are captured synchronously so the later menu render
; cannot disturb them.

CHGMOD          equ #005f
FILVRM          equ #0056
RDVRM           equ #004a
CLS             equ #00c3
CSRX            equ #f3dd
CSRY            equ #f3dc
CLS_DONE        equ #f39e
CLS_RESULT      equ #f3a0

                org #4000

                db #41,#42                     ; public MSX "AB" ROM signature
                dw cls_input
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs 6,0

cls_input:
                xor a
                ld (CLS_DONE),a
                call cls_test_screen0
                call cls_test_screen2
                ld a,#ff
                ld (CLS_DONE),a
                ret

cls_test_screen0:
                xor a
                call chgmod                    ; Screen 0
                ld hl,#0000
                ld bc,#0040
                ld a,#41
                call filvrm                    ; dirty the name table
                call cls
                ld hl,#0000
                call rdvrm
                ld (CLS_RESULT),a              ; expect a space (20h)
                ld a,(CSRX)
                ld (CLS_RESULT+1),a            ; expect 1
                ld a,(CSRY)
                ld (CLS_RESULT+2),a            ; expect 1
                ret

cls_test_screen2:
                ld a,2
                call chgmod                    ; Graphics II
                ld hl,#0000
                ld bc,#0040
                ld a,#ff
                call filvrm                    ; dirty pattern plane
                ld hl,#2000
                ld bc,#0040
                ld a,#f1
                call filvrm                    ; dirty colour plane
                call cls
                ld hl,#0000
                call rdvrm
                ld (CLS_RESULT+3),a            ; expect 0
                ld hl,#2000
                call rdvrm
                ld (CLS_RESULT+4),a            ; expect the background colour
                ld a,(CSRX)
                ld (CLS_RESULT+5),a            ; expect 1
                ld a,(CSRY)
                ld (CLS_RESULT+6),a            ; expect 1
                ret

                defs #8000-$,#ff
