; SPDX-License-Identifier: BSD-3-Clause
;
; Test SUB-ROM fixture for the RainBIOS M5 SUB-ROM calling contract.
;
; Carries the standard "CD" header so the boot scan and CHKSLZ publish its
; slot in EXBRSA. Two routines are exposed:
;
;  0100h  subrom_probe_write: writes A to F362h and returns (EXTROM target).
;  0120h  subrom_probe_spin:  writes #5a to F363h, then spins forever. It is
;         entered only through the documented `push IX; jp SUBROM` pattern,
;         whose final RET returns to the cartridge scan; spinning here keeps
;         the probe observable instead of letting the boot continue.

                org #0000

                db "CD"                        ; standard SUB-ROM signature
                dw 0                           ; INIT (none)
                dw 0                           ; statement handler
                dw 0                           ; device handler
                defs #0100-$,0

subrom_probe_write:
                ld (#f362),a                   ; observable work-area marker
                ret

                defs #0120-$,#ff

subrom_probe_spin:
                ld a,#5a
                ld (#f363),a
subrom_probe_spin_loop:
                jp subrom_probe_spin_loop

                defs #4000-$,#ff
