; SPDX-License-Identifier: BSD-3-Clause
;
; Probe cartridge for the MSX2 SUB-ROM calling contract. Runs on the MSX2
; main-ROM build and calls the public SUBROM/EXTROM/CHKSLZ entries, recording
; observable markers in page-3 RAM for the host-side runner.
;
; CHKSLZ and EXTROM return normally and are checked inline. SUBROM follows the
; documented `push IX; jp SUBROM` pattern into a SUB-ROM routine that spins, so
; the final CPU state stays in the SUB-ROM with the marker visible.

CHKSLZ          equ #0162
EXTROM          equ #015F
SUBROM          equ #015C
EXBRSA          equ #faf8

SUBROM_WRITE    equ #0100
SUBROM_SPIN     equ #0120

                org #4000

                db #41,#42                     ; AB signature
                dw subrom_probe_init
                dw 0,0,0
                defs #4010-$,0

subrom_probe_init:
                ; CHKSLZ: republish EXBRSA and report carry.
                call CHKSLZ
                ld a,0
                jr nc,subrom_probe_no_subrom
                inc a
subrom_probe_no_subrom:
                ld (marker_chkslz),a
                ld a,(EXBRSA)
                ld (marker_exbrsa),a

                ; EXTROM: call the SUB-ROM routine at 0100h, which writes A
                ; to F362h. Seed A with a distinctive value; the write is the
                ; observable marker that the SUB-ROM code actually ran.
                ld a,#a5
                ld ix,SUBROM_WRITE
                call EXTROM

                ; SUBROM: documented `push IX; jp SUBROM` pattern into the
                ; spinning routine. The marker is written and the CPU remains
                ; in the SUB-ROM so the final state is observable.
                ld ix,SUBROM_SPIN
                push ix
                jp SUBROM

marker_chkslz   equ #f360
marker_exbrsa   equ #f361
marker_extrom   equ #f362
marker_subrom   equ #f363

                defs #8000-$,#ff
