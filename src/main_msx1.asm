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

RG1SAV          equ #f3e0
STATFL          equ #f3e7
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

                jp unsupported_inline_call      ; 0030 CALLF
                defs #0038-$,#ff
                jp empty_interrupt              ; 0038 KEYINT
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
                jp unsupported_call             ; 005F CHGMOD
                jp unsupported_call             ; 0062 CHGCLR
                defs #0066-$,#ff
                jp nmi_handler                  ; 0066 NMI
                jp unsupported_call             ; 0069 CLRSPR
                jp unsupported_call             ; 006C INITXT
                jp unsupported_call             ; 006F INIT32
                jp unsupported_call             ; 0072 INITGRP
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
                jp unsupported_call             ; 009C CHSNS
                jp unsupported_call             ; 009F CHGET
                jp unsupported_call             ; 00A2 CHPUT
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
                jp unsupported_call             ; 00C3 CLS
                jp unsupported_call             ; 00C6 POSIT
                jp unsupported_call             ; 00C9 FNKSB
                jp unsupported_call             ; 00CC ERAFNK
                jp unsupported_call             ; 00CF DSPFNK
                jp unsupported_call             ; 00D2 TOTEXT
                jp unsupported_call             ; 00D5 GTSTCK
                jp unsupported_call             ; 00D8 GTTRIG
                jp unsupported_call             ; 00DB GTPAD
                jp unsupported_call             ; 00DE GTPDL
                jp unsupported_call             ; 00E1 TAPION
                jp unsupported_call             ; 00E4 TAPIN
                jp unsupported_call             ; 00E7 TAPIOF
                jp unsupported_call             ; 00EA TAPOON
                jp unsupported_call             ; 00ED TAPOUT
                jp unsupported_call             ; 00F0 TAPOOF
                jp unsupported_call             ; 00F3 STMOTR
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
                jp unsupported_call             ; 0144 PHYDIO
                jp unsupported_call             ; 0147 FORMAT
                jp unsupported_call             ; 014A ISFLIO
                jp unsupported_call             ; 014D OUTDLP
                jp unsupported_call             ; 0150 GETVCP
                jp unsupported_call             ; 0153 GETVC2
                jp unsupported_call             ; 0156 KILBUF
                jp unsupported_call             ; 0159 CALBAS
                defs #015f-$,#ff
                ret                             ; 015F MSX1 compatibility

; Keep implementation code away from the fixed ABI area.
                defs #0200-$,#ff

cold_boot:
                di

; Do not assume the main ROM is in primary slot 0. Preserve the page-0/page-1
; mapping selected by reset and scan primary slots for writable RAM in both
; pages 2 and 3. This bootstrap is stackless and does not yet handle expanded
; slots.
                ld a,#82
                out (PPI_CONTROL),a             ; PPI mode 0, keyboard input
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

; Require two complementary patterns to stick in each page, restoring every
; probe byte before selecting or rejecting the candidate.
                ld hl,RAM_TEST3
                ld c,(hl)
                ld (hl),#55
                ld a,(hl)
                cp #55
                jr nz,bootstrap_primary_ram_fail
                ld (hl),#aa
                ld a,(hl)
                cp #aa
                jr nz,bootstrap_primary_ram_fail
                ld (hl),c

                ld hl,RAM_TEST2
                ld c,(hl)
                ld (hl),#55
                ld a,(hl)
                cp #55
                jr nz,bootstrap_primary_ram_fail
                ld (hl),#aa
                ld a,(hl)
                cp #aa
                jr nz,bootstrap_primary_ram_fail
                ld (hl),c
                jr bootstrap_primary_ram_found

bootstrap_primary_ram_fail:
                ld (hl),c
                inc e
                ld a,e
                cp 4
                jr nz,bootstrap_primary_ram_slot

; No primary RAM was found. Restore the reset mapping and fail closed. A later
; M1 slice will add expanded-slot probing and a visible diagnostic.
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

; Record the minimal MAIN-ROM state. The RAMAD0-RAMAD3 bytes at F341h-F344h
; belong to the Disk-ROM communication area and are deliberately not claimed.
                ld a,d
                and #03
                ld (BIOSSLT),a
                ld hl,#8000
                ld (BOTTOM),hl
                ld hl,STACK_TOP
                ld (HIMEM),hl

; Empty hooks begin with RET. EXPTBL/SLTTBL remain zero in this explicitly
; primary-slot-only slice.
                ld hl,HOOKBASE
                ld de,5
                ld b,113
bootstrap_empty_hook:
                ld (hl),#c9
                add hl,de
                djnz bootstrap_empty_hook

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

; Enable the display. VDP interrupts remain disabled during M1 bring-up.
                ld a,#c0
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

; Discover simple primary-slot cartridges after RAM, video, and sound are
; initialized. A public MSX cartridge header begins with "AB", followed by the
; little-endian INIT address. An INIT routine that returns lets scanning
; continue; a game may keep control instead. M1E scans 4000h and 8000h in each
; non-BIOS primary slot and can invoke INIT in page 1 or page 2.
                call cold_boot_scan_cartridges

; Poll keyboard matrix row 8. MSX keys are active-low, and bit 0 is Space.
cold_boot_wait:
                in a,(PPI_CONTROL_C)
                and #f0
                or #08
                out (PPI_CONTROL_C),a
                in a,(PPI_KEYBOARD)
                bit 0,a
                jr nz,cold_boot_wait

; Space opens a compact Screen 1 options/information page. Its static state is
; intentionally honest about the incomplete M1 cartridge path.
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
                ld hl,options_name
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
                ld a,#c0
                out (VDP_CONTROL),a
                ld a,#81
                out (VDP_CONTROL),a
cold_boot_options_wait:
                jr cold_boot_options_wait

cold_boot_scan_cartridges:
                xor a
                ld (CART_SCAN_SLOT),a
cold_boot_scan_slot:
                ld a,(CART_SCAN_SLOT)
                cp 4
                ret z
                ld b,a
                ld a,(BIOSSLT)
                and #03
                cp b
                jr z,cold_boot_scan_next_slot
                ld hl,#4000
                call cold_boot_try_cartridge
                ld hl,#8000
                call cold_boot_try_cartridge
cold_boot_scan_next_slot:
                ld a,(CART_SCAN_SLOT)
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
                call calslt
                ret

; Ordinary unimplemented calls return carry set. This is a bring-up contract,
; not an assertion about compatible error behavior.
unsupported_call:
                scf
                ret

; CALLF embeds operands after the call site, so returning as if it were an
; ordinary routine would execute those operands. Fail closed until M1.
unsupported_inline_call:
                di
unsupported_inline_halt:
                halt
                jr unsupported_inline_halt

empty_interrupt:
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
                ld c,a
                ld b,#01
                jp wrtvdp

enascr:
                ld a,(RG1SAV)
                or #40
                ld c,a
                ld b,#01
                jp wrtvdp

wrtvdp:
                push af
                push hl
                ld a,b
                and #07
                add a,#df
                ld l,a
                ld h,#f3
                ld (hl),c
                ld a,c
                out (VDP_CONTROL),a
                ld a,b
                or #80
                out (VDP_CONTROL),a
                pop hl
                pop af
                ret

setrd:
                ld a,l
                out (VDP_CONTROL),a
                ld a,h
                and #3f
                out (VDP_CONTROL),a
                ret

setwrt:
                ld a,l
                out (VDP_CONTROL),a
                ld a,h
                and #3f
                or #40
                out (VDP_CONTROL),a
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

; Primary-slot memory calls. The page-0 cases execute the access and exact map
; restoration from RAM. Other pages can be changed while this page-0 code
; remains visible; page 3 is restored before any stack operation.
rdslt:
                bit 7,a
                jp nz,unsupported_call
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

wrslt:
                bit 7,a
                jp nz,unsupported_call
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

; Partial inter-slot call. M1D accepts non-expanded primary slots when the
; target in IX is in page 1 or page 2. Both pages leave this page-0 routine and
; the page-3 stack visible. The exact previous primary map is kept in this
; call's stack frame because the called routine may destroy every normal
; register.
calslt:
                push iy
                pop bc
                bit 7,b
                jp nz,unsupported_call
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

; Primary-slot control. RSLREG and WSLREG map directly to the PPI register.
; ENASLT deliberately rejects expanded-slot IDs until EXPTBL/SLTTBL and the
; secondary-slot register have complete M1 support.
enaslt:
                bit 7,a
                jp nz,unsupported_call
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
                ld b,a
                in a,(PPI_CONTROL_C)
                and #f0
                or b
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

jingle_notes:
                db #d6,#00                     ; C5
                db #aa,#00                     ; E5
                db #8f,#00                     ; G5
                db #6b,#00                     ; C6

boot_font:
                incbin "boot_font.bin"
options_name:
                incbin "options_name.bin"
options_color:
                incbin "options_color.bin"

logo_pattern:
                incbin "logo_pattern.bin"
logo_name:
                incbin "logo_name.bin"
logo_color:
                incbin "logo_color.bin"

                defs #8000-$,#ff
