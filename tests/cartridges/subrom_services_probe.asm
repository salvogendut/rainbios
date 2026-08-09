; SPDX-License-Identifier: BSD-3-Clause
;
; Probe cartridge for the RainBIOS MSX2 SUB-ROM. Calls EXTROM into the
; SUB-ROM bitmap/palette/VRAM entries and records observable markers in
; page-3 RAM for the host-side runner.

EXTROM          equ #015F
MAIN_RDVRM      equ #004a
MAIN_WRTVRM     equ #004d
MAIN_INITXT     equ #006c
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
VDP_CONTROL     equ #99
VDP_INDIRECT    equ #9b

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

                ; Start a full bitmap HMMV and immediately enter text mode.
                ; INITXT must wait for CE before reusing low VRAM, or the
                ; asynchronous command damages the freshly uploaded font.
                ld a,36
                out (VDP_CONTROL),a
                ld a,#91
                out (VDP_CONTROL),a
                ld hl,hmmv_command
                ld b,11
subrom_services_hmmv_out:
                ld a,(hl)
                out (VDP_INDIRECT),a
                inc hl
                djnz subrom_services_hmmv_out
                call MAIN_INITXT
                ld hl,#0a08                    ; glyph 'A', first pattern row
                call MAIN_RDVRM
                ld (marker_font_after_ce),a
                ld a,8                         ; restore the probe's final mode
                call subrom_call_chgmod

                ; 16-bit WRTVRM/RDVRM: write a marker to a 16-bit VRAM address
                ; that needs the extended register (R14) and read it back.
                ld hl,#8000
                ld a,#5a
                call subrom_call_wrvrm
                ld hl,#8000
                call subrom_call_rdvrm
                ld (marker_vram),a

                ; Main-BIOS VRAM calls are 14-bit and must force V9938 R14
                ; back to bank zero. Seed both banks, poison R14 through the
                ; SUB-ROM, then verify that WRTVRM changes only low VRAM.
                ld hl,#0100
                ld a,#4d
                call subrom_call_wrvrm
                ld hl,#8100
                ld a,#3c
                call subrom_call_wrvrm
                ld b,2
                ld c,14
                call subrom_call_wrtvdp
                ld hl,#0100
                ld a,#a5
                call MAIN_WRTVRM
                ld hl,#0100
                call subrom_call_rdvrm
                ld (marker_low_vram),a
                ld hl,#8100
                call subrom_call_rdvrm
                ld (marker_high_vram),a

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

hmmv_command:
                dw 0                           ; DX
                dw 0                           ; DY
                dw 256                         ; NX (Screen 8 width)
                dw 212                         ; NY
                db #ff                         ; CLR
                db 0                           ; ARG
                db #c0                         ; HMMV

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

subrom_call_wrtvdp:
                push ix
                ld ix,SUB_WRTVDP
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
marker_low_vram  equ #f36d
marker_high_vram equ #f36e
marker_font_after_ce equ #f36f

                defs #8000-$,#ff
