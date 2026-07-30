; SPDX-License-Identifier: BSD-3-Clause
;
; RainBIOS M1 MSX1 main-ROM skeleton.
;
; This source establishes the public ROM layout. Routines marked partial have
; straightforward hardware behavior but have not yet passed instruction-level
; and hardware compatibility tests.

VDP_DATA        equ #98
VDP_CONTROL     equ #99
PSG_ADDRESS     equ #a0
PSG_WRITE       equ #a1
PSG_READ        equ #a2
PPI_SLOT        equ #a8
PPI_KEYBOARD    equ #a9
PPI_CONTROL_C   equ #aa
PPI_CONTROL     equ #ab

R0SAV           equ #f3df
RG1SAV          equ #f3e0
STATFL          equ #f3e7
FORCLR          equ #f3e9
BAKCLR          equ #f3ea
BDRCLR          equ #f3eb
LINL40          equ #f3ae
LINL32          equ #f3af
LINLEN          equ #f3b0
CRTCNT          equ #f3b1
CSRY            equ #f3dc
CSRX            equ #f3dd
SCNCNT          equ #f3f6
REPCNT          equ #f3f7
PUTPNT          equ #f3f8
GETPNT          equ #f3fa
NAMBAS          equ #f922
CGPBAS          equ #f924
PATBAS          equ #f926
ATRBAS          equ #f928
OLDKEY          equ #fbda
NEWKEY          equ #fbe5
KEYBUF          equ #fbf0
KEYBUF_END      equ #fc18
JIFFY           equ #fc9e
SCRMOD          equ #fcaf
BOTTOM          equ #fc48
HIMEM           equ #fc4a
BIOSSLT         equ #fcc0
EXPTBL          equ #fcc1
SLTTBL          equ #fcc5
HOOKBASE        equ #fd9a

RAM_TEST2       equ #bfff
RAM_TEST3       equ #f380
PAGE0_SLOT_HELPER equ #f380
PAGE0_READ_HELPER equ #f383
PAGE0_WRITE_HELPER equ #f38b
CART_SCAN_SLOT  equ #f392
PAYLOAD_SLOT    equ #f393
PAYLOAD_ENTRY   equ #f394
PAYLOAD_RAM_END equ #f396
TAPE_PERIOD     equ #f398
TAPE_LEVEL      equ #f399
TAPE_SYNC       equ #f39a
H_PHYD          equ #ffa7
H_FORM          equ #ffac
H_ISFL          equ #fedf
H_OUTD          equ #fee4
PTRFIL          equ #f864
VOICEN          equ #fb38
VCBA            equ #fb41
STACK_TOP       equ #f380

                org #0000

; Reset entry and fixed metadata.
                di
                jp cold_boot
                dw boot_font
                db VDP_DATA
                db VDP_DATA

; MSX1 main BIOS ABI.
                jp unsupported_call             ; 0008 SYNCHR
                defs #000c-$,#ff
                jp rdslt                        ; 000C RDSLT
                defs #0010-$,#ff
                jp unsupported_call             ; 0010 CHRGTR
                defs #0014-$,#ff
                jp wrslt                        ; 0014 WRSLT
                defs #0018-$,#ff
                jp unsupported_call             ; 0018 OUTDO
                defs #001c-$,#ff
                jp calslt                       ; 001C CALSLT
                defs #0020-$,#ff
                jp dcompr                       ; 0020 DCOMPR
                defs #0024-$,#ff
                jp enaslt                       ; 0024 ENASLT
                defs #0028-$,#ff
                jp unsupported_call             ; 0028 GETYPR

; International character set, D-M-Y date order, 60 Hz, US keyboard/BASIC.
                db #21                          ; 002B IDBYT1
                db #11                          ; 002C IDBYT2
                db #00                          ; 002D MSX generation: MSX1
                db #00                          ; 002E reserved
                db #00                          ; 002F reserved

                jp callf                        ; 0030 CALLF
                defs #0038-$,#ff
                jp keyint                       ; 0038 KEYINT
                jp unsupported_call             ; 003B INITIO
                jp unsupported_call             ; 003E INIFNK
                jp disscr                       ; 0041 DISSCR
                jp enascr                       ; 0044 ENASCR
                jp wrtvdp                       ; 0047 WRTVDP
                jp rdvrm                        ; 004A RDVRM
                jp wrtvrm                       ; 004D WRTVRM
                jp setrd                        ; 0050 SETRD
                jp setwrt                       ; 0053 SETWRT
                jp filvrm                       ; 0056 FILVRM
                jp ldirmv                       ; 0059 LDIRMV
                jp ldirvm                       ; 005C LDIRVM
                jp chgmod                       ; 005F CHGMOD
                jp unsupported_call             ; 0062 CHGCLR
                defs #0066-$,#ff
                jp nmi_handler                  ; 0066 NMI
                jp unsupported_call             ; 0069 CLRSPR
                jp initxt                       ; 006C INITXT
                jp init32                       ; 006F INIT32
                jp initgrp                      ; 0072 INITGRP
                jp unsupported_call             ; 0075 INIMLT
                jp unsupported_call             ; 0078 SETTXT
                jp unsupported_call             ; 007B SETT32
                jp unsupported_call             ; 007E SETGRP
                jp unsupported_call             ; 0081 SETMLT
                jp unsupported_call             ; 0084 CALPAT
                jp unsupported_call             ; 0087 CALATR
                jp unsupported_call             ; 008A GSPSIZ
                jp unsupported_call             ; 008D GRPPRT
                jp unsupported_call             ; 0090 GICINI
                jp wrtpsg                       ; 0093 WRTPSG
                jp rdpsg                        ; 0096 RDPSG
                jp unsupported_call             ; 0099 STRTMS
                jp chsns                        ; 009C CHSNS
                jp chget                        ; 009F CHGET
                jp chput                        ; 00A2 CHPUT
                jp unsupported_call             ; 00A5 LPTOUT
                jp unsupported_call             ; 00A8 LPTSTT
                jp unsupported_call             ; 00AB CNVCHR
                jp unsupported_call             ; 00AE PINLIN
                jp unsupported_call             ; 00B1 INLIN
                jp unsupported_call             ; 00B4 QINLIN
                jp unsupported_call             ; 00B7 BREAKX
                jp unsupported_call             ; 00BA ISCNTC
                jp unsupported_call             ; 00BD CKCNTC
                jp unsupported_call             ; 00C0 BEEP
                jp cls                          ; 00C3 CLS
                jp posit                        ; 00C6 POSIT
                jp unsupported_call             ; 00C9 FNKSB
                jp unsupported_call             ; 00CC ERAFNK
                jp unsupported_call             ; 00CF DSPFNK
                jp unsupported_call             ; 00D2 TOTEXT
                jp unsupported_call             ; 00D5 GTSTCK
                jp unsupported_call             ; 00D8 GTTRIG
                jp unsupported_call             ; 00DB GTPAD
                jp unsupported_call             ; 00DE GTPDL
                jp tapion                       ; 00E1 TAPION
                jp tapin                        ; 00E4 TAPIN
                jp tapiof                       ; 00E7 TAPIOF
                jp tapoon                       ; 00EA TAPOON
                jp tapout                       ; 00ED TAPOUT
                jp tapoof                       ; 00F0 TAPOOF
                jp stmotr                       ; 00F3 STMOTR
                jp unsupported_call             ; 00F6 LFTQ
                jp unsupported_call             ; 00F9 PUTQ
                jp unsupported_call             ; 00FC RIGHTC
                jp unsupported_call             ; 00FF LEFTC
                jp unsupported_call             ; 0102 UPC
                jp unsupported_call             ; 0105 TUPC
                jp unsupported_call             ; 0108 DOWNC
                jp unsupported_call             ; 010B TDOWNC
                jp unsupported_call             ; 010E SCALXY
                jp unsupported_call             ; 0111 MAPXY
                jp unsupported_call             ; 0114 FETCHC
                jp unsupported_call             ; 0117 STOREC
                jp unsupported_call             ; 011A SETATR
                jp unsupported_call             ; 011D READC
                jp unsupported_call             ; 0120 SETC
                jp unsupported_call             ; 0123 NSETCX
                jp unsupported_call             ; 0126 GTASPC
                jp unsupported_call             ; 0129 PNTINI
                jp unsupported_call             ; 012C SCANR
                jp unsupported_call             ; 012F SCANL
                jp unsupported_call             ; 0132 CHGCAP
                jp unsupported_call             ; 0135 CHGSND
                jp rslreg                       ; 0138 RSLREG
                jp wslreg                       ; 013B WSLREG
                jp rdvdp                        ; 013E RDVDP
                jp snsmat                       ; 0141 SNSMAT
                jp disk_phyio                   ; 0144 PHYDIO
                jp disk_format                  ; 0147 FORMAT
                jp disk_isflio                  ; 014A ISFLIO
                jp disk_outdlp                  ; 014D OUTDLP
                jp disk_getvcp                  ; 0150 GETVCP
                jp disk_getvc2                  ; 0153 GETVC2
                jp kilbuf                       ; 0156 KILBUF
                jp unsupported_call             ; 0159 CALBAS
                defs #015f-$,#ff
                ret                             ; 015F MSX1 compatibility

; Keep implementation code away from the fixed ABI area.
                defs #0200-$,#ff

cold_boot:
                di

; Do not assume the main ROM is in primary slot 0. Preserve the page-0/page-1
; mapping selected by reset and scan every primary/secondary slot for writable
; RAM in both pages 2 and 3. This bootstrap is stackless. Expansion tests keep
; the reset page-0/page-1 secondary selections unchanged so an expanded main
; ROM remains visible throughout.
                ld a,#82
                out (PPI_CONTROL),a             ; PPI mode 0, keyboard input
                ld a,#09
                out (PPI_CONTROL),a             ; cassette motor off
                ld a,#0b
                out (PPI_CONTROL),a             ; cassette output high
                in a,(PPI_SLOT)
                ld d,a                          ; original primary-slot map
                ld e,0                          ; candidate primary RAM slot
bootstrap_primary_ram_slot:
                ld a,e
                add a,a
                add a,a
                add a,a
                add a,a                         ; candidate in page-2 bits
                ld b,a
                add a,a
                add a,a                         ; candidate in page-3 bits
                or b
                ld b,a
                ld a,d
                and #0f
                or b
                out (PPI_SLOT),a

; FFFFh reads as the complement of the last selector written only on an
; expanded primary slot. Derive the current low selector nibble from the first
; read, then use two upper-nibble patterns while preserving the page-0/page-1
; subslots that keep this code visible.
                ld a,(#ffff)
                ld c,a
                cpl
                and #0f
                ld b,a
                ld (#ffff),a
                ld a,(#ffff)
                cpl
                cp b
                jr nz,bootstrap_unexpanded_ram
                ld a,b
                or #50
                ld h,a
                ld (#ffff),a
                ld a,(#ffff)
                cpl
                cp h
                jr nz,bootstrap_unexpanded_ram

; C becomes the original non-inverted selector. Try each secondary slot in
; both RAM pages while retaining its page-0/page-1 selections.
                ld a,c
                cpl
                ld c,a
                ld b,0
bootstrap_secondary_ram_slot:
                ld a,b
                add a,a
                add a,a
                add a,a
                add a,a
                ld l,a
                add a,a
                add a,a
                or l
                ld h,a
                ld a,c
                and #0f
                or h
                ld (#ffff),a
                jr bootstrap_test_ram

bootstrap_unexpanded_ram:
                ld a,c
                ld (#ffff),a
                ld b,4                          ; unexpanded sentinel

; Require two complementary patterns to stick in each page, restoring every
; probe byte before selecting or rejecting the candidate.
bootstrap_test_ram:
                ld hl,RAM_TEST3
                ld a,(hl)
                ex af,af'
                ld (hl),#55
                ld a,(hl)
                cp #55
                jr nz,bootstrap_ram_test_fail
                ld (hl),#aa
                ld a,(hl)
                cp #aa
                jr nz,bootstrap_ram_test_fail
                ex af,af'
                ld (hl),a

                ld hl,RAM_TEST2
                ld a,(hl)
                ex af,af'
                ld (hl),#55
                ld a,(hl)
                cp #55
                jr nz,bootstrap_ram_test_fail
                ld (hl),#aa
                ld a,(hl)
                cp #aa
                jr nz,bootstrap_ram_test_fail
                ex af,af'
                ld (hl),a
                jr bootstrap_primary_ram_found

bootstrap_ram_test_fail:
                ex af,af'
                ld (hl),a
                ld a,b
                cp 4
                jr z,bootstrap_primary_ram_fail
                inc b
                ld a,b
                cp 4
                jr nz,bootstrap_secondary_ram_slot

bootstrap_primary_ram_fail:
; Restore the pre-probe selector (or ordinary FFFFh byte) before moving to the
; next primary candidate.
                ld a,c
                ld (#ffff),a
                inc e
                ld a,e
                cp 4
                jp nz,bootstrap_primary_ram_slot

; No contiguous page-2/page-3 RAM was found. Restore the reset mapping and
; fail closed.
                ld a,d
                out (PPI_SLOT),a
bootstrap_no_primary_ram:
                halt
                jr bootstrap_no_primary_ram

bootstrap_primary_ram_found:
; Initialize the published system work area without touching FFFFh, which is
; the secondary-slot register on expanded-slot machines.
                ld sp,STACK_TOP
                push de                         ; preserve reset map/RAM slot
                xor a
                ld hl,RAM_TEST3
                ld (hl),a
                ld de,RAM_TEST3+1
                ld bc,#0c7e                    ; clear F381h through FFFEh
                ldir

; Page-0 slot operations must finish from mapped RAM because the BIOS
; disappears immediately after the PPI write. Install original switch,
; read/restore, and write/restore helpers before recovering the saved reset
; mapping and selected RAM slot.
                ld hl,slot_helpers_image
                ld de,PAGE0_SLOT_HELPER
                ld bc,slot_helpers_image_end-slot_helpers_image
                ldir
                pop de

; Record the primary MAIN-ROM slot before probing expansion state. The
; RAMAD0-RAMAD3 bytes at F341h-F344h belong to the Disk-ROM communication
; area and are deliberately not claimed.
                ld a,d
                and #03
                ld (BIOSSLT),a
                call bootstrap_expanded_slots
                ld hl,#8000
                ld (BOTTOM),hl
                ld hl,STACK_TOP
                ld (HIMEM),hl

; Empty hooks begin with RET.
                ld hl,HOOKBASE
                ld de,5
                ld b,113
bootstrap_empty_hook:
                ld (hl),#c9
                add hl,de
                djnz bootstrap_empty_hook

                call init_disk_default_hooks

; Publish the eight write-only TMS9918 register values used by the boot UI.
; Firmware clients read these RAM shadows when changing individual bits.
                ld hl,cold_boot_vdp_registers
                ld de,R0SAV
                ld bc,8
                ldir
                ld a,40
                ld (LINL40),a
                ld a,32
                ld (LINL32),a
                ld (LINLEN),a
                ld a,24
                ld (CRTCNT),a
                ld a,1
                ld (CSRY),a
                ld (CSRX),a
                ld a,15
                ld (FORCLR),a
                ld a,1
                ld (BAKCLR),a
                ld (BDRCLR),a
                ld a,2
                ld (SCRMOD),a
                ld hl,#1800
                ld (NAMBAS),hl
                ld hl,#0000
                ld (CGPBAS),hl
                ld hl,#3800
                ld (PATBAS),hl
                ld hl,#1b00
                ld (ATRBAS),hl
                ld a,1
                ld (SCNCNT),a
                ld a,50
                ld (REPCNT),a
                ld hl,KEYBUF
                ld (PUTPNT),hl
                ld (GETPNT),hl
                ld hl,OLDKEY
                ld de,OLDKEY+1
                ld bc,21
                ld (hl),#ff
                ldir
                ld a,#ff
                ld (PAYLOAD_SLOT),a
                ld hl,0
                ld (PAYLOAD_ENTRY),hl
                ld (PAYLOAD_RAM_END),hl

                ld sp,STACK_TOP

; Initialize Graphics II with the display disabled.
                ld a,#02
                out (VDP_CONTROL),a
                ld a,#80
                out (VDP_CONTROL),a             ; R0: Graphics II
                ld a,#80
                out (VDP_CONTROL),a
                ld a,#81
                out (VDP_CONTROL),a             ; R1: 16K VRAM, display off
                ld a,#06
                out (VDP_CONTROL),a
                ld a,#82
                out (VDP_CONTROL),a             ; R2: name table at 1800h
                ld a,#ff
                out (VDP_CONTROL),a
                ld a,#83
                out (VDP_CONTROL),a             ; R3: color table at 2000h
                ld a,#03
                out (VDP_CONTROL),a
                ld a,#84
                out (VDP_CONTROL),a             ; R4: patterns at 0000h
                ld a,#36
                out (VDP_CONTROL),a
                ld a,#85
                out (VDP_CONTROL),a             ; R5: sprites at 1B00h
                ld a,#07
                out (VDP_CONTROL),a
                ld a,#86
                out (VDP_CONTROL),a             ; R6: sprite patterns at 3800h
                ld a,#01
                out (VDP_CONTROL),a
                ld a,#87
                out (VDP_CONTROL),a             ; R7: black backdrop

; Upload the 6K pattern table at 0000h.
                xor a
                out (VDP_CONTROL),a
                ld a,#40
                out (VDP_CONTROL),a
                ld hl,logo_pattern
                ld d,24
                ld c,VDP_DATA
cold_boot_pattern_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_pattern_block

; The VDP address is now 1800h; upload the 768-byte name table.
                ld hl,logo_name
                ld d,3
cold_boot_name_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_name_block

; The VDP address is now 1B00h. A terminator hides all sprites.
                ld a,#d0
                out (VDP_DATA),a

; Upload the 6K color table at 2000h.
                xor a
                out (VDP_CONTROL),a
                ld a,#60
                out (VDP_CONTROL),a
                ld hl,logo_color
                ld d,24
cold_boot_color_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_color_block

; Enable the display and VBlank interrupt source. The CPU stays under DI until
; cartridge discovery has a stable page-0 BIOS and page-3 stack.
                ld a,#e0
                out (VDP_CONTROL),a
                ld a,#81
                out (VDP_CONTROL),a

; Play a four-note startup motif on PSG channel A. The standard MSX mixer
; value keeps PSG port A as input and port B as output. Channel B/C volumes
; remain zero. The routine is deliberately inline and stackless.
                ld a,#08
                out (PSG_ADDRESS),a
                xor a
                out (PSG_WRITE),a
                ld a,#09
                out (PSG_ADDRESS),a
                xor a
                out (PSG_WRITE),a
                ld a,#0a
                out (PSG_ADDRESS),a
                xor a
                out (PSG_WRITE),a
                ld a,#07
                out (PSG_ADDRESS),a
                ld a,#b8
                out (PSG_WRITE),a
                ld hl,jingle_notes
                ld d,4
cold_boot_jingle_note:
                ld a,#00
                out (PSG_ADDRESS),a
                ld a,(hl)
                inc hl
                out (PSG_WRITE),a
                ld a,#01
                out (PSG_ADDRESS),a
                ld a,(hl)
                inc hl
                out (PSG_WRITE),a
                ld a,#08
                out (PSG_ADDRESS),a
                ld a,#0c
                out (PSG_WRITE),a
                ld bc,#3000
cold_boot_jingle_delay:
                dec bc
                ld a,b
                or c
                jr nz,cold_boot_jingle_delay
                ld a,#08
                out (PSG_ADDRESS),a
                xor a
                out (PSG_WRITE),a
                ld bc,#0400
cold_boot_jingle_gap:
                dec bc
                ld a,b
                or c
                jr nz,cold_boot_jingle_gap
                dec d
                jr nz,cold_boot_jingle_note

; Discover simple primary/secondary-slot cartridges after RAM, video, and sound are
; initialized. A public MSX cartridge header begins with "AB", followed by the
; little-endian INIT address. An INIT routine that returns lets scanning
; continue; a game may keep control instead. M1E scans 4000h and 8000h in each
; non-BIOS slot and can invoke INIT in page 1 or page 2.
                im 1
                call cold_boot_scan_cartridges
                ei

; Wait for the translated Space character through the standard input path.
cold_boot_wait:
                call chsns
                jr nz,cold_boot_wait_read
                ei
                halt
                jr cold_boot_wait
cold_boot_wait_read:
                call chget
                cp #20
                jr nz,cold_boot_wait

; Space opens a compact Screen 1 menu. The name table selected below reports
; whether a validated BASIC payload was discovered.
cold_boot_options:
                xor a
                out (VDP_CONTROL),a
                ld a,#80
                out (VDP_CONTROL),a             ; R0: Screen 1
                ld a,#80
                out (VDP_CONTROL),a
                ld a,#81
                out (VDP_CONTROL),a             ; display off
                ld a,#06
                out (VDP_CONTROL),a
                ld a,#82
                out (VDP_CONTROL),a             ; name table at 1800h
                ld a,#80
                out (VDP_CONTROL),a
                ld a,#83
                out (VDP_CONTROL),a             ; color table at 2000h
                xor a
                out (VDP_CONTROL),a
                ld a,#84
                out (VDP_CONTROL),a             ; patterns at 0000h
                ld a,#04
                out (VDP_CONTROL),a
                ld a,#87
                out (VDP_CONTROL),a             ; dark-blue backdrop

; Upload the 2K font, then the 768-byte name table.
                xor a
                out (VDP_CONTROL),a
                ld a,#40
                out (VDP_CONTROL),a
                ld hl,boot_font
                ld d,8
                ld c,VDP_DATA
cold_boot_font_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_font_block
                xor a
                out (VDP_CONTROL),a
                ld a,#58
                out (VDP_CONTROL),a
                ld a,(PAYLOAD_SLOT)
                cp #ff
                ld hl,options_name_ready
                jr nz,cold_boot_options_name_selected
                ld hl,options_name_missing
cold_boot_options_name_selected:
                ld d,3
cold_boot_options_name_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_options_name_block

; Upload the 32-byte Screen 1 color table and enable the display.
                xor a
                out (VDP_CONTROL),a
                ld a,#60
                out (VDP_CONTROL),a
                ld hl,options_color
                ld b,32
                otir
                ld a,#e0
                out (VDP_CONTROL),a
                ld a,#81
                out (VDP_CONTROL),a
                xor a
                ld (R0SAV),a
                ld a,#e0
                ld (RG1SAV),a
                ld a,1
                ld (SCRMOD),a
                ld a,(LINL32)
                ld (LINLEN),a
                call kilbuf
cold_boot_options_wait:
                call chget
                cp '1'
                jr nz,cold_boot_options_wait

; Enter a validated page-1 payload without a return address. Page 0 remains
; the BIOS, pages 2/3 remain the selected contiguous RAM, SP is restored to
; HIMEM, and all normal and index registers are zero. EI becomes effective
; after RET transfers to the descriptor entry.
cold_boot_launch_payload:
                ld a,(PAYLOAD_SLOT)
                cp #ff
                jr z,cold_boot_options_wait
                di
                ld h,#40
                call enaslt
                ld sp,STACK_TOP
                ld hl,(PAYLOAD_ENTRY)
                push hl
                xor a
                ld bc,0
                ld de,0
                ld hl,0
                ld ix,0
                ld iy,0
                ei
                ret

cold_boot_scan_cartridges:
                xor a
                ld (CART_SCAN_SLOT),a
cold_boot_scan_slot:
                ld a,(CART_SCAN_SLOT)
                cp 4
                ret z
                bit 7,a
                jr nz,cold_boot_scan_slot_ready

; Normalize an expanded primary candidate to its secondary-slot-zero ID.
                or #80
                call expanded_slot_check
                jr nz,cold_boot_scan_slot_expanded
                and #03
                jr cold_boot_scan_slot_ready
cold_boot_scan_slot_expanded:
                ld (CART_SCAN_SLOT),a
cold_boot_scan_slot_ready:
                ld b,a
                ld a,(BIOSSLT)
                cp b
                jr z,cold_boot_scan_next_slot
                ld hl,#4000
                call cold_boot_try_cartridge
                ld hl,#8000
                call cold_boot_try_cartridge
cold_boot_scan_next_slot:
                ld a,(CART_SCAN_SLOT)
                bit 7,a
                jr z,cold_boot_scan_next_primary
                ld b,a
                and #0c
                cp #0c
                jr z,cold_boot_scan_expanded_done
                ld a,b
                add a,4
                ld (CART_SCAN_SLOT),a
                jr cold_boot_scan_slot
cold_boot_scan_expanded_done:
                ld a,b
                and #03
cold_boot_scan_next_primary:
                inc a
                ld (CART_SCAN_SLOT),a
                jr cold_boot_scan_slot

; Input HL is a possible header address. RDSLT preserves HL and E. The low
; INIT byte is kept on the page-3 stack while the high byte is read because
; RDSLT is allowed to replace the other normal registers.
cold_boot_try_cartridge:
                ld a,(CART_SCAN_SLOT)
                call rdslt
                cp #41
                ret nz
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                cp #42
                ret nz
                inc hl
                ld a,h
                cp #40
                jr nz,cold_boot_read_cartridge_init
                call cold_boot_try_payload
                ret c                           ; valid or rejected RBP1
                ld hl,#4002
cold_boot_read_cartridge_init:
                ld a,(CART_SCAN_SLOT)
                call rdslt
                push af
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                ld d,a
                pop af
                ld e,a
                ld a,d
                or e
                ret z
                ld a,d
                and #c0
                cp #40
                jr z,cold_boot_call_cartridge
                cp #80
                ret nz
cold_boot_call_cartridge:
                push de
                pop ix
                ld a,(CART_SCAN_SLOT)
                ld b,a
                ld c,0
                push bc
                pop iy
                ei
                call calslt
                di
                ret

; Detect and validate a RainBIOS payload descriptor at 7FF0h. Carry is clear
; only when the ROM does not claim the RBP1 magic and should retain ordinary
; cartridge INIT behavior. Once the magic matches, invalid descriptors fail
; closed with carry set. Version 1 accepts a BASIC page-1 entry, known service
; bits, contiguous page-2/page-3 RAM, and an exclusive RAM limit in
; 8001h-F380h. The first valid payload wins.
cold_boot_try_payload:
                ld hl,#7ff0
                ld e,'R'
                call cold_boot_payload_expect
                jp nz,cold_boot_not_payload
                inc hl
                ld e,'B'
                call cold_boot_payload_expect
                jp nz,cold_boot_not_payload
                inc hl
                ld e,'P'
                call cold_boot_payload_expect
                jp nz,cold_boot_not_payload
                inc hl
                ld e,'1'
                call cold_boot_payload_expect
                jp nz,cold_boot_not_payload

                ld a,(PAYLOAD_SLOT)
                cp #ff
                jp nz,cold_boot_payload_claimed

; Require the additive checksum across all 16 descriptor bytes to be zero.
                ld hl,#7ff0
                ld e,0
cold_boot_payload_checksum:
                ld a,(CART_SCAN_SLOT)
                call rdslt
                add a,e
                ld e,a
                inc hl
                ld a,h
                cp #80
                jr nz,cold_boot_payload_checksum
                ld a,e
                or a
                jp nz,cold_boot_payload_claimed

                ld hl,#7ff4
                ld e,1
                call cold_boot_payload_expect    ; descriptor version
                jp nz,cold_boot_payload_claimed
                inc hl
                ld e,16
                call cold_boot_payload_expect    ; descriptor length
                jp nz,cold_boot_payload_claimed
                inc hl
                ld e,1
                call cold_boot_payload_expect    ; BASIC payload type
                jp nz,cold_boot_payload_claimed
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt                       ; required service bits
                and #e0
                jp nz,cold_boot_payload_claimed

; Record and validate a page-1 entry address.
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                ld (PAYLOAD_ENTRY),a
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                ld (PAYLOAD_ENTRY+1),a
                and #c0
                cp #40
                jp nz,cold_boot_payload_claimed

; Version 1 requires RAM at 8000h and two contiguous pages.
                inc hl
                ld e,0
                call cold_boot_payload_expect
                jp nz,cold_boot_payload_claimed
                inc hl
                ld e,#80
                call cold_boot_payload_expect
                jp nz,cold_boot_payload_claimed

; The exclusive RAM limit must be above 8000h and no higher than F380h.
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                ld (PAYLOAD_RAM_END),a
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                ld (PAYLOAD_RAM_END+1),a
                ld hl,(PAYLOAD_RAM_END)
                ld de,#8000
                or a
                sbc hl,de
                jp z,cold_boot_payload_claimed
                jp c,cold_boot_payload_claimed
                ld hl,#f380
                ld de,(PAYLOAD_RAM_END)
                or a
                sbc hl,de
                jp c,cold_boot_payload_claimed

                ld hl,#7ffe
                ld e,2
                call cold_boot_payload_expect
                jp nz,cold_boot_payload_claimed
                ld a,(CART_SCAN_SLOT)
                ld (PAYLOAD_SLOT),a
cold_boot_payload_claimed:
                scf
                ret
cold_boot_not_payload:
                or a
                ret

; Compare descriptor byte (HL) in the current scan slot with E. RDSLT
; preserves both inputs.
cold_boot_payload_expect:
                ld a,(CART_SCAN_SLOT)
                call rdslt
                cp e
                ret

; Ordinary unimplemented calls return carry set. This is a bring-up contract,
; not an assertion about compatible error behavior.
unsupported_call:
                scf
                ret

; MSX1 mass-storage callouts.
; These call into hook vectors when a disk ROM provides them; safe defaults are
; installed at cold boot so read-only behavior is still defined without
; additional mass-storage support.
disk_phyio:
                call H_PHYD
                ret

disk_format:
                call H_FORM
                ret

disk_isflio:
                xor a
                call H_ISFL
                ret

disk_outdlp:
                call H_OUTD
                ret

disk_getvcp:
                ld l,2
                call disk_getvc2
                ret

disk_getvc2:
                ld a,(VOICEN)
                push de
                ld d,0
                ld e,l
                ld hl,VCBA
                add hl,de
                ld e,37
disk_getvc2_loop:
                or a
                jr z,disk_getvc2_exit
                add hl,de
                dec a
                jr disk_getvc2_loop
disk_getvc2_exit:
                pop de
                scf
                ret

; Initialize disk-related hook vectors to safe defaults.
;
; H_PHYD, H_FORM and H_OUTD:
;   - scf / ret (report not supported)
; H_ISFL:
;   - xor a / ret (no active transfer context)
;
; A default is stored as two instruction bytes; this is sufficient because all
; current call sites use a direct CALL to this address.
init_disk_default_hooks:
                ld hl,H_PHYD
                ld (hl),#37
                inc hl
                ld (hl),#c9

                ld hl,H_FORM
                ld (hl),#37
                inc hl
                ld (hl),#c9

                ld hl,H_ISFL
                ld (hl),#af
                inc hl
                ld (hl),#c9

                ld hl,H_OUTD
                ld (hl),#37
                inc hl
                ld (hl),#c9
                ret

; Partial inline inter-slot call used by standard five-byte hooks:
;   RST 30h, slot byte, target word, RET.
; Parse the inline operands through the alternate BC/DE/HL set so the target
; receives the caller's normal BC/DE/HL values. IX/IY take the documented
; CALSLT target and slot inputs.
callf:
                exx
                pop hl
                ld a,(hl)
                inc hl
                ld e,(hl)
                inc hl
                ld d,(hl)
                inc hl
                push hl
                push de
                pop ix
                ld b,a
                ld c,0
                push bc
                pop iy
                exx
                jp calslt

; Partial MSX1 IM 1 handler. Preserve normal, index, and shadow registers,
; run the device and VBlank hooks, acknowledge VDP status zero, scan the
; keyboard, and advance the public JIFFY counter once per VBlank. CALLF hooks
; use EXX internally, so preserving the shadow bank is required even when the
; interrupted application never exchanges registers itself.
keyint:
                push af
                push bc
                push de
                push hl
                push ix
                push iy
                ex af,af'
                push af
                ex af,af'
                exx
                push bc
                push de
                push hl
                exx
                call HOOKBASE                    ; H.KEYI
                in a,(VDP_CONTROL)
                bit 7,a
                jr z,keyint_done
                push af
                call keyboard_scan
                call HOOKBASE+5                  ; H.TIMI
                pop af
                ld (STATFL),a
                ld hl,(JIFFY)
                inc hl
                ld (JIFFY),hl
keyint_done:
                exx
                pop hl
                pop de
                pop bc
                exx
                ex af,af'
                pop af
                ex af,af'
                pop iy
                pop ix
                pop hl
                pop de
                pop bc
                pop af
                ei
                reti

nmi_handler:
                retn

; Partial: compare HL with DE while preserving both operands.
dcompr:
                ld a,h
                sub d
                ret nz
                ld a,l
                sub e
                ret

; Partial MSX1 VDP primitives.
disscr:
                ld a,(RG1SAV)
                and #bf
                ld b,a
                ld c,#01
                jp wrtvdp

enascr:
                ld a,(RG1SAV)
                or #40
                ld b,a
                ld c,#01
                jp wrtvdp

wrtvdp:
                push af
                push hl
                ld a,c
                and #07
                add a,#df
                ld l,a
                ld h,#f3
                ld (hl),b
                di
                ld a,b
                out (VDP_CONTROL),a
                ld a,c
                or #80
                out (VDP_CONTROL),a
                ei
                pop hl
                pop af
                ret

; Minimal MSX1 mode dispatcher. Screen 3 remains explicitly unsupported.
chgmod:
                or a
                jp z,initxt
                cp 1
                jp z,init32
                cp 2
                jp z,initgrp
                jp unsupported_call

; Program all eight TMS9918 registers from HL. The public WRTVDP path updates
; the corresponding RAM shadows for every register.
write_vdp_register_block:
                ld c,0
                ld d,8
write_vdp_register_block_loop:
                ld b,(hl)
                call wrtvdp
                inc hl
                inc c
                dec d
                jr nz,write_vdp_register_block_loop
                ret

; SCREEN 0: 40x24 text, name table at 0000h and font at 0800h.
initxt:
                ld hl,text40_vdp_registers
                call write_vdp_register_block
                ld hl,#0000
                ld (NAMBAS),hl
                ld hl,#0800
                ld (CGPBAS),hl
                ld hl,#0000
                ld (PATBAS),hl
                ld (ATRBAS),hl
                ld hl,#0000
                ld bc,960
                ld a,#20
                call filvrm
                ld hl,boot_font
                ld de,#0800
                ld bc,#0800
                call ldirvm
                ld a,0
                ld (SCRMOD),a
                ld a,(LINL40)
                ld (LINLEN),a
                ld a,1
                ld (CSRY),a
                ld (CSRX),a
                ld b,#f0
                ld c,1
                jp wrtvdp

; SCREEN 1: 32x24 text/tiles. This first slice supplies the project font,
; clears the name and color tables, and hides sprites.
init32:
                ld hl,text32_vdp_registers
                call write_vdp_register_block
                ld hl,#1800
                ld (NAMBAS),hl
                ld hl,#0000
                ld (CGPBAS),hl
                ld hl,#3800
                ld (PATBAS),hl
                ld hl,#1b00
                ld (ATRBAS),hl
                ld hl,#1800
                ld bc,768
                ld a,#20
                call filvrm
                ld hl,boot_font
                ld de,#0000
                ld bc,#0800
                call ldirvm
                ld hl,#2000
                ld bc,32
                ld a,#f1
                call filvrm
                ld hl,#1b00
                ld a,#d0
                call wrtvrm
                ld a,1
                ld (SCRMOD),a
                ld a,(LINL32)
                ld (LINLEN),a
                ld a,1
                ld (CSRY),a
                ld (CSRX),a
                ld b,#e0
                ld c,1
                jp wrtvdp

; SCREEN 2: Graphics II with the standard three copies of pattern indices in
; the name table. Clear the bitmap and select white over black for every
; eight-pixel colour cell so callers begin with deterministic graphics VRAM.
initgrp:
                ld hl,graphics2_vdp_registers
                call write_vdp_register_block
                ld hl,#1800
                ld (NAMBAS),hl
                ld hl,#0000
                ld (CGPBAS),hl
                ld hl,#3800
                ld (PATBAS),hl
                ld hl,#1b00
                ld (ATRBAS),hl
                ld hl,#1800
                call setwrt
                di
                ld b,3
                xor a
initgrp_name_loop:
                out (VDP_DATA),a
                inc a
                jr nz,initgrp_name_loop
                djnz initgrp_name_loop
                ei
                ld hl,#0000
                ld bc,#1800
                xor a
                call filvrm
                ld hl,#2000
                ld bc,#1800
                ld a,#f1
                call filvrm
                ld hl,#1b00
                ld a,#d0
                call wrtvrm
                ld a,2
                ld (SCRMOD),a
                ld a,(LINL32)
                ld (LINLEN),a
                ld b,#e0
                ld c,1
                jp wrtvdp

; Minimal Screen 0/1 console output. Cursor coordinates are one-based, as
; published for POSIT and the CSRX/CSRY work bytes. CHPUT preserves every
; normal register and handles printable ASCII, CR, LF, line wrapping, and
; scrolling at the bottom of the 24-row text screen.
chput:
                push af
                push bc
                push de
                push hl
                push af
                call HOOKBASE+10                 ; H.CHPH
                pop af
                ld e,a
                ld a,e
                cp #0d
                jr z,chput_carriage_return
                cp #0a
                jr z,chput_line_feed
                cp #08
                jr z,chput_backspace
                cp #20
                jr c,chput_done
                ld a,(SCRMOD)
                cp 2
                jr z,chput_graphics_character
                push de
                call console_cursor_address
                pop de
                ld a,e
                call wrtvrm
                jr chput_advance_cursor
chput_graphics_character:
                call graphics_put_character
chput_advance_cursor:
                ld a,(CSRX)
                inc a
                ld b,a
                ld a,(LINLEN)
                inc a
                cp b
                ld a,b
                jr nz,chput_store_x
                ld a,1
                ld (CSRX),a
                jr chput_advance_line
chput_store_x:
                ld (CSRX),a
                jr chput_done
chput_carriage_return:
                ld a,1
                ld (CSRX),a
                jr chput_done
chput_backspace:
                ld a,(CSRX)
                cp 1
                jr z,chput_done
                dec a
                ld (CSRX),a
                jr chput_done
chput_line_feed:
chput_advance_line:
                ld a,(CSRY)
                inc a
                cp 25
                jr c,chput_store_y
                call console_scroll
                ld a,24
chput_store_y:
                ld (CSRY),a
chput_done:
                pop hl
                pop de
                pop bc
                pop af
                ret

; Convert the current one-based cursor position into a Screen 0/1 name-table
; VRAM address. Screen 0 begins at 0000h; Screen 1 begins at 1800h.
console_cursor_address:
                ld a,(CSRY)
                dec a
                ld b,a
                ld a,(LINLEN)
                ld e,a
                ld d,0
                ld hl,0
console_cursor_row_loop:
                ld a,b
                or a
                jr z,console_cursor_column
                add hl,de
                dec b
                jr console_cursor_row_loop
console_cursor_column:
                ld a,(CSRX)
                dec a
                ld e,a
                ld d,0
                add hl,de
                ld a,(SCRMOD)
                cp 1
                ret nz
                ld de,#1800
                add hl,de
                ret

; Render one character into its Graphics II pattern and colour cell. Screen 2
; uses a sequential name table, so row Y and column X map to pattern address
; (Y * 256) + (X * 8). E contains the printable character.
graphics_put_character:
                ld l,e
                ld h,0
                add hl,hl
                add hl,hl
                add hl,hl
                ld bc,boot_font
                add hl,bc                       ; HL = eight-byte glyph
                ld a,(CSRY)
                dec a
                ld d,a
                ld a,(CSRX)
                dec a
                add a,a
                add a,a
                add a,a
                ld e,a                          ; DE = pattern address
                push de
                ld bc,8
                call ldirvm
                pop hl
                ld de,#2000
                add hl,de                       ; matching colour cell
                ld a,(FORCLR)
                and #0f
                rlca
                rlca
                rlca
                rlca
                ld d,a
                ld a,(BAKCLR)
                and #0f
                or d
                ld bc,8
                jp filvrm

; Move text rows 2..24 to rows 1..23 and blank the last row. The direct
; bytewise VRAM copy works in both 40-column Screen 0 and 32-column Screen 1
; without reserving a large RAM buffer.
console_scroll:
                ld a,(SCRMOD)
                cp 2
                jr z,console_scroll_screen2
                cp 1
                jr z,console_scroll_screen1
                ld hl,#0028                    ; Screen 0 row 2
                ld de,#0000                    ; Screen 0 row 1
                ld bc,920                      ; 23 rows * 40 columns
                call console_scroll_copy
                ld hl,#0398                    ; Screen 0 row 24
                ld bc,40
                jr console_scroll_clear_text
console_scroll_screen1:
                ld hl,#1820                    ; Screen 1 row 2
                ld de,#1800                    ; Screen 1 row 1
                ld bc,736                      ; 23 rows * 32 columns
                call console_scroll_copy
                ld hl,#1ae0                    ; Screen 1 row 24
                ld bc,32
console_scroll_clear_text:
                ld a,#20
                jp filvrm
console_scroll_screen2:
                ld hl,#0100                    ; pattern rows 2..24
                ld de,#0000
                ld bc,#1700
                call console_scroll_copy
                ld hl,#2100                    ; colour rows 2..24
                ld de,#2000
                ld bc,#1700
                call console_scroll_copy
                ld hl,#1700                    ; blank pattern row 24
                ld bc,#0100
                xor a
                call filvrm
                ld hl,#3700                    ; reset its colour row
                ld bc,#0100
                ld a,(FORCLR)
                and #0f
                rlca
                rlca
                rlca
                rlca
                ld d,a
                ld a,(BAKCLR)
                and #0f
                or d
                jp filvrm
console_scroll_copy:
                call rdvrm
                ex de,hl
                call wrtvrm
                ex de,hl
                inc hl
                inc de
                dec bc
                ld a,b
                or c
                jr nz,console_scroll_copy
                ret

cls:
                push hl
                ld a,(SCRMOD)
                cp 1
                jr z,cls_screen1
                ld hl,#0000
                ld bc,960
                jr cls_fill
cls_screen1:
                ld hl,#1800
                ld bc,768
cls_fill:
                ld a,#20
                call filvrm
                ld a,1
                ld (CSRX),a
                ld (CSRY),a
                pop hl
                ret

posit:
                ld a,h
                ld (CSRX),a
                ld a,l
                ld (CSRY),a
                ret

; Partial international-keyboard input. KEYINT records newly pressed matrix
; positions in the standard 40-byte circular buffer. Lock states, function-key
; expansion, dead keys, key click, and auto-repeat remain later M3 work.
keyboard_scan:
                ld a,6
                call snsmat
                ld d,a                          ; current modifier row
                ld hl,OLDKEY
                ld ix,NEWKEY
                ld b,0
keyboard_scan_row:
                ld a,b
                call snsmat
                ld e,(hl)                       ; previous active-low row
                ld (hl),a
                ld (ix),a
                cpl
                and e                           ; one bits are new presses
                ld c,a
                ld a,b
                cp 6
                jr z,keyboard_scan_next
                ld a,c
                or a
                jr z,keyboard_scan_next
                push bc
                push de
                push hl
                push ix
                call keyboard_enqueue_edges
                pop ix
                pop hl
                pop de
                pop bc
keyboard_scan_next:
                inc hl
                inc ix
                inc b
                ld a,b
                cp 9
                jr nz,keyboard_scan_row
                ret

; B is the matrix row, C contains newly pressed bits, and D contains the
; active-low Shift/Ctrl row. Enqueue every translatable edge from low to high
; bit number.
keyboard_enqueue_edges:
                ld e,0
keyboard_enqueue_edge:
                srl c
                jr nc,keyboard_enqueue_next
                push bc
                push de
                call keyboard_translate
                or a
                call nz,keyboard_buffer_put
                pop de
                pop bc
keyboard_enqueue_next:
                inc e
                ld a,e
                cp 8
                jr nz,keyboard_enqueue_edge
                ret

; Translate rows 0-5 through original tables derived from the published
; international matrix. Rows 7 and 8 contain editing/control keys.
keyboard_translate:
                ld a,b
                cp 6
                jr c,keyboard_translate_printable
                cp 7
                jr z,keyboard_translate_row7
                cp 8
                jr z,keyboard_translate_row8
                xor a
                ret
keyboard_translate_printable:
                add a,a
                add a,a
                add a,a
                add a,e
                ld c,a
                ld b,0
                ld hl,keymap_unshifted
                bit 0,d
                jr nz,keyboard_translate_table
                ld hl,keymap_shifted
keyboard_translate_table:
                add hl,bc
                ld a,(hl)
                bit 1,d
                ret nz
                cp 'A'
                ret c
                cp 'Z'+1
                ret nc
                and #1f                         ; Ctrl+A through Ctrl+Z
                ret
keyboard_translate_row7:
                ld hl,keymap_row7
                jr keyboard_translate_special
keyboard_translate_row8:
                ld hl,keymap_row8
keyboard_translate_special:
                ld d,0
                add hl,de
                ld a,(hl)
                ret

; Add A to the circular buffer unless advancing PUTPNT would collide with
; GETPNT. This private interrupt helper may use all normal registers.
keyboard_buffer_put:
                push af
                ld hl,(PUTPNT)
                ld d,h
                ld e,l
                inc hl
                ld a,h
                cp KEYBUF_END/256
                jr nz,keyboard_buffer_put_compare
                ld a,l
                cp KEYBUF_END&255
                jr nz,keyboard_buffer_put_compare
                ld hl,KEYBUF
keyboard_buffer_put_compare:
                push hl
                ld bc,(GETPNT)
                or a
                sbc hl,bc
                pop hl
                jr z,keyboard_buffer_put_full
                pop af
                ld (de),a
                ld (PUTPNT),hl
                ret
keyboard_buffer_put_full:
                pop af
                ret

; Return Z when the keyboard buffer is empty and NZ when input is ready.
; Only AF is changed, matching the public entry contract.
chsns:
                push hl
                ld hl,(GETPNT)
                ld a,(PUTPNT)
                cp l
                jr nz,chsns_done
                ld a,(PUTPNT+1)
                cp h
chsns_done:
                pop hl
                ret

; Wait for and remove one buffered character. All registers other than AF are
; preserved. Interrupts are enabled while waiting so KEYINT can fill the
; buffer.
chget:
                push bc
                push de
                push hl
chget_wait:
                call chsns
                jr nz,chget_ready
                ei
                halt
                jr chget_wait
chget_ready:
                di
                ld hl,(GETPNT)
                ld a,(hl)
                inc hl
                ld d,a
                ld a,h
                cp KEYBUF_END/256
                jr nz,chget_store_pointer
                ld a,l
                cp KEYBUF_END&255
                jr nz,chget_store_pointer
                ld hl,KEYBUF
chget_store_pointer:
                ld (GETPNT),hl
                ld a,d
                ei
                pop hl
                pop de
                pop bc
                ret

; Empty the standard key buffer. The public contract permits HL to change.
kilbuf:
                di
                ld hl,KEYBUF
                ld (PUTPNT),hl
                ld (GETPNT),hl
                ei
                ret

setrd:
                di
                ld a,l
                out (VDP_CONTROL),a
                ld a,h
                and #3f
                out (VDP_CONTROL),a
                ei
                ret

setwrt:
                di
                ld a,l
                out (VDP_CONTROL),a
                ld a,h
                and #3f
                or #40
                out (VDP_CONTROL),a
                ei
                ret

rdvrm:
                call setrd
                in a,(VDP_DATA)
                ret

wrtvrm:
                push af
                call setwrt
                pop af
                out (VDP_DATA),a
                ret

filvrm:
                push af
                call setwrt
                pop af
filvrm_loop:
                out (VDP_DATA),a
                dec bc
                push af
                ld a,b
                or c
                jr z,filvrm_done
                pop af
                jr filvrm_loop
filvrm_done:
                pop af
                ret

ldirmv:
                call setrd
ldirmv_loop:
                in a,(VDP_DATA)
                ld (de),a
                inc de
                dec bc
                ld a,b
                or c
                jr nz,ldirmv_loop
                ret

ldirvm:
                ex de,hl
                call setwrt
                ex de,hl
ldirvm_loop:
                ld a,(hl)
                out (VDP_DATA),a
                inc hl
                dec bc
                ld a,b
                or c
                jr nz,ldirvm_loop
                ret

; Partial PSG primitives.
wrtpsg:
                out (PSG_ADDRESS),a
                ld a,e
                out (PSG_WRITE),a
                ret

rdpsg:
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                ret

; MSX cassette input. TAPION starts the motor, waits through the initial
; silence, and measures the leader's transition period. TAPIN decodes the
; asynchronous start bit, eight LSB-first data bits, and two stop bits. The
; measured threshold tolerates both standard baud rates and moderate tape
; speed variation. Interrupts remain disabled until TAPIOF, as required by
; the published cassette-call contract.
tapion:
                di
                ld a,1
                call stmotr
                ld a,14
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                and #80
                ld e,a
                ld d,12
                call tape_wait_transition_long
                jr c,tape_input_fail
                ld c,#ff
                ld h,64
tapion_measure:
                call tape_measure_transition
                jr c,tape_input_fail
                ld a,b
                cp c
                jr nc,tapion_measure_next
                ld c,a
tapion_measure_next:
                dec h
                jr nz,tapion_measure
                ld a,c
                or a
                jr z,tape_input_fail
                ld (TAPE_PERIOD),a
                ld a,e
                ld (TAPE_LEVEL),a
                xor a
                ld (TAPE_SYNC),a
                or a
                ret

tape_input_fail:
                xor a
                ld (TAPE_SYNC),a
                call stmotr
                ei
                scf
                ret

tapin:
                ld a,(TAPE_LEVEL)
                ld e,a
                ld a,(TAPE_SYNC)
                or a
                jr z,tapin_find_start
; Consecutive TAPIN calls are already aligned to the next start-bit boundary.
; Consume its two transitions directly. Reclassifying the shortened first
; interval after caller overhead would otherwise lose byte synchronization.
                call tape_measure_transition
                jr c,tape_input_fail
                call tape_measure_transition
                jr c,tape_input_fail
                jr tapin_data_boundary
tapin_find_start:
                call tape_measure_transition
                jr c,tape_input_fail
                call tape_interval_is_long
                jr c,tapin_start_middle
                jr tapin_find_start
tapin_start_middle:
                call tape_measure_transition    ; middle to next bit boundary
                jr c,tape_input_fail
                call tape_interval_is_long
                jr nc,tapin_find_start
tapin_data_boundary:
                ld h,0
                ld l,1
                ld d,8
tapin_data_bit:
                push de
                call tape_read_bit
                pop bc
                jr c,tape_input_fail
                ld d,b
                or a
                jr z,tapin_data_next
                ld a,h
                or l
                ld h,a
tapin_data_next:
                sla l
                dec d
                jr nz,tapin_data_bit
                call tape_read_bit
                jr c,tape_input_fail
                or a
                jr z,tape_input_fail
                call tape_read_bit
                jr c,tape_input_fail
                or a
                jr z,tape_input_fail
                ld a,e
                ld (TAPE_LEVEL),a
                ld a,1
                ld (TAPE_SYNC),a
                ld a,h
                or a
                ret

tapiof:
                xor a
                ld (TAPE_SYNC),a
                xor a
                call stmotr
                ei
                ret

; Wait for the first transition with a multi-second timeout. E contains the
; current comparator state and receives the new state.
tape_wait_transition_long:
                ld bc,0
tape_wait_transition_loop:
                in a,(PSG_READ)
                and #80
                cp e
                jr nz,tape_transition_found
                dec bc
                ld a,b
                or c
                jr nz,tape_wait_transition_loop
                dec d
                jr nz,tape_wait_transition_long
                scf
                ret
tape_transition_found:
                ld e,a
                or a
                ret

; Measure one comparator transition in B polling iterations.
tape_measure_transition:
                ld b,0
tape_measure_loop:
                inc b
                jr z,tape_measure_timeout
                in a,(PSG_READ)
                and #80
                cp e
                jr z,tape_measure_loop
                ld e,a
                or a
                ret
tape_measure_timeout:
                scf
                ret

; Carry is set when B is at least twice the shortest interval sampled from
; the leader. A real zero/start bit supplies two such intervals in a row;
; TAPIN checks that pair to reject isolated timing jitter in the leader.
tape_interval_is_long:
                ld a,(TAPE_PERIOD)
                add a,a
                ld c,a
                ld a,b
                cp c
                ccf
                ret

; Read one FSK bit while maintaining E as the current comparator level.
; A returns zero or one. The routine consumes through the next bit boundary.
tape_read_bit:
                push hl
                call tape_measure_transition
                jr c,tape_read_bit_fail
                call tape_interval_is_long
                jr c,tape_read_zero
                ld c,1
                ld d,3
                jr tape_read_consume
tape_read_zero:
                ld c,0
                ld d,1
tape_read_consume:
                call tape_measure_transition
                jr c,tape_read_bit_fail
                dec d
                jr nz,tape_read_consume
                ld a,c
                pop hl
                or a
                ret
tape_read_bit_fail:
                pop hl
                scf
                ret

; MSX cassette output. The first milestone emits conservative 1200-baud FSK:
; a zero is one 1200 Hz cycle and a one is two 2400 Hz cycles. TAPOON writes
; an approximately two-second long leader or half-second short leader.
tapoon:
                ld c,a
                di
                ld a,1
                call stmotr
                ld a,#0a
                out (PPI_CONTROL),a             ; known low starting phase
                ld hl,600
                ld a,c
                or a
                jr z,tapoon_header
                ld hl,2400
tapoon_header:
                ld a,1
                call tape_write_bit
                dec hl
                ld a,h
                or l
                jr nz,tapoon_header
                or a
                ret

tapout:
                ld c,a
                xor a
                call tape_write_bit             ; start bit
                ld d,8
tapout_data:
                rr c
                ld a,0
                adc a,0
                call tape_write_bit
                dec d
                jr nz,tapout_data
                ld a,1
                call tape_write_bit
                ld a,1
                call tape_write_bit
                or a
                ret

tapoof:
                ld a,#0b
                out (PPI_CONTROL),a             ; idle high
                xor a
                call stmotr
                ei
                ret

tape_write_bit:
                or a
                jr z,tape_write_zero
                ld b,2
tape_write_one_cycle:
                ld a,#0b
                out (PPI_CONTROL),a
                ld a,44
                call tape_delay
                ld a,#0a
                out (PPI_CONTROL),a
                ld a,44
                call tape_delay
                djnz tape_write_one_cycle
                ret
tape_write_zero:
                ld a,#0b
                out (PPI_CONTROL),a
                ld a,90
                call tape_delay
                ld a,#0a
                out (PPI_CONTROL),a
                ld a,90
tape_delay:
                dec a
                jr nz,tape_delay
                ret

; A=0 stops, A=1 starts, and A=FFh toggles the active-low motor relay.
stmotr:
                or a
                jr z,stmotr_off
                inc a
                jr z,stmotr_toggle
                dec a
                cp 1
                ret nz
                ld a,#08
                out (PPI_CONTROL),a
                ret
stmotr_off:
                ld a,#09
                out (PPI_CONTROL),a
                ret
stmotr_toggle:
                in a,(PPI_CONTROL_C)
                xor #10
                out (PPI_CONTROL_C),a
                ret

; Detect the four primary-slot expanders after page-3 RAM and its stack have
; been established. An expanded slot returns the complement of the value
; written to FFFFh. Two patterns distinguish that register from writable RAM
; and fixed ROM; the original byte or selector is restored before the stack is
; used again. SLTTBL records the non-inverted selector written to each slot.
bootstrap_expanded_slots:
                ld c,0
bootstrap_expanded_slot:
                in a,(PPI_SLOT)
                ld d,a
                and #3f
                ld b,a
                ld a,c
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                or b
                out (PPI_SLOT),a

                ld a,(#ffff)
                ld e,a
                cpl
                and #0f
                ld b,a
                ld (#ffff),a
                ld a,(#ffff)
                cpl
                cp b
                jr nz,bootstrap_slot_not_expanded
                ld a,b
                or #50
                ld h,a
                ld (#ffff),a
                ld a,(#ffff)
                cpl
                cp h
                jr nz,bootstrap_slot_not_expanded

                ld a,e
                cpl
                ld (#ffff),a
                ld b,a
                ld a,d
                out (PPI_SLOT),a
                ld a,c
                or a
                jr z,bootstrap_expanded_slot0
                dec a
                jr z,bootstrap_expanded_slot1
                dec a
                jr z,bootstrap_expanded_slot2
                ld a,#80
                ld (EXPTBL+3),a
                ld a,b
                ld (SLTTBL+3),a
                jr bootstrap_expanded_next
bootstrap_expanded_slot2:
                ld a,#80
                ld (EXPTBL+2),a
                ld a,b
                ld (SLTTBL+2),a
                jr bootstrap_expanded_next
bootstrap_expanded_slot1:
                ld a,#80
                ld (EXPTBL+1),a
                ld a,b
                ld (SLTTBL+1),a
                jr bootstrap_expanded_next
bootstrap_expanded_slot0:
                ld a,#80
                ld (EXPTBL),a
                ld a,b
                ld (SLTTBL),a
                jr bootstrap_expanded_next

bootstrap_slot_not_expanded:
                ld a,e
                ld (#ffff),a
                ld a,d
                out (PPI_SLOT),a

bootstrap_expanded_next:
                inc c
                ld a,c
                cp 4
                jr nz,bootstrap_expanded_slot

; If the main ROM's primary slot is expanded, publish its page-0 secondary
; slot in the standard FxxxSSPP slot-ID form.
                ld a,(BIOSSLT)
                ld c,a
                or a
                jr z,bootstrap_main_expansion0
                dec a
                jr z,bootstrap_main_expansion1
                dec a
                jr z,bootstrap_main_expansion2
                ld a,(EXPTBL+3)
                jr bootstrap_main_expansion_check
bootstrap_main_expansion2:
                ld a,(EXPTBL+2)
                jr bootstrap_main_expansion_check
bootstrap_main_expansion1:
                ld a,(EXPTBL+1)
                jr bootstrap_main_expansion_check
bootstrap_main_expansion0:
                ld a,(EXPTBL)
bootstrap_main_expansion_check:
                bit 7,a
                ret z
                ld a,c
                or a
                jr z,bootstrap_main_selector0
                dec a
                jr z,bootstrap_main_selector1
                dec a
                jr z,bootstrap_main_selector2
                ld a,(SLTTBL+3)
                jr bootstrap_main_selector_ready
bootstrap_main_selector2:
                ld a,(SLTTBL+2)
                jr bootstrap_main_selector_ready
bootstrap_main_selector1:
                ld a,(SLTTBL+1)
                jr bootstrap_main_selector_ready
bootstrap_main_selector0:
                ld a,(SLTTBL)
bootstrap_main_selector_ready:
                and #03
                add a,a
                add a,a
                or c
                or #80
                ld (BIOSSLT),a
                ret

; Inter-slot memory calls. Page-0 accesses finish from mapped RAM because the
; BIOS disappears immediately after the PPI write. Page-3 expanded accesses
; restore both selectors before using the stack again.
rdslt:
                di
                bit 7,a
                jr nz,rdslt_expanded
                and #03
                ld c,a
                call primary_slot_map
                bit 7,h
                jr nz,rdslt_direct
                bit 6,h
                jr nz,rdslt_direct
                call PAGE0_READ_HELPER
                ret
rdslt_direct:
                out (PPI_SLOT),a
                ld b,(hl)
                ld a,d
                out (PPI_SLOT),a
                ld a,b
                ret

rdslt_expanded:
                call expanded_slot_check
                jp z,unsupported_call
                ld a,h
                and #c0
                cp #c0
                jr z,rdslt_expanded_page3

; Preserve the public E input while the selected secondary slot is installed.
; The temporary selector leaves page 3 unchanged for page-0 through page-2
; accesses, so the normal stack remains available.
                push de
                call expanded_temporary_select
                push bc
                call primary_slot_map
                bit 7,h
                jr nz,rdslt_expanded_direct
                bit 6,h
                jr nz,rdslt_expanded_direct
                call PAGE0_READ_HELPER
                jr rdslt_expanded_restore
rdslt_expanded_direct:
                out (PPI_SLOT),a
                ld b,(hl)
                ld a,d
                out (PPI_SLOT),a
                ld a,b
rdslt_expanded_restore:
                ld e,a
                pop bc
                ld a,b
                call expanded_store_selector
                call expanded_write_selector
                ld a,e
                pop de
                ret

; Selecting a different secondary slot in page 3 can hide the stack even when
; its primary slot was already selected. Keep every restoration value in
; registers until both the secondary selector and PPI map are back in place.
rdslt_expanded_page3:
                push de
                call expanded_load_selector
                ld e,a
                ld a,c
                and #0c
                add a,a
                add a,a
                add a,a
                add a,a
                ld b,a
                ld a,e
                and #3f
                or b
                ld b,a
                ld a,b
                call expanded_store_selector
                ld a,c
                and #03
                ld c,a
                in a,(PPI_SLOT)
                ld d,a
                ld a,c
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                ld c,a
                ld a,d
                and #3f
                or c
                out (PPI_SLOT),a
                ld a,b
                ld (#ffff),a
                ld b,(hl)
                ld a,e
                ld (#ffff),a
                ld a,d
                out (PPI_SLOT),a
                ld a,c
                rlca
                rlca
                and #03
                ld c,a
                ld a,e
                call expanded_store_selector
                ld a,b
                pop de
                ret

wrslt:
                di
                bit 7,a
                jr nz,wrslt_expanded
                and #03
                ld c,a
                call primary_slot_map
                bit 7,h
                jr nz,wrslt_direct
                bit 6,h
                jr nz,wrslt_direct
                call PAGE0_WRITE_HELPER
                ret
wrslt_direct:
                out (PPI_SLOT),a
                ld (hl),e
                ld a,d
                out (PPI_SLOT),a
                ret

wrslt_expanded:
                call expanded_slot_check
                jp z,unsupported_call
                ld a,h
                and #c0
                cp #c0
                jr z,wrslt_expanded_page3
                call expanded_temporary_select
                push bc
                call primary_slot_map
                bit 7,h
                jr nz,wrslt_expanded_direct
                bit 6,h
                jr nz,wrslt_expanded_direct
                call PAGE0_WRITE_HELPER
                jr wrslt_expanded_restore
wrslt_expanded_direct:
                out (PPI_SLOT),a
                ld (hl),e
                ld a,d
                out (PPI_SLOT),a
wrslt_expanded_restore:
                pop bc
                ld a,b
                call expanded_store_selector
                call expanded_write_selector
                ret

wrslt_expanded_page3:
                call expanded_load_selector
                ld b,a
                ld a,c
                and #0c
                add a,a
                add a,a
                add a,a
                add a,a
                ld d,a
                ld a,b
                and #3f
                or d
                call expanded_store_selector
                ex af,af'
                ld a,c
                and #03
                ld c,a
                in a,(PPI_SLOT)
                ld d,a
                ld a,c
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                ld c,a
                ld a,d
                and #3f
                or c
                out (PPI_SLOT),a
                ex af,af'
                ld (#ffff),a
                ld (hl),e
                ld a,b
                ld (#ffff),a
                ld a,d
                out (PPI_SLOT),a
                ld a,c
                rlca
                rlca
                and #03
                ld c,a
                ld a,b
                call expanded_store_selector
                ret

; Validate an expanded slot ID against EXPTBL without disturbing HL or E.
; Return the original slot ID in A and C; Z means that its primary slot is not
; expanded and the caller must fail closed.
expanded_slot_check:
                ld c,a
                and #03
                jr z,expanded_slot_check0
                dec a
                jr z,expanded_slot_check1
                dec a
                jr z,expanded_slot_check2
                ld a,(EXPTBL+3)
                jr expanded_slot_check_flag
expanded_slot_check2:
                ld a,(EXPTBL+2)
                jr expanded_slot_check_flag
expanded_slot_check1:
                ld a,(EXPTBL+1)
                jr expanded_slot_check_flag
expanded_slot_check0:
                ld a,(EXPTBL)
expanded_slot_check_flag:
                bit 7,a
                ld a,c
                ret

; Load the current non-inverted secondary selector for slot ID C.
expanded_load_selector:
                ld a,c
                and #03
                jr z,expanded_load_selector0
                dec a
                jr z,expanded_load_selector1
                dec a
                jr z,expanded_load_selector2
                ld a,(SLTTBL+3)
                ret
expanded_load_selector2:
                ld a,(SLTTBL+2)
                ret
expanded_load_selector1:
                ld a,(SLTTBL+1)
                ret
expanded_load_selector0:
                ld a,(SLTTBL)
                ret

; Build a selector for C's secondary slot and the page containing HL.
; Return A=new selector, B=old selector, C=primary slot.
expanded_compute_selector:
                call expanded_load_selector
                ld b,a
                ld a,h
                and #c0
                jr z,expanded_compute_page0
                cp #40
                jr z,expanded_compute_page1
                cp #80
                jr z,expanded_compute_page2
                ld a,c
                and #0c
                add a,a
                add a,a
                add a,a
                add a,a
                ld d,a
                ld a,b
                and #3f
                jr expanded_compute_merge
expanded_compute_page2:
                ld a,c
                and #0c
                add a,a
                add a,a
                ld d,a
                ld a,b
                and #cf
                jr expanded_compute_merge
expanded_compute_page1:
                ld a,c
                and #0c
                ld d,a
                ld a,b
                and #f3
                jr expanded_compute_merge
expanded_compute_page0:
                ld a,c
                and #0c
                rrca
                rrca
                ld d,a
                ld a,b
                and #fc
expanded_compute_merge:
                or d
                push af
                ld a,c
                and #03
                ld c,a
                pop af
                ret

expanded_temporary_select:
                call expanded_compute_selector
                call expanded_store_selector
; Fall through with the new selector in A and the old selector in B.

; Write A to primary slot C's FFFFh selector while preserving its current
; primary mapping. Callers only use this helper when A keeps page 3's
; secondary selection unchanged.
expanded_write_selector:
                push bc
                push de
                ld e,a
                in a,(PPI_SLOT)
                ld d,a
                and #3f
                ld b,a
                ld a,c
                and #03
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                or b
                out (PPI_SLOT),a
                ld a,e
                ld (#ffff),a
                ld a,d
                out (PPI_SLOT),a
                pop de
                pop bc
                ret

; Input C is a primary slot and the top two bits of H select the page. Return
; the complete new primary map in A and the exact previous map in D. HL and E
; are preserved for the public read/write contracts.
primary_slot_map:
                in a,(PPI_SLOT)
                ld d,a
                ld a,h
                and #c0
                jr z,primary_slot_map_page0
                cp #40
                jr z,primary_slot_map_page1
                cp #80
                jr z,primary_slot_map_page2
                ld a,c
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                ld b,a
                ld a,d
                and #3f
                or b
                ret
primary_slot_map_page2:
                ld a,c
                add a,a
                add a,a
                add a,a
                add a,a
                ld b,a
                ld a,d
                and #cf
                or b
                ret
primary_slot_map_page1:
                ld a,c
                add a,a
                add a,a
                ld b,a
                ld a,d
                and #f3
                or b
                ret
primary_slot_map_page0:
                ld a,d
                and #fc
                or c
                ret

; Partial inter-slot call. Primary and expanded targets in IX are accepted in
; page 1 or page 2. Both pages leave this page-0 routine and the page-3 stack
; visible. Restoration state is kept in the call's stack frame because the
; called routine may destroy every normal register.
calslt:
                di
                push iy
                pop bc
                bit 7,b
                jr nz,calslt_expanded
                push ix
                pop hl
                ld a,h
                and #c0
                cp #40
                jr z,calslt_page_supported
                cp #80
                jp nz,unsupported_call
calslt_page_supported:
                ld a,b
                and #03
                ld c,a
                call primary_slot_map
                push de
                out (PPI_SLOT),a
                ld hl,calslt_return
                push hl
                jp (ix)

; Preserve the called routine's normal AF/BC/DE/HL results while recovering
; the saved map through the alternate register set. IX and IY are untouched.
calslt_return:
                ex af,af'
                exx
                pop bc
                ld a,b
                out (PPI_SLOT),a
                exx
                ex af,af'
                ret

calslt_expanded:
                push ix
                pop hl
                ld a,h
                and #c0
                cp #40
                jr z,calslt_expanded_page_supported
                cp #80
                jp nz,unsupported_call
calslt_expanded_page_supported:
                ld a,b
                call expanded_slot_check
                jp z,unsupported_call
                call expanded_temporary_select
                push bc                        ; old selector, primary slot
                call primary_slot_map
                push de                        ; exact old primary map in D
                out (PPI_SLOT),a
                ld hl,calslt_expanded_return
                push hl
                jp (ix)

; Recover restoration state through the alternate register set so the target
; routine's normal AF/BC/DE/HL results survive unchanged.
calslt_expanded_return:
                ex af,af'
                exx
                pop bc                         ; B = old primary map
                pop de                         ; D = old selector, E = primary
                ld c,e
                ld a,d
                call expanded_store_selector
                call expanded_write_selector
                ld a,b
                out (PPI_SLOT),a
                exx
                ex af,af'
                ret

; Slot control. RSLREG and WSLREG map directly to the PPI register. ENASLT
; updates both the primary and secondary selectors for expanded slot IDs.
enaslt:
                di
                bit 7,a
                jr nz,enaslt_expanded
                and #03
                ld e,a
                ld a,h
                and #c0
                jr z,enaslt_page0
                cp #40
                jr z,enaslt_page1
                cp #80
                jr z,enaslt_page2

; Page 3 contains the normal stack. Pop the caller's return address before
; changing that page, then jump to it without reading the newly selected slot.
                ld a,e
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                ld c,a
                in a,(PPI_SLOT)
                and #3f
                or c
                pop hl
                out (PPI_SLOT),a
                jp (hl)

enaslt_page2:
                ld a,e
                add a,a
                add a,a
                add a,a
                add a,a
                ld b,#cf
                jr enaslt_direct

enaslt_page1:
                ld a,e
                add a,a
                add a,a
                ld b,#f3
                jr enaslt_direct

enaslt_page0:
                ld a,e
                ld c,a
                in a,(PPI_SLOT)
                and #fc
                or c
                jp PAGE0_SLOT_HELPER

enaslt_direct:
                ld c,a
                in a,(PPI_SLOT)
                and b
                or c
                out (PPI_SLOT),a
                ret

enaslt_expanded:
                call expanded_slot_check
                jp z,unsupported_call
                ld a,h
                and #c0
                cp #c0
                jr z,enaslt_expanded_page3

; Page 0 through page 2 leave the page-3 stack selected. Publish the selector,
; write it to hardware, and then reuse the primary-slot mapping paths.
                push hl
                call expanded_compute_selector
                call expanded_store_selector
                call expanded_write_selector
                pop hl
                ld e,c
                ld a,h
                and #c0
                jr z,enaslt_page0
                cp #40
                jr z,enaslt_page1
                jr enaslt_page2

; Page 3 must become stackless before either selector is changed. The mirror is
; updated first; after popping the caller's address, no RAM is touched.
enaslt_expanded_page3:
                call expanded_compute_selector
                call expanded_store_selector
                ld b,a
                pop hl
                in a,(PPI_SLOT)
                and #3f
                ld d,a
                ld a,c
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                or d
                out (PPI_SLOT),a
                ld a,b
                ld (#ffff),a
                jp (hl)

; Store A in the selector mirror for primary slot C while preserving A, B,
; and C. D is scratch.
expanded_store_selector:
                ld d,a
                ld a,c
                and #03
                jr z,expanded_store_selector0
                dec a
                jr z,expanded_store_selector1
                dec a
                jr z,expanded_store_selector2
                ld a,d
                ld (SLTTBL+3),a
                ret
expanded_store_selector2:
                ld a,d
                ld (SLTTBL+2),a
                ret
expanded_store_selector1:
                ld a,d
                ld (SLTTBL+1),a
                ret
expanded_store_selector0:
                ld a,d
                ld (SLTTBL),a
                ret

rslreg:
                in a,(PPI_SLOT)
                ret

wslreg:
                out (PPI_SLOT),a
                ret

rdvdp:
                in a,(VDP_CONTROL)
                ld (STATFL),a
                ret

snsmat:
                and #0f
                ld c,a
                in a,(PPI_CONTROL_C)
                and #f0
                or c
                out (PPI_CONTROL_C),a
                in a,(PPI_KEYBOARD)
                ret

; Copied to F380h-F391h during cold boot. These instructions are original
; RainBIOS code for operations that temporarily remove page-0 BIOS visibility.
slot_helpers_image:
                db #d3,PPI_SLOT,#c9             ; switch page 0, return caller
                db #d3,PPI_SLOT,#46,#7a         ; read byte, restore old map
                db #d3,PPI_SLOT,#78,#c9
                db #d3,PPI_SLOT,#73,#7a         ; write byte, restore old map
                db #d3,PPI_SLOT,#c9
slot_helpers_image_end:

cold_boot_vdp_registers:
                db #02,#e0,#06,#ff,#03,#36,#07,#01

text40_vdp_registers:
                db #00,#b0,#00,#00,#01,#36,#07,#f1
text32_vdp_registers:
                db #00,#a0,#06,#80,#00,#36,#07,#f1
graphics2_vdp_registers:
                db #02,#a0,#06,#ff,#03,#36,#07,#01

; International keyboard matrix rows 0-5, bit 0 first. A zero entry is not
; translated in this first keyboard slice.
keymap_unshifted:
                db '0', '1', '2', '3', '4', '5', '6', '7'
                db '8', '9', '-', '=', #5c, '[', ']', ';'
                db #27, '`', ',', '.', '/', 0,   'A', 'B'
                db 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'
                db 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'
                db 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
keymap_shifted:
                db ')', '!', '@', '#', '$', '%', '^', '&'
                db '*', '(', '_', '+', '|', '{', '}', ':'
                db '"', '~', '<', '>', '?', 0,   'a', 'b'
                db 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'
                db 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r'
                db 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
keymap_row7:
                db 0,0,#1b,#09,#03,#08,0,#0d
keymap_row8:
                db #20,#0b,#12,#7f,#1d,#1e,#1f,#1c

jingle_notes:
                db #d6,#00                     ; C5
                db #aa,#00                     ; E5
                db #8f,#00                     ; G5
                db #6b,#00                     ; C6

boot_font:
                incbin "boot_font.bin"
options_name_ready:
                incbin "options_name_ready.bin"
options_name_missing:
                incbin "options_name_missing.bin"
options_color:
                incbin "options_color.bin"

logo_pattern:
                incbin "logo_pattern.bin"
logo_name:
                incbin "logo_name.bin"
logo_color:
                incbin "logo_color.bin"

                defs #8000-$,#ff
