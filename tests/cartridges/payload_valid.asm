; SPDX-License-Identifier: BSD-3-Clause
;
; Test-only minimal valid RainBIOS payload. Declaring a valid RBP1 descriptor
; at 7FF0h claims the slot during cold-boot discovery, which keeps the cold-boot
; disk bootstrap from auto-running so tests can reach the interactive menu. The
; payload entry itself is never launched by these tests.

                org #4000

                db #41,#42              ; "AB"
                dw payload_entry        ; INIT (skipped once the RBP1 claims it)
                dw 0,0,0
                defs 6,0

payload_entry:
                ret                     ; page-1 BASIC entry, unused by tests

                defs #7ff0-$,#ff        ; pad to the descriptor

payload_descriptor:
                db "RBP1"
                db 1                    ; descriptor version
                db 16                   ; descriptor length
                db 1                    ; payload type: BASIC
                db 0                    ; required service bits
                dw payload_entry        ; page-1 entry (4010h)
                dw #8000                ; contiguous RAM start
                dw #c000                ; exclusive RAM end
                db 2                    ; RAM page limit
                db #47                  ; additive checksum (sum of 16 == 0)

                defs #8000-$,#ff
