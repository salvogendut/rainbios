; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only cartridge which claims RBP1 but has a bad checksum. Its ordinary
; INIT writes a marker and retains control, so fail-closed discovery can prove
; that RainBIOS neither invokes nor advertises it.

                org #4000

                db #41,#42
                dw invalid_payload_init
                dw 0,0,0
                defs 6,0

invalid_payload_init:
                ld hl,#f300
                ld (hl),'B'
                inc hl
                ld (hl),'A'
                inc hl
                ld (hl),'D'
                inc hl
                ld (hl),'!'
invalid_payload_loop:
                jr invalid_payload_loop

                defs #7ff0-$,#ff
                db 'R','B','P','1'
                db 1,16,1,#07
                dw #4010,#8000,#f300
                db 2
                db #0c                         ; deliberately wrong checksum

                defs #8000-$,#ff
