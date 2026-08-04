; SPDX-License-Identifier: BSD-3-Clause
;
; Probe cartridge for the RainBIOS MSX2 SUB-ROM VDP command transfers and
; real-time clock. Calls EXTROM into the BLTVV/BLTVM/BLTMV and
; REDCLK/WRTCLK entries and records observable markers in page-3 RAM for
; the host-side runner.

EXTROM          equ #015F
EXBRSA          equ #faf8
SCRMOD          equ #fcaf

SUB_CHGMOD      equ #00d1
SUB_WRTVRM      equ #0109
SUB_RDVRM       equ #010d
SUB_BLTVV       equ #0191
SUB_BLTVM       equ #0195
SUB_BLTMV       equ #0199
SUB_REDCLK      equ #01f5
SUB_WRTCLK      equ #01f9

SX              equ #f562
SY              equ #f564
DX              equ #f566
DY              equ #f568
NX              equ #f56a
NY              equ #f56c

; Work RAM for the transfer buffers (page-3 free area).
RAM_BUFFER      equ #e000
VRAM_PATTERN    equ #0020
VRAM_DEST       equ #0200

                org #4000

                db #41,#42                     ; AB signature
                dw subrom_cmdclock_init
                dw 0,0,0
                defs #4010-$,0

subrom_cmdclock_init:
                ; CHGMOD 5 so the command engine has a bitmap mode.
                ld a,5
                call subrom_call_chgmod

                ; --- BLTVV: VRAM-to-VRAM copy. Write a source pattern at
                ; VRAM byte 0 (pixel x=0,y=0 in SC5 = byte 0), then copy
                ; NX=8 pixels (4 bytes) to DX pixel 0x20 (byte 0x10).
                ; WRTVRM clobbers HL, so track the address in work RAM.
                ld hl,0
                ld (addr_tmp),hl
                ld b,4
bltvv_write:
                ld a,b
                ld hl,(addr_tmp)
                call subrom_call_wrvrm
                ld hl,(addr_tmp)
                inc hl
                ld (addr_tmp),hl
                djnz bltvv_write

                xor a
                ld (SX),a
                ld (SX+1),a
                ld (SY),a
                ld (SY+1),a
                ld a,#20
                ld (DX),a
                ld a,#00
                ld (DX+1),a
                xor a
                ld (DY),a
                ld (DY+1),a
                ld a,8
                ld (NX),a
                xor a
                ld (NX+1),a
                ld a,1
                ld (NY),a
                xor a
                ld (NY+1),a
                call subrom_call_bltvv

                ; Read back the copied bytes at VRAM byte 0x10-0x13.
                ld hl,#0010
                ld (addr_tmp),hl
                ld b,4
                ld de,marker_bltvv
bltvv_read:
                ld hl,(addr_tmp)
                call subrom_call_rdvrm
                ld (de),a
                inc de
                ld hl,(addr_tmp)
                inc hl
                ld (addr_tmp),hl
                djnz bltvv_read

                ; --- BLTVM: RAM-to-VRAM copy. Build a small screen-data
                ; header (NX=8, NY=1) plus four pixel bytes at RAM_BUFFER.
                ; The CPU feeds each pixel (4-bit colour in SC5) through R44.
                ; Dest pixel 0x40 = VRAM byte 0x20.
                ld hl,RAM_BUFFER
                ld a,8
                ld (hl),a
                inc hl
                xor a
                ld (hl),a
                inc hl
                ld a,1
                ld (hl),a
                inc hl
                xor a
                ld (hl),a
                inc hl
                ld b,4
bltvm_byte:
                ld a,#33
                ld (hl),a
                inc hl
                djnz bltvm_byte

                ld a,RAM_BUFFER&255
                ld (SX),a
                ld a,RAM_BUFFER>>8
                ld (SX+1),a
                xor a
                ld (SY),a
                ld (SY+1),a
                ld a,#40
                ld (DX),a
                ld a,#00
                ld (DX+1),a
                xor a
                ld (DY),a
                ld (DY+1),a
                call subrom_call_bltvm

                ; Read back the four VRAM bytes at 0x20-0x23.
                ld hl,#0020
                ld (addr_tmp),hl
                ld b,4
                ld de,marker_bltvm
bltvm_readback:
                ld hl,(addr_tmp)
                call subrom_call_rdvrm
                ld (de),a
                inc de
                ld hl,(addr_tmp)
                inc hl
                ld (addr_tmp),hl
                djnz bltvm_readback

                ; --- BLTMV: VRAM-to-RAM copy. Read back the block that BLTVM
                ; just wrote (8 pixels of colour 3 = four bytes of 0x33).
                xor a
                ld (SX),a
                ld (SX+1),a
                xor a
                ld (SY),a
                ld (SY+1),a
                ld a,RAM_BUFFER&255
                ld (DX),a
                ld a,RAM_BUFFER>>8
                ld (DX+1),a
                xor a
                ld (DY),a
                ld (DY+1),a
                ld a,8
                ld (NX),a
                xor a
                ld (NX+1),a
                ld a,1
                ld (NY),a
                xor a
                ld (NY+1),a
                call subrom_call_bltmv

                ; Verify the header plus the first pixel bytes.
                ld a,(RAM_BUFFER)
                ld (marker_bltmv_nx),a
                ld a,(RAM_BUFFER+4)
                ld (marker_bltmv_p0),a
                ld a,(RAM_BUFFER+5)
                ld (marker_bltmv_p1),a
                ld a,(RAM_BUFFER+6)
                ld (marker_bltmv_p2),a

                ; --- RTC: WRTCLK then REDCLK round trip on register 0 of
                ; block 3 (general-purpose clock RAM).
                ld a,#0a
                ld c,#30
                call subrom_call_wrtclk
                ld c,#30
                call subrom_call_redclk
                ld (marker_rtc),a

subrom_cmdclock_spin:
                jp subrom_cmdclock_spin

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

subrom_call_bltvv:
                push ix
                ld ix,SUB_BLTVV
                call EXTROM
                pop ix
                ret

subrom_call_bltvm:
                push ix
                ld ix,SUB_BLTVM
                call EXTROM
                pop ix
                ret

subrom_call_bltmv:
                push ix
                ld ix,SUB_BLTMV
                call EXTROM
                pop ix
                ret

subrom_call_wrtclk:
                push ix
                ld ix,SUB_WRTCLK
                call EXTROM
                pop ix
                ret

subrom_call_redclk:
                push ix
                ld ix,SUB_REDCLK
                call EXTROM
                pop ix
                ret

marker_bltvv    equ #f380
marker_bltvm    equ #f384
marker_bltmv_nx equ #f388
marker_bltmv_p0 equ #f389
marker_bltmv_p1 equ #f38a
marker_bltmv_p2 equ #f38b
marker_rtc      equ #f387
addr_tmp        equ #f3a0

                defs #8000-$,#ff
