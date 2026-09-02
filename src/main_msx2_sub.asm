; SPDX-License-Identifier: BSD-3-Clause
;
; RainBIOS MSX2 SUB-ROM.
;
; A self-contained 16 KiB extended-VDP ROM installed in slot 3-0. It carries
; the standard "CD" header and the documented SUB-ROM fixed-entry layout, and
; provides the bitmap screen modes, palette, and 16-bit VRAM access through
; the entries reached by the main-ROM EXTROM dispatch.
;
; The SUB-ROM runs with page 0 (or page 1) switched to its own slot, so it
; cannot call the main BIOS: VDP register writes, VRAM access, and the
; R8-R23/R0-R7 shadows are all performed here directly.

VDP_DATA        equ #98
VDP_CONTROL     equ #99
VDP_PALT        equ #9a
VDP_REGS        equ #9b
RTC_ADDR        equ #b4
RTC_DATA        equ #b5

; VDP command work area.
SX              equ #f562
SY              equ #f564
DX              equ #f566
DY              equ #f568
NX              equ #f56a
NY              equ #f56c
CDUMMY          equ #f56e
L_OP            equ #f570
cmd_temp        equ #f572

R0SAV           equ #f3df
RG1SAV          equ #f3e0
RG8SAV          equ #ffe7
SCRMOD          equ #fcaf
LINLEN          equ #f3b0
CSRX            equ #f3dd
CSRY            equ #f3dc
FORCLR          equ #f3e9
BAKCLR          equ #f3ea
BDRCLR          equ #f3eb
NAMBAS          equ #f922
PATBAS          equ #f926
ATRBAS          equ #f928
DPPAGE          equ #faf5
ACPAGE          equ #faf6

                org #0000

                db "CD"                        ; standard SUB-ROM signature
                dw 0                           ; INIT (none)
                dw 0                           ; statement handler
                dw 0                           ; device handler

; Keep the reserved low entries as safe returns so accidental dispatch into
; them cannot execute main-ROM bytes from the SUB-ROM slot.
                defs #0008-$,#c9
                ret                             ; 0008 CHRGTR
                defs #0010-$,#ff
                ret                             ; 0010 WRSLT
                defs #0014-$,#ff
                ret                             ; 0014 OUTDO
                defs #0018-$,#ff
                ret                             ; 0018 CALSLT
                defs #001c-$,#ff
                ret                             ; 001C DCOMPR
                defs #0020-$,#ff
                ret                             ; 0020 ENASLT
                defs #0028-$,#ff
                ret                             ; 0028 GETYPR
                defs #0030-$,#ff
                ret                             ; 0030 CALLF
                defs #0038-$,#ff
                ret                             ; 0038 KEYINT
                defs #0066-$,#ff
                ret                             ; 0066 NMI

; Graphics and screen-mode entry table. Entries that are not implemented in
; this slice return cleanly; implemented entries jump to their bodies below.
; EI deliberately precedes JP at implemented fixed entries: on the Z80 the
; JP is the required one-instruction delay, so interrupts become eligible at
; the first instruction of the target routine. This is the MSX2 SUB-ROM ABI
; convention; it must not be padded with a NOP or rewritten as an immediate
; interrupt-enable sequence.
                defs #0085-$,#c9
                ret                             ; 0085 DOGRPH
                defs #0089-$,#ff
                ret                             ; 0089 GRPPRT
                defs #008d-$,#ff
                ret                             ; 008D SCALXY
                defs #0091-$,#ff
                ret                             ; 0091 MAPXYC
                defs #0095-$,#ff
                ret                             ; 0095 READC
                defs #0099-$,#ff
                ret                             ; 0099 SETATR
                defs #009d-$,#ff
                ret                             ; 009D SETC
                defs #00a1-$,#ff
                ret                             ; 00A1 TRIGHT
                defs #00a5-$,#ff
                ret                             ; 00A5 RIGHTC
                defs #00a9-$,#ff
                ret                             ; 00A9 TLEFTC
                defs #00ad-$,#ff
                ret                             ; 00AD LEFTC
                defs #00b1-$,#ff
                ret                             ; 00B1 TDOWNC
                defs #00b5-$,#ff
                ret                             ; 00B5 DOWNC
                defs #00b9-$,#ff
                ret                             ; 00B9 TUPC
                defs #00bd-$,#ff
                ret                             ; 00BD UPC
                defs #00c1-$,#ff
                ret                             ; 00C1 SCANR
                defs #00c5-$,#ff
                ret                             ; 00C5 SCANL
                defs #00c9-$,#ff
                ret                             ; 00C9 NVBXLN
                defs #00cd-$,#ff
                ret                             ; 00CD NVBXFL

                defs #00d1-$,#c9
                ei
                jp sub_chgmod                   ; 00D1 CHGMOD
                defs #00d5-$,#c9
                ret                             ; 00D5 INITXT
                defs #00d9-$,#ff
                ret                             ; 00D9 INIT32
                defs #00dd-$,#ff
                ret                             ; 00DD INIGRP
                defs #00e1-$,#ff
                ret                             ; 00E1 INIMLT
                defs #00e5-$,#ff
                ret                             ; 00E5 SETTXT
                defs #00e9-$,#ff
                ret                             ; 00E9 SETT32
                defs #00ed-$,#ff
                ret                             ; 00ED SETGRP
                defs #00f1-$,#ff
                ret                             ; 00F1 SETMLT
                defs #00f5-$,#ff
                ret                             ; 00F5 CLRSPR
                defs #00f9-$,#ff
                ret                             ; 00F9 CALPAT
                defs #00fd-$,#ff
                ret                             ; 00FD CALATR
                defs #0101-$,#ff
                ret                             ; 0101 GSPSIZ
                defs #0105-$,#ff
                ret                             ; 0105 GETPAT

                defs #0109-$,#c9
                ei
                jp sub_wrvrm                    ; 0109 WRTVRM (16-bit)
                defs #010d-$,#c9
                ei
                jp sub_rdvrm                    ; 010D RDVRM (16-bit)
                defs #0111-$,#c9
                ret                             ; 0111 CHGCLR
                defs #0115-$,#ff
                ret                             ; 0115 CLS
                defs #0119-$,#ff
                ret                             ; 0119 CLRTXT

                defs #012d-$,#c9
                ei
                jp sub_wrtvdp                   ; 012D WRTVDP
                defs #0131-$,#c9
                ei
                jp sub_vdpsta                   ; 0131 VDPSTA
                defs #013d-$,#c9
                ret                             ; 013D SETPAG

                defs #0141-$,#c9
                ei
                jp sub_iniplt                   ; 0141 INIPLT
                defs #0145-$,#c9
                ei
                jp sub_rstplt                   ; 0145 RSTPLT
                defs #0149-$,#c9
                ei
                jp sub_getplt                   ; 0149 GETPLT
                defs #014d-$,#c9
                ei
                jp sub_setplt                   ; 014D SETPLT

                defs #0191-$,#c9
                ei
                jp sub_bltvv                    ; 0191 BLTVV
                defs #0195-$,#c9
                ei
                jp sub_bltvm                    ; 0195 BLTVM
                defs #0199-$,#c9
                ei
                jp sub_bltmv                    ; 0199 BLTMV

                defs #01f5-$,#c9
                ei
                jp sub_redclk                   ; 01F5 REDCLK
                defs #01f9-$,#c9
                ei
                jp sub_wrtclk                   ; 01F9 WRTCLK

                defs #0200-$,#ff

; ---------------------------------------------------------------------------
; VDP register write that keeps the R0-R7 and R8-R23 shadow work area in sync.
; Input: B = value, C = register number.
sub_wrtvdp:
                push af
                push hl
                ld a,c
                cp 8
                jr nc,sub_wrtvdp_ext
                add a,R0SAV&255
                ld l,a
                ld h,#f3
                jr sub_wrtvdp_store
sub_wrtvdp_ext:
                sub 8
                add a,RG8SAV&255
                ld l,a
                ld h,#ff
sub_wrtvdp_store:
                ld (hl),b
                di
                ld a,b
                out (VDP_CONTROL),a
                ld a,c
                or #80
                out (VDP_CONTROL),a
                pop hl
                pop af
                ei                             ; effective after RET
                ret

; ---------------------------------------------------------------------------
; Read a VDP status register selected by A (0-7) into A. Status 0 is restored
; afterwards so the caller keeps the default status register. Status registers
; are read from the status port (0x99).
sub_vdpsta:
                push hl
                di
                ld l,a
                out (VDP_CONTROL),a             ; select status register
                ld a,#8f
                out (VDP_CONTROL),a             ; R#15 = status select
                in a,(VDP_CONTROL)              ; read status
                ld h,a
                xor a
                out (VDP_CONTROL),a             ; restore status 0
                ld a,#8f
                out (VDP_CONTROL),a
                ld a,h
                pop hl
                ei                             ; effective after RET
                ret

; ---------------------------------------------------------------------------
; Set the V9938 CPU-access write pointer from the logical address in HL.
; R14 holds physical A16-A14; sub_setaddr16 combines HL with ACPAGE according
; to the current bitmap page size so all 128 KiB are reachable.
sub_setwrt16:
                push af
                call sub_setaddr16
                ld a,h
                and #3f
                or #40
                out (VDP_CONTROL),a
                pop af
                ei                             ; effective after RET
                ret

; Set the V9938 CPU-access read pointer from the logical address in HL.
sub_setrd16:
                push af
                call sub_setaddr16
                ld a,h
                and #3f
                out (VDP_CONTROL),a
                pop af
                ei                             ; effective after RET
                ret

; Translate logical HL plus the active bitmap page into R14 A16-A14, then
; emit R14 and the low VRAM-address byte as one interrupt-atomic sequence.
;
; With ACPAGE=0, retain the existing 16-bit mapping. For Screen 5/6 ACPAGE
; selects one of four 32 KiB pages; its low bit toggles A15 and its high bit
; supplies A16. For Screen 7 and later it selects one of two 64 KiB pages and
; supplies A16. In the legacy modes a nonzero ACPAGE falls back to the 14-bit
; MSX1 window, matching the established MSX2 BIOS behavior.
sub_setaddr16:
                push hl
                ld a,h
                rlca
                rlca
                and #03                         ; logical A15,A14
                ld h,a
                ld a,(ACPAGE)
                or a
                jr z,sub_setaddr16_logical
                ld a,(SCRMOD)
                cp 5
                jr c,sub_setaddr16_legacy
                cp 7
                ld a,(ACPAGE)
                jr c,sub_setaddr16_32k
                and #01
                add a,a
                add a,a                         ; page bit 0 -> physical A16
                or h
                jr sub_setaddr16_program
sub_setaddr16_32k:
                and #03
                add a,a                         ; page bits -> A16,A15
                xor h                           ; documented odd-page wrap
                jr sub_setaddr16_program
sub_setaddr16_logical:
                ld a,h
                jr sub_setaddr16_program
sub_setaddr16_legacy:
                xor a                           ; force the 14-bit window
sub_setaddr16_program:
                di
                out (VDP_CONTROL),a             ; R14: physical A16-A14
                ld a,#8e
                out (VDP_CONTROL),a             ; select register 14
                pop hl
                ld a,l
                out (VDP_CONTROL),a             ; physical A7-A0
                ret

; 0109h WRTVRM: write A to the 16-bit VRAM address HL.
sub_wrvrm:
                push af
                call sub_setwrt16
                pop af
                out (VDP_DATA),a
                ret

; 010Dh RDVRM: read the 16-bit VRAM address HL into A.
sub_rdvrm:
                call sub_setrd16
                in a,(VDP_DATA)
                ret

; ---------------------------------------------------------------------------
; $0141 INIPLT: initialize the V9938 palette to the default 0GRB values and
; copy them into the VRAM palette store.
sub_iniplt:
                push af
                push bc
                push hl
                call sub_palette_vram
                call sub_setwrt16
                xor a
                ld b,a
                ld c,16
                call sub_wrtvdp                 ; palette index 0
                ld hl,sub_default_palette
                ld b,16
sub_iniplt_entry:
                ld a,(hl)
                out (VDP_PALT),a                ; low byte (R in 6-4, B in 2-0)
                out (VDP_DATA),a                ; VRAM store low
                inc hl
                ld a,(hl)
                out (VDP_PALT),a                ; high byte (G in 2-0)
                out (VDP_DATA),a                ; VRAM store high
                inc hl
                djnz sub_iniplt_entry
                pop hl
                pop bc
                pop af
                ret

; ---------------------------------------------------------------------------
; The palette copy lives in VRAM at a screen-dependent base so RSTPLT and
; GETPLT can read it back without reading the write-only palette latch.
sub_palette_vram:
                ld a,(SCRMOD)
                ld hl,sub_palette_table
                add a,a
                add a,l
                ld l,a
                ld a,0
                adc a,h
                ld h,a
                ld a,(hl)
                inc hl
                ld h,(hl)
                ld l,a
                ret

sub_palette_table:
                dw #0400, #0f00, #2020, #1b80, #2020, #1b80
                dw #7680, #7680, #fa80, #fa80, #fa80, #fa80
                dw #fa80, #fa80, #fa80, #fa80

; $0145 RSTPLT: restore the palette from the VRAM copy.
sub_rstplt:
                push af
                push bc
                push hl
                call sub_palette_vram
                call sub_setrd16
                xor a
                ld b,a
                ld c,16
                call sub_wrtvdp                 ; palette index 0
                ld b,32
sub_rstplt_loop:
                in a,(VDP_DATA)                ; low byte
                out (VDP_PALT),a
                in a,(VDP_DATA)                ; high byte
                out (VDP_PALT),a
                djnz sub_rstplt_loop
                pop hl
                pop bc
                pop af
                ret

; $0149 GETPLT: return colorcode A as B = RRRRBBBB and C = xxxxGGGG from the
; VRAM palette store.
sub_getplt:
                push hl
                push af
                call sub_palette_vram
                pop af
                add a,a
                ld c,a
                ld b,0
                add hl,bc
                call sub_setrd16
                in a,(VDP_DATA)
                ld b,a
                in a,(VDP_DATA)
                ld c,a
                pop hl
                ret

; $014D SETPLT: set palette index D to RRRRBBBB in A and xxxxGGGG in E, and
; keep the VRAM palette store in sync.
sub_setplt:
                push af
                push bc
                push hl
                push de
                call sub_palette_vram
                ld a,d
                add a,a
                ld c,a
                ld b,0
                add hl,bc
                call sub_setwrt16
                pop de
                pop hl
                ld b,d
                ld c,16
                call sub_wrtvdp                 ; palette index
                pop bc
                pop af
                out (VDP_PALT),a                ; low byte (R in 6-4, B in 2-0)
                out (VDP_DATA),a                ; VRAM store low
                ld a,e
                out (VDP_PALT),a                ; high byte (G in 2-0)
                out (VDP_DATA),a                ; VRAM store high
                ret

; ---------------------------------------------------------------------------
; VDP command engine helpers. The command registers (R32-R46) hold the source,
; destination, size, colour, argument, and command code.
;
; Write a 16-bit coordinate pair from B (low) and A (high) into register C and
; C+1.
sub_cmd_coord:
                push af
                ld a,b
                call sub_cmd_reg
                pop af
                ld b,a
                call sub_cmd_reg
                ret

; Wait for the current VDP command to finish (status 2 CE bit clears).
sub_cmd_wait:
                ld a,2
                call sub_vdpsta
                bit 0,a
                jr nz,sub_cmd_wait
                ret

; ---------------------------------------------------------------------------
; $0191 BLTVV: copy a rectangle from VRAM to VRAM (LMMM). The command engine
; runs entirely in the VDP; the CPU waits for completion.
sub_bltvv:
                call sub_cmd_prepare
                ret c
                ; LMMM command, then wait for the engine to finish.
                ld b,#90
                call sub_cmd_launch
                jp sub_cmd_wait

; ---------------------------------------------------------------------------
; $0195 BLTVM: copy a rectangle from RAM to VRAM (LMMC). The CPU writes each
; pixel colour to R44 (which the engine consumes) as it advances. The RAM
; screen data at SX is: NX (16-bit), NY (16-bit), then the pixels packed
; according to the current screen mode.
;
; Packing: D = pixels per byte, E = number of 2-bit groups per pixel (so E*2
; bits per pixel). SC8: D=1, E=4. SC6: D=4, E=1. SC5/SC7: D=2, E=2.
sub_bltvm:
                ; SX points at the RAM screen data: NX (16-bit), NY (16-bit),
                ; then the pixel bytes.
                ld hl,(SX)
                ld a,(hl)
                ld (NX),a
                inc hl
                ld a,(hl)
                ld (NX+1),a
                inc hl
                ld a,(hl)
                ld (NY),a
                inc hl
                ld a,(hl)
                ld (NY+1),a
                inc hl
                ld (CDUMMY),hl                 ; first pixel byte address
                call sub_cmd_prepare
                ret c
                call sub_packing                ; D = pixels/byte, E = groups
                ; Set R44 to the first pixel colour so the engine consumes it
                ; when the LMMC command starts. C stays rotated afterwards so
                ; the feed loop extracts the remaining pixels.
                ld hl,(CDUMMY)
                ld c,(hl)
                inc hl
                ld (CDUMMY),hl
                xor a
                ld b,e
sub_bltvm_first:
                rl c
                rla
                rl c
                rla
                djnz sub_bltvm_first
                push bc
                call sub_set_cmd_colour
                pop bc
                ; Save the remaining pixel bits while the launch clobbers C.
                ld a,c
                ld (cmd_temp),a
                ; LMMC command, then feed the remaining pixels through R44.
                ld b,#b0
                call sub_cmd_launch
                ; Restore the pixel byte and the pixels remaining in the
                ; current byte (D-1).
                ld a,(cmd_temp)
                ld c,a
                ld a,d
                dec a
                ld b,a
sub_bltvm_feed:
                ld a,2
                call sub_vdpsta
                bit 0,a
                jr z,sub_bltvm_done            ; command finished
                bit 7,a
                jr z,sub_bltvm_feed            ; wait for transfer ready
                ld a,b
                and a
                jr z,sub_bltvm_next            ; byte exhausted
                ; Extract one pixel (E*2 bits) from the top of C into A. C
                ; stays rotated so the next pixel comes from the low bits.
                push bc
                xor a
                ld b,e
sub_bltvm_shift:
                rl c
                rla
                rl c
                rla
                djnz sub_bltvm_shift
                call sub_set_cmd_colour
                ld a,c
                pop bc
                ld c,a
                djnz sub_bltvm_feed
sub_bltvm_next:
                ld hl,(CDUMMY)
                ld a,(hl)
                ld c,a
                inc hl
                ld (CDUMMY),hl
                ld b,d
                jr sub_bltvm_feed
sub_bltvm_done:
                ret

; Write A as the command colour in R44 (direct register write).
sub_set_cmd_colour:
                push bc
                ld b,a
                ld c,44
                call sub_cmd_reg
                pop bc
                ret

; ---------------------------------------------------------------------------
; $0199 BLTMV: copy a rectangle from VRAM to RAM (LMCM). The CPU reads each
; pixel colour from status 7 as the engine produces it and packs the pixels
; into the destination RAM screen data.
sub_bltmv:
                ; DX points at the destination RAM screen data.
                ld hl,(DX)
                ld a,(NX)
                ld (hl),a
                inc hl
                ld a,(NX+1)
                ld (hl),a
                inc hl
                ld a,(NY)
                ld (hl),a
                inc hl
                ld a,(NY+1)
                ld (hl),a
                inc hl
                ld (CDUMMY),hl
                call sub_cmd_prepare
                ret c
                call sub_packing
                ; LMCM command.
                ld b,#a0
                 call sub_cmd_launch
                ; B = pixels read in the current byte, C = byte assembled.
                ld b,d
                xor a
                ld c,a
sub_bltmv_feed:
                ld a,2
                call sub_vdpsta
                bit 0,a
                jr z,sub_bltmv_done            ; command finished
                bit 7,a
                jr z,sub_bltmv_feed            ; wait for transfer ready
                ; Read the pixel colour from status 7.
                ld a,7
                call sub_vdpsta
                ; Pack: rotate the accumulated byte E*2 bits left (E is the
                ; number of 2-bit groups, so E*2 = bits per pixel), OR the
                ; pixel. Save the packing registers; the pixel value stays in
                ; A across the rotation via the stack.
                push bc
                push af
                ld a,e
                add a,a
                ld b,a
sub_bltmv_shift:
                rlc c
                djnz sub_bltmv_shift
                pop af
                or c
                pop bc
                ld c,a
                ; Pixels left in this byte.
                djnz sub_bltmv_feed
                ; One full byte assembled; store it.
                ld hl,(CDUMMY)
                ld (hl),c
                inc hl
                ld (CDUMMY),hl
                xor a
                ld c,a
                ld b,d
                jr sub_bltmv_feed
sub_bltmv_done:
                ret

; Determine the current screen data packing. Returns D = pixels per byte and
; E = number of 2-bit groups per pixel (so E*2 bits per pixel).
sub_packing:
                push af
                ld a,(SCRMOD)
                cp 8
                ld d,1
                ld e,4
                jr z,sub_packing_done
                cp 6
                ld d,4
                ld e,1
                jr z,sub_packing_done
                ld d,2
                ld e,2
sub_packing_done:
                pop af
                ret

; ---------------------------------------------------------------------------
; Common command launch: fill R32-R43 from the work area, R45 = ARG, then
; issue the command in B. Returns carry on a clipped/invalid size.
sub_cmd_prepare:
                ld a,(NX)
                ld b,a
                ld a,(NX+1)
                or b
                jr z,sub_cmd_prepare_clip
                ld a,(NY)
                ld b,a
                ld a,(NY+1)
                or b
                jr z,sub_cmd_prepare_clip
                ; SX, SY, DX, DY, NX, NY as low/high pairs into R32-R43.
                ld c,32
                ld hl,SX
                ld d,6
sub_cmd_prepare_loop:
                ld a,(hl)
                inc hl
                ld b,a
                ld a,(hl)
                inc hl
                call sub_cmd_coord
                dec d
                jr nz,sub_cmd_prepare_loop
                ; R44 = colour (unused by these transfers), R45 = ARG.
                xor a
                ld b,a
                ld c,44
                call sub_cmd_reg
                ld b,a
                ld c,45
                call sub_cmd_reg
                or a
                ret
sub_cmd_prepare_clip:
                scf
                ret

sub_cmd_launch:
                ld c,46
                call sub_cmd_reg
                or a
                ret

; ---------------------------------------------------------------------------
; $01F5 REDCLK: read one RTC register. C = clock address (xxBBAAAA).
; Returns the register value in A.
sub_redclk:
                push bc
                ld a,c
                rrca
                rrca
                rrca
                rrca
                and 3
                ld b,a
                ; Select the block via the mode register (13).
                ld a,13
                out (RTC_ADDR),a
                in a,(RTC_DATA)
                and #fc
                or b
                out (RTC_DATA),a
                ; Select the register and read it.
                ld a,c
                and 15
                out (RTC_ADDR),a
                in a,(RTC_DATA)
                and 15
                pop bc
                ret

; ---------------------------------------------------------------------------
; $01F9 WRTCLK: write one RTC register. C = clock address (xxBBAAAA),
; A = value.
sub_wrtclk:
                push bc
                ld b,a
                ld a,c
                rrca
                rrca
                rrca
                rrca
                and 3
                ld d,a
                ; Select the block via the mode register (13).
                ld a,13
                out (RTC_ADDR),a
                in a,(RTC_DATA)
                and #fc
                or d
                out (RTC_DATA),a
                ; Select the register and write the low nibble.
                ld a,c
                and 15
                out (RTC_ADDR),a
                ld a,b
                and 15
                out (RTC_DATA),a
                pop bc
                ret

; ---------------------------------------------------------------------------
; $00D1 CHGMOD: set the VDP screen mode. Screens 5, 6, 7, and 8 are supported
; with table-base work-area publication and a full bitmap clear.
sub_chgmod:
                cp 5
                jr z,sub_screen5
                cp 6
                jr z,sub_screen6
                cp 7
                jr z,sub_screen7
                cp 8
                jr z,sub_screen8
                scf
                ret

sub_screen5:
                ld a,5
                ld (SCRMOD),a
                ld hl,sub_sc5_regs
                call sub_write_mode_regs
                ld hl,#0000
                ld (NAMBAS),hl
                ld hl,#7800
                ld (PATBAS),hl
                ld hl,#7600
                ld (ATRBAS),hl
                call sub_clear_bitmap
                jr sub_screen_done

sub_screen6:
                ld a,6
                ld (SCRMOD),a
                ld hl,sub_sc6_regs
                call sub_write_mode_regs
                ld hl,#0000
                ld (NAMBAS),hl
                ld hl,#7800
                ld (PATBAS),hl
                ld hl,#7600
                ld (ATRBAS),hl
                call sub_clear_bitmap
                jr sub_screen_done

sub_screen7:
                ld a,7
                ld (SCRMOD),a
                ld hl,sub_sc7_regs
                call sub_write_mode_regs
                ld hl,#0000
                ld (NAMBAS),hl
                ld hl,#f000
                ld (PATBAS),hl
                ld hl,#fa00
                ld (ATRBAS),hl
                call sub_clear_bitmap
                jr sub_screen_done

sub_screen8:
                ld a,8
                ld (SCRMOD),a
                ld hl,sub_sc8_regs
                call sub_write_mode_regs
                ld hl,#0000
                ld (NAMBAS),hl
                ld hl,#f000
                ld (PATBAS),hl
                ld hl,#fa00
                ld (ATRBAS),hl
                call sub_clear_bitmap

sub_screen_done:
                xor a
                ret

; Write the 12 mode registers R0-R11 from the table at HL.
sub_write_mode_regs:
                ld c,0
sub_write_mode_regs_loop:
                ld a,(hl)
                ld b,a
                push bc
                push hl
                call sub_wrtvdp
                pop hl
                pop bc
                inc hl
                inc c
                ld a,c
                cp 12
                jr nz,sub_write_mode_regs_loop
                ret

; ---------------------------------------------------------------------------
; Clear the active bitmap with the VDP HMMV command. The fill byte is BAKCLR
; packed for the mode. The command clears the whole 256x212 or 512x212 area;
; completion is polled via status 2 (CE bit).
sub_clear_bitmap:
                push af
                push bc
                push de
                push hl
                ; Pack BAKCLR into the mode's fill byte.
                ld a,(BAKCLR)
                ld c,a
                ld a,(SCRMOD)
                cp 6
                jr z,sub_clear_bitmap_6
                cp 8
                jr z,sub_clear_bitmap_8
                ; SCREEN 5/7: two 4-bit pixels per byte.
                ld a,c
                and #0f
                ld b,a
                rlca
                rlca
                rlca
                rlca
                or b
                jr sub_clear_bitmap_colour
sub_clear_bitmap_6:
                ; SCREEN 6: four 2-bit pixels per byte.
                ld a,c
                and #03
                ld b,a
                rlca
                rlca
                or b
                rlca
                rlca
                or b
                rlca
                rlca
                or b
                jr sub_clear_bitmap_colour
sub_clear_bitmap_8:
                ld a,c
sub_clear_bitmap_colour:
                push af
                ; Wait for any previous command to finish.
                ld a,2
                call sub_vdpsta
                bit 0,a
                jr nz,sub_clear_bitmap_colour
                pop af
                ; R44 = colour.
                ld b,a
                ld c,44
                call sub_cmd_reg
                ; Zero SX/SY/DX/DY (R32-R39).
                ld b,0
                ld c,32
                ld de,8
sub_clear_bitmap_zero:
                call sub_cmd_reg
                dec de
                ld a,d
                or e
                jr nz,sub_clear_bitmap_zero
                ; NX = mode width (R40/41).
                ld a,(SCRMOD)
                cp 5
                jr z,sub_clear_bitmap_nx256
                cp 8
                jr z,sub_clear_bitmap_nx256
                ld b,#02
                ld c,40
                call sub_cmd_reg
                ld b,0
                call sub_cmd_reg
                jr sub_clear_bitmap_ny
sub_clear_bitmap_nx256:
                ld b,#01
                ld c,40
                call sub_cmd_reg
                ld b,0
                call sub_cmd_reg
sub_clear_bitmap_ny:
                ; NY = 212 (R42/43).
                ld b,#d4
                ld c,42
                call sub_cmd_reg
                ld b,0
                call sub_cmd_reg
                ; ARG = 0 (R45), command = HMMV (R46).
                ld c,45
                call sub_cmd_reg
                ld b,#c0
                call sub_cmd_reg
sub_clear_bitmap_wait:
                ld a,2
                call sub_vdpsta
                bit 0,a
                jr z,sub_clear_bitmap_wait
sub_clear_bitmap_wait2:
                ld a,2
                call sub_vdpsta
                bit 0,a
                jr nz,sub_clear_bitmap_wait2
                pop hl
                pop de
                pop bc
                pop af
                ret

; Write B to VDP register C without touching the R0-R23 shadows (command
; registers R32-R46 have no standard shadow work area). C advances to the next
; register so low/high pairs can be written in sequence.
sub_cmd_reg:
                push af
                di
                ld a,b
                out (VDP_CONTROL),a
                ld a,c
                or #80
                out (VDP_CONTROL),a
                pop af
                inc c
                ei                             ; effective after RET
                ret

; ---------------------------------------------------------------------------
sub_sc5_regs:
                db #06,#20,#1f,#00,#00,#ef,#0f,#01,#08,#00,#00,#00
sub_sc6_regs:
                db #08,#00,#1f,#00,#00,#ef,#0f,#01,#08,#00,#00,#00
sub_sc7_regs:
                db #0a,#00,#1f,#00,#00,#f7,#1e,#01,#08,#00,#00,#01
sub_sc8_regs:
                db #0e,#00,#1f,#00,#00,#f7,#1e,#01,#08,#00,#00,#01

; Default 0GRB palette, two bytes per entry: low (R in 6-4, B in 2-0) then
; high (G in 2-0), little-endian of the documented 16-entry table.
sub_default_palette:
                db #00,#00, #00,#00, #11,#06, #33,#07
                db #17,#01, #27,#03, #51,#01, #27,#06
                db #71,#01, #73,#03, #61,#06, #64,#06
                db #11,#04, #65,#02, #55,#05, #77,#07

                assert $<=#4000
                defs #4000-$,#ff
