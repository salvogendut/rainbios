; SPDX-License-Identifier: BSD-3-Clause
;
; Probe cartridge for the RainBIOS MSX2 SUB-ROM. Calls EXTROM into the
; SUB-ROM bitmap/palette/VRAM entries and records observable markers in
; page-3 RAM for the host-side runner.

EXTROM          equ #015F
EXBRSA          equ #faf8
SCRMOD          equ #fcaf
NAMBAS          equ #f922
PATBAS          equ #f926
ATRBAS          equ #f928

SUB_CHGMOD      equ #00d1
SUB_WRTVRM      equ #0109
SUB_RDVRM       equ #010d
SUB_WRTVDP      equ #012d
SUB_VDPSTA      equ #0131
SUB_INIPLT      equ #0141
SUB_GETPLT      equ #0149
SUB_SETPLT      equ #014d

                org #4000

                db #41,#42                     ; AB signature
                dw subrom_services_init
                dw 0,0,0
                defs #4010-$,0

subrom_services_init:
                ; CHGMOD 5: SCRMOD and table bases should update.
                ld a,5
                call subrom_call_chgmod
                ld a,(SCRMOD)
                ld (marker_scrmod5),a
                ld hl,(NAMBAS)
                ld (marker_nambas5),hl
                ld hl,(PATBAS)
                ld (marker_patbas5),hl
                ld hl,(ATRBAS)
                ld (marker_atrbas5),hl

                ; CHGMOD 6.
                ld a,6
                call subrom_call_chgmod
                ld a,(SCRMOD)
                ld (marker_scrmod6),a

                ; CHGMOD 7.
                ld a,7
                call subrom_call_chgmod
                ld a,(SCRMOD)
                ld (marker_scrmod7),a

                ; CHGMOD 8.
                ld a,8
                call subrom_call_chgmod
                ld a,(SCRMOD)
                ld (marker_scrmod8),a

                ; 16-bit WRTVRM/RDVRM: write a marker to a 16-bit VRAM address
                ; that needs the extended register (R14) and read it back.
                ld hl,#8000
                ld a,#5a
                call subrom_call_wrvrm
                ld hl,#8000
                call subrom_call_rdvrm
                ld (marker_vram),a

                ; SETPLT + GETPLT round trip on palette index 2.
                ld a,#00
                ld d,2
                ld e,#07
                call subrom_call_setplt
                ld a,2
                call subrom_call_getplt
                ld a,b
                ld (marker_plt_b),a
                ld a,c
                ld (marker_plt_c),a

subrom_services_spin:
                jp subrom_services_spin

subrom_call_chgmod:
                push ix
                ld ix,SUB_CHGMOD
                call EXTROM
                pop ix
                ret

subrom_call_wrvrm:
                push ix
                ld ix,SUB_WRTVRM
                call EXTROM
                pop ix
                ret

subrom_call_rdvrm:
                push ix
                ld ix,SUB_RDVRM
                call EXTROM
                pop ix
                ret

subrom_call_setplt:
                push ix
                ld ix,SUB_SETPLT
                call EXTROM
                pop ix
                ret

subrom_call_getplt:
                push ix
                ld ix,SUB_GETPLT
                call EXTROM
                pop ix
                ret

marker_scrmod5   equ #f360
marker_nambas5   equ #f361
marker_patbas5   equ #f363
marker_atrbas5   equ #f365
marker_scrmod6   equ #f367
marker_scrmod7   equ #f368
marker_scrmod8   equ #f369
marker_vram      equ #f36a
marker_plt_b     equ #f36b
marker_plt_c     equ #f36c

                defs #8000-$,#ff
