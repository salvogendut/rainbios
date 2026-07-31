; SPDX-License-Identifier: BSD-3-Clause
;
; Optional read-only disk extension for the Philips NMS 8250 WD2793 layout.

                org #4000

                db #41,#42                     ; AB signature
                dw disk_driver_init
                dw 0                           ; BASIC statement handler
                dw 0                           ; device handler
                dw 0                           ; BASIC text pointer
                defs #4010-$,0

                jp disk_phydio                 ; 4010 DSKIO
                jp disk_unsupported            ; 4013 DSKCHG
                jp disk_unsupported            ; 4016 GETDPB
                jp disk_no_choice              ; 4019 CHOICE
                jp disk_unsupported            ; 401C DSKFMT
                jp disk_motor_off              ; 401F MTOFF
                ret                            ; 4022 BASIC
                defs #4030-$,#ff

                include "disk_nms8250_driver.asm"

disk_no_choice:
                ld hl,0
                ret

                defs #8000-$,#ff
