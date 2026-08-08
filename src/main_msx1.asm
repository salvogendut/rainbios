; SPDX-License-Identifier: BSD-3-Clause
;
; RainBIOS M1 MSX1 main-ROM skeleton.
;
; This source establishes the public ROM layout. Routines marked partial have
; straightforward hardware behavior but have not yet passed instruction-level
; and hardware compatibility tests.

VDP_DATA        equ #98
VDP_CONTROL     equ #99
PRINTER_DATA    equ #91
PRINTER_CTRL    equ #90
PSG_ADDRESS     equ #a0
PSG_WRITE       equ #a1
PSG_READ        equ #a2
PSG_MIXER       equ #07
PSG_PORT_A      equ #0e
PSG_PORT_B      equ #0f
MAPPER_PAGE0    equ #fc
MAPPER_PAGE1    equ #fd
MAPPER_PAGE2    equ #fe
MAPPER_PAGE3    equ #ff
PPI_SLOT        equ #a8
PPI_KEYBOARD    equ #a9
PPI_CONTROL_C   equ #aa
PPI_CONTROL     equ #ab

R0SAV           equ #f3df
RG1SAV          equ #f3e0
RG8SAV          equ #ffe7
RG9SAV          equ #ffe8
STATFL          equ #f3e7
FORCLR          equ #f3e9
BAKCLR          equ #f3ea
BDRCLR          equ #f3eb
LINL40          equ #f3ae
LINL32          equ #f3af
LINLEN          equ #f3b0
CRTCNT          equ #f3b1
CONTROLLER_PORT1 equ #f3b8
CONTROLLER_PORT2 equ #f3b9
CAS_MOTOR       equ #f3ba
CAS_MOTOR_TIMER equ #f3bb
CAS_MOTOR_FRAMES equ 120
DISK_MOTOR      equ #f3bc
DISK_MOTOR_TIMER equ #f3bd
DISK_PRESENT    equ #f3be
DISK_MOTOR_FRAMES equ 120
FDC_DRIVE       equ #7ffd
MLTNAM          equ #f3d1
MLTCOL          equ #f3d3
MLTCGP          equ #f3d5
MLTATR          equ #f3d7
MLTPAT          equ #f3d9
CSRY            equ #f3dc
CSRX            equ #f3dd
SCNCNT          equ #f3f6
REPCNT          equ #f3f7
PUTPNT          equ #f3f8
GETPNT          equ #f3fa
CLIKSW          equ #f3db
CLICKCNT        equ #f559
TPAD_MASK       equ #f560                 ; touch panel AND/OR masks (2 bytes)
INLIN_CNT       equ #f558
CNSDFG          equ #f3de
BUFFER          equ #f55e
INLIN_START_COL equ #f55c
INLIN_START_ROW equ #f55d
INLIN_TMP       equ #f55b
DEADKEY_TMP     equ #f55a
AUTFLG          equ #f6aa
DEADST          equ #fcac
FNKSTR          equ #f87f
FNKFLG          equ #fbce
INTFLG          equ #fc9b
NAMBAS          equ #f922
CGPBAS          equ #f924
PATBAS          equ #f926
ATRBAS          equ #f928
OLDKEY          equ #fbda
NEWKEY          equ #fbe5
KEYBUF          equ #fbf0
KEYBUF_END      equ #fc18
PADY            equ #fc9c
PADX            equ #fc9d
JIFFY           equ #fc9e
CAPST           equ #fcab
SCRMOD          equ #fcaf
BOTTOM          equ #fc48
HIMEM           equ #fc4a
BIOSSLT         equ #fcc0
EXPTBL          equ #fcc1
SLTTBL          equ #fcc5
HOOKBASE        equ #fd9a
EXBRSA          equ #faf8

RAM_TEST2       equ #bfff
RAM_TEST3       equ #f37f
RDPRIM          equ #f380
WRPRIM          equ #f385
CLPRIM          equ #f38c
CLPRM1          equ #f398
CART_SCAN_SLOT  equ #f300
PAYLOAD_SLOT    equ #f301
PAYLOAD_ENTRY   equ #f302
PAYLOAD_RAM_END equ #f304
TAPE_PERIOD     equ #f306
TAPE_LEVEL      equ #f307
TAPE_SYNC       equ #f308
IDE_SLOT        equ #f309
SD_FLAGS        equ #f30a
SD_INIT_TRIES   equ #f30b
APP_CART_PRESENT equ #f30c
RAMAD0          equ #f341
MAPPER_SEGMENTS equ #f345
H_PHYD          equ #ffa7
H_FORM          equ #ffac
H_ISFL          equ #fedf
H_OUTD          equ #fee4
H_RUNC          equ #fecb
H_STKE          equ #feda
H_LPTO          equ #ffb6
H_LPTS          equ #ffbb
LPTPOS          equ #f415
DEVICE          equ #fd99
DISK_SETUP      equ #fb29
NEXTOR_BOOT_DRIVE equ #f2fd
NEXTOR_DOS_VERSION equ #f313
NEXTOR_VERSION  equ #f318
PTRFIL          equ #f864
VOICEN          equ #fb38
VCBA            equ #fb41
QUEUES          equ #f3f3
FRCNEW          equ #f3f5
MUSICF          equ #fb3f
PLYCNT          equ #fb40
PLAY_AREA       equ #fb35
PLAY_AREA_END   equ #fb91
QUETAB          equ #f959
QUEUE_END       equ #faf5
MEMSIZ          equ #f672
STKTOP          equ #f674
INITIAL_MEMSIZ  equ #f168
INITIAL_STKTOP  equ #f0a0
EXTENSION_STACK equ #f092
STACK_TOP       equ #f380
CALSLT_P3_FRAME equ #f360
ASSET_BUFFER    equ #c000

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
                IFDEF MSX2
                db #01                          ; 002D MSX generation: MSX2
                ELSE
                db #00                          ; 002D MSX generation: MSX1
                ENDIF
                db #00                          ; 002E reserved
                db #00                          ; 002F reserved

                jp callf                        ; 0030 CALLF
                defs #0038-$,#ff
                jp keyint                       ; 0038 KEYINT
                jp unsupported_call             ; 003B INITIO
                jp inifnk                        ; 003E INIFNK
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
                jp chgclr                       ; 0062 CHGCLR
                defs #0066-$,#ff
                jp nmi_handler                  ; 0066 NMI
                jp clrspr                       ; 0069 CLRSPR
                jp initxt                       ; 006C INITXT
                jp init32                       ; 006F INIT32
                jp initgrp                      ; 0072 INITGRP
                jp inimlt                       ; 0075 INIMLT
                jp settxt                       ; 0078 SETTXT
                jp sett32                       ; 007B SETT32
                jp setgrp                       ; 007E SETGRP
                jp setmlt                       ; 0081 SETMLT
                jp calpat                       ; 0084 CALPAT
                jp calatr                       ; 0087 CALATR
                jp gspsiz                       ; 008A GSPSIZ
                jp grpprt                       ; 008D GRPPRT
                jp gicini                       ; 0090 GICINI
                jp wrtpsg                       ; 0093 WRTPSG
                jp rdpsg                        ; 0096 RDPSG
                jp unsupported_call             ; 0099 STRTMS
                jp chsns                        ; 009C CHSNS
                jp chget                        ; 009F CHGET
                jp chput                        ; 00A2 CHPUT
                jp lptout                       ; 00A5 LPTOUT
                jp lptstt                       ; 00A8 LPTSTT
                jp unsupported_call             ; 00AB CNVCHR
                jp pinlin                        ; 00AE PINLIN
                jp inlin                         ; 00B1 INLIN
                jp qinlin                        ; 00B4 QINLIN
                jp breakx                        ; 00B7 BREAKX
                jp iscntc                        ; 00BA ISCNTC
                jp ckcntc                        ; 00BD CKCNTC
                jp beep                          ; 00C0 BEEP
                jp cls                          ; 00C3 CLS
                jp posit                        ; 00C6 POSIT
                jp fnksb                         ; 00C9 FNKSB
                jp erafnk                        ; 00CC ERAFNK
                jp dspfnk                        ; 00CF DSPFNK
                jp totext                        ; 00D2 TOTEXT
                jp gtstck                        ; 00D5 GTSTCK
                jp gttrig                        ; 00D8 GTTRIG
                jp gtpad                         ; 00DB GTPAD
                jp gtpdl                         ; 00DE GTPDL
                jp tapion                       ; 00E1 TAPION
                jp tapin                        ; 00E4 TAPIN
                jp tapiof                       ; 00E7 TAPIOF
                jp tapoon                       ; 00EA TAPOON
                jp tapout                       ; 00ED TAPOUT
                jp tapoof                       ; 00F0 TAPOOF
                jp stmotr                       ; 00F3 STMOTR
                jp unsupported_call             ; 00F6 LFTQ
                jp unsupported_call             ; 00F9 PUTQ
                jp rightc                       ; 00FC RIGHTC
                jp leftc                        ; 00FF LEFTC
                jp upc                          ; 0102 UPC
                jp tupc                         ; 0105 TUPC
                jp downc                        ; 0108 DOWNC
                jp tdownc                       ; 010B TDOWNC
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
                jp chgcap                        ; 0132 CHGCAP
                jp chgsnd                        ; 0135 CHGSND
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
                jp subrom                       ; 015C SUBROM
                jp extrom                       ; 015F EXTROM
                jp chkslz                       ; 0162 CHKSLZ

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

; Give standard memory mappers four independent 16 KiB pages. Machines without
; a mapper ignore these reserved ports; mapper sizing beyond 64 KiB is deferred.
                ld a,3
                out (MAPPER_PAGE0),a
                ld a,2
                out (MAPPER_PAGE1),a
                ld a,1
                out (MAPPER_PAGE2),a
                xor a
                out (MAPPER_PAGE3),a

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
                push de                         ; preserve reset map/RAM primary
                push bc                         ; preserve RAM secondary
                xor a
                ld hl,#f380
                ld (hl),a
                ld de,#f381
                ld bc,#0c7e                    ; clear F381h through FFFEh
                ldir

; Install the standardized primary-slot read, write, and call primitives at
; F380h-F399h before any extension ROM can use them.
                ld hl,slot_helpers_image
                ld de,RDPRIM
                ld bc,slot_helpers_image_end-slot_helpers_image
                ldir
                pop bc
                pop de

; F300h-F37Fh is the pre-DOS scratch area. Initialize it to safe returns, then
; use its first bytes only until a disk kernel takes ownership. The LDIR
; advances the main DE/BC, so keep the reset map, RAM primary, and RAM
; secondary in the alternate bank while the clearing runs.
                exx
                ld hl,#f300
                ld (hl),#c9
                ld de,#f301
                ld bc,#007f
                ldir
                exx

; Publish the full slot ID of the discovered RAM for Disk-ROM extensions.
; B=4 is the unexpanded sentinel; otherwise B is the secondary slot number.
                ld a,b
                cp 4
                ld a,e
                jr z,bootstrap_ram_slot_ready
                ld a,b
                add a,a
                add a,a
                or e
                or #80
bootstrap_ram_slot_ready:
                ld hl,RAMAD0
                ld (hl),a
                inc hl
                ld (hl),a
                inc hl
                ld (hl),a
                inc hl
                ld (hl),a

; Record the primary MAIN-ROM slot before probing expansion state.
                ld a,d
                and #03
                ld (BIOSSLT),a
                call bootstrap_expanded_slots
                call bootstrap_size_mapper
                ld hl,#8000
                ld (BOTTOM),hl
                ld hl,STACK_TOP
                ld (HIMEM),hl
                ld hl,INITIAL_MEMSIZ
                ld (MEMSIZ),hl
                ld hl,INITIAL_STKTOP
                ld (STKTOP),hl

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
                ld hl,#0800
                ld (MLTNAM),hl
                ld hl,#0000
                ld (MLTCGP),hl
                ld hl,#1b00
                ld (MLTATR),hl
                ld hl,#3800
                ld (MLTPAT),hl
                ld a,1
                ld (SCNCNT),a
                ld a,50
                ld (REPCNT),a
                xor a
                ld (CAPST),a                    ; caps off at boot
                ld (INTFLG),a                   ; no pending break
                ld (CNSDFG),a                   ; function keys hidden
                ld (CLIKSW),a                   ; no key click
                call inifnk                     ; default function-key strings
                in a,(PPI_CONTROL_C)
                or #40
                out (PPI_CONTROL_C),a           ; CAPS LED off
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
                ld (IDE_SLOT),a
                ld (CONTROLLER_PORT1),a
                ld (CONTROLLER_PORT2),a
                xor a
                ld (SD_FLAGS),a
                ld (APP_CART_PRESENT),a
                ld (CAS_MOTOR),a
                ld (CAS_MOTOR_TIMER),a
                ld (DISK_MOTOR),a
                ld (DISK_MOTOR_TIMER),a
                ld (DISK_PRESENT),a
                ld hl,0
                ld (PAYLOAD_ENTRY),hl
                ld (PAYLOAD_RAM_END),hl

                ld sp,STACK_TOP

                IFDEF MSX2
                call bootstrap_msx2
                ENDIF

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

; Expand the compressed logo tables in scratch RAM and upload them to VRAM.
                call cold_boot_render_logo

; The decoder workspace overlaps application RAM used by storage kernels.
; Restore the reset-time zero fill before cartridge discovery so embedding
; compressed artwork is observationally equivalent to the former ROM-direct
; upload path.
                xor a
                ld hl,ASSET_BUFFER
                ld (hl),a
                ld de,ASSET_BUFFER+1
                ld bc,#17ff
                ldir
                ld a,#5a
                ld (ASSET_BUFFER),a            ; mapper segment-0 probe marker

; Enable the display and VBlank interrupt source. The CPU stays under DI until
; cartridge discovery has a stable page-0 BIOS and page-3 stack.
                ld a,#e0
                out (VDP_CONTROL),a
                ld a,#81
                out (VDP_CONTROL),a

; Initialize sound and both controller connectors, then play a four-note
; startup motif on PSG channel A. Channel B/C volumes remain zero.
                call gicini_impl
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
                ld sp,EXTENSION_STACK
                call cold_boot_scan_cartridges
                call H_STKE
                call cold_boot_init_disk
                call cold_boot_valid_payload
                jr c,cold_boot_payload_ready
                call cold_boot_select_internal_payload
                jr c,cold_boot_payload_ready
                ld a,(APP_CART_PRESENT)
                or a
                jp z,cold_boot_options
cold_boot_payload_ready:
                ld sp,STACK_TOP
                ei
                ld a,(APP_CART_PRESENT)
                or a
                jr nz,cold_boot_cartridge_wait
                ld b,180                      ; about three seconds at 60 Hz
                jr cold_boot_wait

; Match the C-BIOS start-up sequence: initialize disk context and invoke the
; disk-ROM bootstrap hook so the selected disk device can install itself before
; the interactive menu is presented.
cold_boot_init_disk:
                jp cold_boot_init_disk_impl

; Give Space a bounded window to open the options menu. If no external
; cartridge or storage loader kept control, launch the selected BASIC payload.
cold_boot_wait:
                call chsns
                jr nz,cold_boot_wait_read
                ei
                halt
                djnz cold_boot_wait
                jr cold_boot_launch_payload
cold_boot_wait_read:
                call chget
                cp #20
                jr z,cold_boot_options
                djnz cold_boot_wait
                jr cold_boot_launch_payload

; A conventional cartridge whose INIT returns may continue through hooks or
; interrupt-driven code.  Keep the pre-payload unbounded wait in that case so
; the embedded BASIC cannot later replace page 1 underneath the cartridge.
; Space remains available to enter the boot menu explicitly.
cold_boot_cartridge_wait:
                call chsns
                jr nz,cold_boot_cartridge_wait_read
                ei
                halt
                jr cold_boot_cartridge_wait
cold_boot_cartridge_wait_read:
                call chget
                cp #20
                jr z,cold_boot_options
                jr cold_boot_cartridge_wait

; Space opens a compact Screen 1 menu. The name table selected below reports
; whether a validated BASIC payload was discovered.
cold_boot_options:
                call cold_boot_render_options
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
                jr z,cold_boot_launch_payload
                cp '2'
                jr z,cold_boot_options_boot_disk
                cp '3'
                jr z,cold_boot_options_ide
                jr cold_boot_options_wait

; Boot drive A through the floppy disk-ROM bootstrap hook. The disk driver
; installs H_RUNC and publishes H_PHYD during cartridge discovery; the probe
; below keeps an absent disk ROM from turning the key into a stray hook call.
; disk_boot transfers control to the loader at C000h+1Eh when a bootable medium
; is present, so a return always means the menu should continue.
cold_boot_options_boot_disk:
                ld a,(H_RUNC)
                cp #c9
                jr z,cold_boot_options_wait
                ld a,1
                ld (DEVICE),a
                xor a
                ld (DISK_SETUP),a
                call H_RUNC
                jr cold_boot_options_wait

; Boot an IDE cartridge through the Sunrise ATA window. The boot scan records
; IDE_SLOT for Sunrise IDE / SD Mapper cartridges without running their INIT.
; ide_boot reads sector 0 into C000h and transfers control to the loader at
; C000h+1Eh when a bootable medium is present, so a return always means the
; menu should continue.
cold_boot_options_ide:
                call ide_boot
                ld h,2
                ld l,12
                call posit
                ld hl,storage_boot_failed_message
cold_boot_options_ide_status:
                ld a,(hl)
                or a
                jr z,cold_boot_options_wait
                call chput
                inc hl
                jr cold_boot_options_ide_status

; Enter a validated page-1 payload without a return address. Page 0 remains
; the BIOS, pages 2/3 remain the selected contiguous RAM, SP is restored to
; HIMEM, and all normal and index registers are zero. EI becomes effective
; after RET transfers to the descriptor entry.
cold_boot_launch_payload:
                ld a,(PAYLOAD_SLOT)
                cp #ff
                jr z,cold_boot_options_wait
                di
                ld b,a
                ld a,(BIOSSLT)
                cp b
                jp z,cold_boot_expand_internal_payload
                ld a,b
                ld h,#40
                call enaslt
                jr cold_boot_payload_mapped
cold_boot_payload_mapped:
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

; Sunrise IDE and SD Mapper use the public 40F6h INIT convention and are
; storage boot providers: when their boot path returns, embedded BASIC is the
; intended fallback.  Every other ordinary AB cartridge suppresses automatic
; BASIC, including header-only cartridges with a null INIT pointer.
                ld a,d
                cp #40
                jr nz,cold_boot_mark_app_cartridge
                ld a,e
                cp #f6
                jr z,cold_boot_check_ide
cold_boot_mark_app_cartridge:
                ld a,1
                ld (APP_CART_PRESENT),a
                ld a,d
                or e
                ret z
                ld a,d
                and #c0
                cp #40
                jr z,cold_boot_check_ide
                cp #80
                ret nz
                jr cold_boot_call_cartridge
; Sunrise IDE / SD Mapper cartridges publish the shared "AB" header with the
; INIT pointer at 40F6h. Record the slot for RainBIOS's direct fallback loader,
; then follow the ordinary cartridge contract and invoke INIT. A disk kernel
; can allocate its work area and install H.RUNC for the standard boot path.
cold_boot_check_ide:
                ld a,d
                cp #40
                jr nz,cold_boot_call_cartridge
                ld a,e
                cp #f6
                jr nz,cold_boot_call_cartridge
                ld a,(CART_SCAN_SLOT)
                ld (IDE_SLOT),a
                jr cold_boot_call_cartridge
cold_boot_call_cartridge:
                push de
                pop ix
                ld a,(CART_SCAN_SLOT)
                ld b,a
                ld c,0
                push bc
                pop iy
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

; Select the payload physically embedded in the main ROM after all external
; cartridge and storage boot paths have had priority. The exact standalone
; payload is stored as an RBC1 compressed container so addresses probed by
; storage kernels remain erased. Validate the container marker and pinned
; entry before publishing the internal payload contract.
cold_boot_select_internal_payload:
                jp cold_boot_select_internal_payload_impl

; Ordinary unimplemented calls return carry set. This is a bring-up contract,
; not an assertion about compatible error behavior.
unsupported_call:
                 scf
                 ret

; $00A8 LPTSTT: return the printer status. Reads the busy line from the
; printer control port (bit 1 = status, low = ready, high = busy): returns
; A = FFh with Z clear when ready, A = 00h with Z set while busy, matching
; the official BIOS.
lptstt:
                 call H_LPTS                    ; printer status hook
                 in a,(PRINTER_CTRL)
                 rrca
                 rrca                            ; status bit into carry
                 ccf
                 sbc a,a
                 ret

; $00A5 LPTOUT: write the character in A to the printer. Polls the printer
; status until it is ready or a break is detected, then latches the byte on
; the data port and pulses the strobe. On a break, writes CR, resets the
; printer position, and returns with carry set; otherwise carry is clear.
lptout:
                 call H_LPTO                    ; printer output hook
                 push af                        ; store byte
lptout_wait:
                 call breakx
                 jr c,lptout_abort
                 call lptstt
                 jr z,lptout_wait               ; printer busy, keep waiting
                 pop af                         ; restore byte
lptout_write:
                 push af
                 out (PRINTER_DATA),a           ; latch the byte on the data port
                 xor a
                 out (PRINTER_CTRL),a           ; strobe on
                 dec a
                 out (PRINTER_CTRL),a           ; strobe off
                 pop af
                 and a                          ; clear carry (ok)
                 ret
lptout_abort:
                 xor a
                 ld (LPTPOS),a                  ; printer position = 0
                 ld a,13
                 call lptout_write              ; write carriage return
                 pop af
                 scf                            ; carry set (aborted)
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
                ex af,af'
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
                ex af,af'
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
                call keyboard_click_update
                call controller_capture
                call cassette_motor_tick
                call disk_motor_tick
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
                IFDEF MSX2
                ld a,c
                cp 8
                jr c,wrtvdp_msx2_r0_7
                cp 24
                jp c,wrtvdp_v9938
wrtvdp_msx2_r0_7:
                ENDIF
                jp wrtvdp_impl

; $0062 CHGCLR: apply FORCLR/BAKCLR/BDRCLR to the current screen. The text
; color and border come from the VDP R7 register; Screen 1 additionally
; recolors its 32 color-table cells with (FORCLR<<4)|BAKCLR.
; $0081 SETMLT: switch the VDP to multicolor (Screen 3) using the MLTNAM,
; MLTCOL, MLTCGP, MLTATR and MLTPAT base addresses. Those five RAM variables
; are contiguous and map one-to-one onto the R2-R6 base registers.
setmlt:
                ld a,(R0SAV)
                and #f1
                ld b,a
                ld c,0
                call wrtvdp
                ld a,(RG1SAV)
                and #e7
                or #08                         ; M2 selects multicolor
                ld b,a
                ld c,1
                call wrtvdp
                ld hl,setmlt_shift_table
                ld de,MLTNAM
                ld c,2
setmlt_base_loop:
                ld b,(hl)                      ; shift count for register c
                inc hl
                ld a,(de)
                ld l,a
                inc de
                ld a,(de)
                ld h,a
                inc de
                xor a
setmlt_shift_loop:
                add hl,hl
                adc a,a
                djnz setmlt_shift_loop
                ld b,a
                call wrtvdp
                inc c
                ld a,c
                cp 7
                jr nz,setmlt_base_loop
                ret
setmlt_shift_table:
                db 6,10,5,9,5                  ; R2..R6

; $0075 INIMLT: initialize multicolor mode. Publish the MLT* base addresses,
; hide sprites, seed the name table with the canonical six-band color ramp so
; callers that do not redraw still get a visible screen, and clear the pattern
; plane to the background color.
inimlt:
                call disscr
                ld a,3
                ld (SCRMOD),a
                call chgclr
                ld hl,(MLTNAM)
                ld (NAMBAS),hl
                ld hl,(MLTCGP)
                ld (CGPBAS),hl
                ld hl,(MLTATR)
                ld (ATRBAS),hl
                ld hl,(MLTPAT)
                ld (PATBAS),hl
                call setmlt
                ld hl,(ATRBAS)
                ld a,#d0
                call wrtvrm                     ; hide sprites
                ld hl,(NAMBAS)
                call setwrt
                di
                xor a
                ld b,6
inimlt_group:
                push af
                ld e,4
inimlt_row:
                push af
                ld c,32
inimlt_col:
                out (VDP_DATA),a
                inc a
                dec c
                jr nz,inimlt_col
                pop af
                dec e
                jr nz,inimlt_row
                pop af
                add a,32
                djnz inimlt_group
                ei
                ld a,(BAKCLR)
                and #0f
                ld b,a
                rlca
                rlca
                rlca
                rlca
                or b
                ld hl,(CGPBAS)
                ld bc,#0800
                call filvrm
                ld a,1
                ld (CSRY),a
                ld (CSRX),a
                ld a,(LINL32)
                ld (LINLEN),a
                jp enascr

; Partial mode dispatcher for MSX1 Screens 0-3 and guarded V9938 Screen 7.
chgmod:
                or a
                jp z,initxt
                cp 1
                jp z,init32
                cp 2
                jp z,initgrp
                cp 3
                jp z,inimlt
                cp 7
                jp z,initv9938_screen7
                jp unsupported_call

; Program all eight TMS9918 registers from HL. The public WRTVDP path updates
; the corresponding RAM shadows for every register.
write_vdp_register_block:
                ld c,0
                ld d,8
write_vdp_registers:
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
                ld a,(RG1SAV)
                and #e7                         ; preserve sprite size/magnify
                or #50                         ; M1 selects text, display on
                push af
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
                pop af
                ld b,a
                ld c,1
                jp wrtvdp

; SCREEN 1: 32x24 text/tiles. This first slice supplies the project font,
; clears the name and color tables, and hides sprites.
init32:
                ld a,(RG1SAV)
                and #e7                         ; preserve sprite size/magnify
                or #40                         ; display on
                push af
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
                pop af
                ld b,a
                ld c,1
                jp wrtvdp

; SCREEN 2: Graphics II with the standard three copies of pattern indices in
; the name table. Clear the bitmap and select white over black for every
; eight-pixel colour cell so callers begin with deterministic graphics VRAM.
initgrp:
                ld a,(RG1SAV)
                and #e7                         ; preserve sprite size/magnify
                or #40                         ; display on
                push af
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
                pop af
                ld b,a
                ld c,1
                jp wrtvdp

; $0078 SETTXT: switch the live VDP to 40-column text (Screen 0). Unlike
; INITXT, the name/pattern tables and the font are left as they are; only the
; mode registers, the screen-mode work byte, the line length, and the cursor
; change. The register block and R1 shadow formula match INITXT.
settxt:
                ld a,(RG1SAV)
                and #e7                         ; preserve sprite size/magnify
                or #50
                push af
                ld hl,text40_vdp_registers
                call write_vdp_register_block
                xor a
                ld (SCRMOD),a
                ld a,(LINL40)
                ld (LINLEN),a
                ld a,1
                ld (CSRY),a
                ld (CSRX),a
                pop af
                ld b,a
                ld c,1
                jp wrtvdp

; $007B SETT32: switch the live VDP to 32-column Screen 1.
sett32:
                ld a,(RG1SAV)
                and #e7                         ; preserve sprite size/magnify
                or #40
                push af
                ld hl,text32_vdp_registers
                call write_vdp_register_block
                ld a,1
                ld (SCRMOD),a
                ld a,(LINL32)
                ld (LINLEN),a
                ld a,1
                ld (CSRY),a
                ld (CSRX),a
                pop af
                ld b,a
                ld c,1
                jp wrtvdp

; $007E SETGRP: switch the live VDP to Graphics II (Screen 2).
setgrp:
                ld a,(RG1SAV)
                and #e7                         ; preserve sprite size/magnify
                or #40
                push af
                ld hl,graphics2_vdp_registers
                call write_vdp_register_block
                ld a,2
                ld (SCRMOD),a
                ld a,(LINL32)
                ld (LINLEN),a
                ld a,1
                ld (CSRY),a
                ld (CSRX),a
                pop af
                ld b,a
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
                cp #09
                jp z,chput_tab
                cp #0b
                jp z,chput_cursor_up
                cp #0c
                jp z,chput_form_feed
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

; Clear the current screen and home the cursor. Text modes clear their name
; table with spaces; Graphics II clears the pattern and colour planes so the
; visible bitmap empties to the background; multicolor clears its colour table.
cls:
                push hl
                ld a,(SCRMOD)
                cp 1
                jr z,cls_screen1
                cp 2
                jr z,cls_screen2
                cp 3
                jr z,cls_screen3
                ld hl,#0000
                ld bc,960
                jr cls_text_fill
cls_screen1:
                ld hl,#1800
                ld bc,768
cls_text_fill:
                ld a,#20
                call filvrm
                jr cls_home
cls_screen2:
                ld hl,#0000
                ld bc,#1800
                xor a
                call filvrm
                ld hl,#2000
                ld bc,#1800
                ld a,(BAKCLR)
                call filvrm
                jr cls_home
cls_screen3:
                ld a,(BAKCLR)
                and #0f
                ld b,a
                rlca
                rlca
                rlca
                rlca
                or b
                ld hl,(NAMBAS)
                ld bc,768
                call filvrm
cls_home:
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

; Cursor movement within the current text width and row count. The plain
; variants stop at the edges; the scrolling variants (TUPC/TDOWNC) move the
; text when the cursor is already on the boundary row. Only the cursor
; work-area variables and AF change.
rightc:
                ld a,(LINLEN)
                ld b,a
                ld a,(CSRX)
                cp b
                ret nc                          ; already at the right edge
                inc a
                ld (CSRX),a
                ret
leftc:
                ld a,(CSRX)
                cp 1
                ret z                           ; already at the left edge
                dec a
                ld (CSRX),a
                ret
upc:
                ld a,(CSRY)
                cp 1
                ret z                           ; already at the top
                dec a
                ld (CSRY),a
                ret
downc:
                ld a,(CRTCNT)
                ld b,a
                ld a,(CSRY)
                cp b
                ret nc                          ; already at the bottom
                inc a
                ld (CSRY),a
                ret
tupc:
                ld a,(CSRY)
                cp 1
                jr z,tupc_scroll
                dec a
                ld (CSRY),a
                ret
tupc_scroll:
                jp console_scroll_down
tdownc:
                ld a,(CRTCNT)
                ld b,a
                ld a,(CSRY)
                cp b
                jr z,tdownc_scroll
                inc a
                ld (CSRY),a
                ret
tdownc_scroll:
                jp console_scroll

; Move the text one row downward for TUPC at the top row: rows 1..N-1 copy to
; 2..N (from the last row first, so the overlap is safe), then row 1 blanks.
; Mirrors console_scroll for each Screen 0/1/2 layout.
console_scroll_down:
                ld a,(SCRMOD)
                cp 2
                jr z,console_scroll_down_screen2
                cp 1
                jr z,console_scroll_down_screen1
                ld hl,#0397                    ; Screen 0 row 23 end
                ld de,#03bf                    ; Screen 0 row 24 end
                ld bc,920                      ; 23 rows * 40 columns
                call console_scroll_copy_back
                ld hl,#0000                    ; Screen 0 row 1
                ld bc,40
                jr console_scroll_down_clear_text
console_scroll_down_screen1:
                ld hl,#1adf                    ; Screen 1 row 23 end
                ld de,#1aff                    ; Screen 1 row 24 end
                ld bc,736                      ; 23 rows * 32 columns
                call console_scroll_copy_back
                ld hl,#1800                    ; Screen 1 row 1
                ld bc,32
console_scroll_down_clear_text:
                ld a,#20
                jp filvrm
console_scroll_down_screen2:
                ld hl,#16ff                    ; pattern row 23 end
                ld de,#17ff                    ; pattern row 24 end
                ld bc,#1700                    ; 23 pattern rows
                call console_scroll_copy_back
                ld hl,#36ff                    ; colour row 23 end
                ld de,#37ff                    ; colour row 24 end
                ld bc,#1700                    ; 23 colour rows
                call console_scroll_copy_back
                ld hl,#0000                    ; blank pattern row 1
                ld bc,#0100
                xor a
                call filvrm
                ld hl,#2000                    ; reset its colour row
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

; Copy BC bytes from the source at (HL - BC + 1) to the destination at
; (DE - BC + 1), walking backward so a downward scroll can overlap safely.
console_scroll_copy_back:
                call rdvrm
                ex de,hl
                call wrtvrm
                ex de,hl
                dec hl
                dec de
                dec bc
                ld a,b
                or c
                jr nz,console_scroll_copy_back
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
                jp filvrm_impl

; Nextor 2.1 calls the original MSX BIOS keyboard decoder at this undocumented
; address while distinguishing Russian and international keyboards. KILBUF is
; called first, so queue a non-"J" marker to select the international layout.
                defs #0d89-$,#ff
nextor_keyboard_layout_probe:
                push af
                push bc
                push de
                push hl
                ld a,"N"
                call keyboard_buffer_put
                pop hl
                pop de
                pop bc
                pop af
                ret

; Renderers live after the fixed Nextor 0D89h compatibility entry so changes
; to visual asset handling cannot move that published address. ZX0 expansion
; uses C000h-D7FFh as transient storage; cartridge and disk boot paths may
; overwrite the buffer after the startup/menu upload has completed.
cold_boot_render_logo:
                ld hl,logo_pattern_zx0
                ld de,ASSET_BUFFER
                call dzx0_standard
                xor a
                out (VDP_CONTROL),a
                ld a,#40
                out (VDP_CONTROL),a
                ld hl,ASSET_BUFFER
                ld d,24
                ld c,VDP_DATA
cold_boot_render_logo_pattern_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_render_logo_pattern_block

                ld hl,logo_name_zx0
                ld de,ASSET_BUFFER
                call dzx0_standard
                ld hl,ASSET_BUFFER
                ld d,3
                ld c,VDP_DATA
cold_boot_render_logo_name_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_render_logo_name_block
                ld a,#d0                      ; hide all sprites at 1B00h
                out (VDP_DATA),a

                ld hl,logo_color_zx0
                ld de,ASSET_BUFFER
                call dzx0_standard
                xor a
                out (VDP_CONTROL),a
                ld a,#60
                out (VDP_CONTROL),a
                ld hl,ASSET_BUFFER
                ld d,24
                ld c,VDP_DATA
cold_boot_render_logo_color_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_render_logo_color_block
                ret

cold_boot_render_options:
                di                              ; VDP control pairs must be atomic
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

                xor a
                out (VDP_CONTROL),a
                ld a,#40
                out (VDP_CONTROL),a
                ld hl,boot_font
                ld d,8
                ld c,VDP_DATA
cold_boot_render_options_font_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_render_options_font_block
                xor a
                out (VDP_CONTROL),a
                ld a,#58
                out (VDP_CONTROL),a
                ld a,(PAYLOAD_SLOT)
                cp #ff
                ld hl,options_name_ready_zx0
                jr nz,cold_boot_render_options_name_selected
                ld hl,options_name_missing_zx0
cold_boot_render_options_name_selected:
                ld de,ASSET_BUFFER
                call dzx0_standard
                ld hl,ASSET_BUFFER
                ld d,3
                ld c,VDP_DATA
cold_boot_render_options_name_block:
                ld b,0
                otir
                dec d
                jr nz,cold_boot_render_options_name_block

                xor a
                out (VDP_CONTROL),a
                ld a,#60
                out (VDP_CONTROL),a
                ld hl,options_color_zx0
                ld de,ASSET_BUFFER
                call dzx0_standard
                ld hl,ASSET_BUFFER
                ld b,32
                ld c,VDP_DATA
                otir
                ld a,#e0
                out (VDP_CONTROL),a
                ld a,#81
                out (VDP_CONTROL),a
                ei
                ret

cold_boot_select_internal_payload_impl:
                ld a,#ff
                ld (PAYLOAD_SLOT),a
                ld a,(BIOSSLT)
                ld (CART_SCAN_SLOT),a
                ld hl,#4000
                call rdslt
                cp 'R'
                jr nz,cold_boot_internal_payload_invalid
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                cp 'B'
                jr nz,cold_boot_internal_payload_invalid
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                cp 'C'
                jr nz,cold_boot_internal_payload_invalid
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                cp '1'
                jr nz,cold_boot_internal_payload_invalid
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                cp #10
                jr nz,cold_boot_internal_payload_invalid
                inc hl
                ld a,(CART_SCAN_SLOT)
                call rdslt
                cp #40
                jr nz,cold_boot_internal_payload_invalid
                ld a,(CART_SCAN_SLOT)
                ld (PAYLOAD_SLOT),a
                ld hl,#4010
                ld (PAYLOAD_ENTRY),hl
                ld hl,#f300
                ld (PAYLOAD_RAM_END),hl
                scf
                ret
cold_boot_internal_payload_invalid:
                or a
                ret

cold_boot_expand_internal_payload:
; Copy the compressed internal bank while the main ROM owns page 1, then map
; the contiguous RAM slot there and expand the exact standalone payload. This
; keeps the main-ROM addresses probed by storage kernels inert without making
; the BASIC implementation itself depend on a transformed binary.
                ld a,(BIOSSLT)
                ld h,#40
                call enaslt
                ld hl,embedded_basic_payload_zx0
                ld de,ASSET_BUFFER
                ld bc,embedded_basic_payload_zx0_end-embedded_basic_payload_zx0
                ldir
                ld a,(RAMAD0)
                ld h,#40
                call enaslt
                ld hl,ASSET_BUFFER
                ld de,#4000
                call dzx0_standard
; Fail closed if either the decompressed standalone header or descriptor is
; not the source-built RBP1 payload validated by the host build.
                ld hl,#4000
                ld a,(hl)
                cp 'A'
                jr nz,cold_boot_internal_expand_failed
                inc hl
                ld a,(hl)
                cp 'B'
                jr nz,cold_boot_internal_expand_failed
                ld hl,#7ff0
                ld a,(hl)
                cp 'R'
                jr nz,cold_boot_internal_expand_failed
                inc hl
                ld a,(hl)
                cp 'B'
                jr nz,cold_boot_internal_expand_failed
                inc hl
                ld a,(hl)
                cp 'P'
                jr nz,cold_boot_internal_expand_failed
                inc hl
                ld a,(hl)
                cp '1'
                jr nz,cold_boot_internal_expand_failed
                jp cold_boot_payload_mapped
cold_boot_internal_expand_failed:
                ld a,(BIOSSLT)
                ld h,#40
                call enaslt
                ld a,#ff
                ld (PAYLOAD_SLOT),a
                jp cold_boot_options

; Text control characters handled by CHPUT: tab, cursor up, and form feed.
chgclr:
                ld a,(SCRMOD)
                or a
                jr nz,chgclr_graphics
                ; Screen 0: R7 = (FORCLR << 4) | BAKCLR, so the text colour
                ; sits in the TC nibble and the backdrop in the BD nibble.
                ld a,(FORCLR)
                rlca
                rlca
                rlca
                rlca
                and #f0
                ld b,a
                ld a,(BAKCLR)
                and #0f
                or b
                ld b,a
                ld c,7
                call wrtvdp
                ret
chgclr_graphics:
                ; Screen 1/2/3: R7 carries only the border colour.
                ld a,(BDRCLR)
                ld b,a
                ld c,7
                call wrtvdp
                ld a,(SCRMOD)
                cp 1
                ret nz
                ; Screen 1: fill the 32-byte color table with
                ; (FORCLR << 4) | BAKCLR.
                ld a,(FORCLR)
                rlca
                rlca
                rlca
                rlca
                and #f0
                ld b,a
                ld a,(BAKCLR)
                and #0f
                or b
                ld hl,#2000
                ld bc,32
                jp filvrm

; They live here, after the fixed-address Nextor keyboard probe, so the probe
; stays at 0D89h while CHPUT above keeps its short branches.
chput_tab:
                ld a,(CSRX)
                and #f8
                add a,9
                ld (CSRX),a
                ld a,(LINLEN)
                inc a
                ld b,a
                ld a,(CSRX)
                cp b
                jr c,chput_tab_done
                ld a,1
                ld (CSRX),a
                jp chput_advance_line
chput_tab_done:
                jp chput_done
chput_cursor_up:
                ld a,(CSRY)
                cp 1
                jr z,chput_cursor_up_done
                dec a
                ld (CSRY),a
chput_cursor_up_done:
                jp chput_done
chput_form_feed:
                call cls
                jp chput_done

; Test whether Ctrl-STOP is held right now through the physical matrix.; $008D GRPPRT: print one character on the graphic screen at the current
; cursor position using the project font and FORCLR, then advance the cursor
; by one 8-pixel cell (wrapping at LINLEN). Carriage return and line feed
; move the cursor without printing; other control characters are ignored.
grpprt:
                push af
                push bc
                push de
                push hl
                ld e,a
                cp #0d
                jr z,grpprt_carriage_return
                cp #0a
                jr z,grpprt_line_feed
                cp #20
                jr c,grpprt_done
                call graphics_put_character
grpprt_advance_cursor:
                ld a,(CSRX)
                inc a
                ld b,a
                ld a,(LINLEN)
                inc a
                cp b
                ld a,b
                jr nz,grpprt_store_x
                ld a,1
                ld (CSRX),a
                jr grpprt_advance_line
grpprt_store_x:
                ld (CSRX),a
                jr grpprt_done
grpprt_carriage_return:
                ld a,1
                ld (CSRX),a
                jr grpprt_done
grpprt_line_feed:
grpprt_advance_line:
                ld a,(CSRY)
                inc a
                cp 25
                jr c,grpprt_store_y
                call console_scroll
                ld a,24
grpprt_store_y:
                ld (CSRY),a
grpprt_done:
                pop hl
                pop de
                pop bc
                pop af
                ret

; $0084 CALPAT: return the VRAM address of the pattern data for sprite number
; A. The offset is A*8 bytes for 8x8 sprites and A*32 for 16x16 sprites.
calpat:
                ld h,0
                ld l,a
                add hl,hl
                add hl,hl
                add hl,hl
                call gspsiz
                jr nc,calpat_add_base
                add hl,hl
                add hl,hl
calpat_add_base:
                ld de,(PATBAS)
                add hl,de
                ret

; $0087 CALATR: return the VRAM address of the four-byte sprite attribute
; entry for sprite number A.
calatr:
                ld hl,(ATRBAS)
                ld d,0
                ld e,a
                sla e
                rl d
                sla e
                rl d
                add hl,de
                ret

; $008A GSPSIZ: report the current sprite pattern size from the R1 shadow.
; A returns 8 for 8x8 sprites with carry clear or 32 for 16x16 sprites with
; carry set. The call is a query and must not change the live VDP or RG1SAV.
gspsiz:
                ld a,(RG1SAV)
                and #02                         ; also clears carry
                ld a,8
                ret z
                ld a,32
                scf
                ret

; $0069 CLRSPR: initialize all 32 sprites. Screen 0 has no sprites and returns.
; Otherwise the complete 2 KiB pattern table is cleared and every attribute is
; assigned Y = 209 (sprite mode 1) or 217 (sprite mode 2), X = 0, the next
; valid pattern number (step 1 for 8x8, step 4 for 16x16), and FORCLR.
clrspr:
                ld a,(SCRMOD)
                or a
                ret z
                cp 4
                ld a,#d1
                jr c,clrspr_y
                ld a,#d9
clrspr_y:
                ld d,a
                ld e,1
                ld a,(RG1SAV)
                bit 1,a
                jr z,clrspr_step_ready
                ld e,4
clrspr_step_ready:
                ld hl,(ATRBAS)
                ld b,32
                ld c,0
clrspr_attr_loop:
                ld a,d
                call wrtvrm
                inc hl
                xor a
                call wrtvrm
                inc hl
                ld a,c
                call wrtvrm
                inc hl
                ld a,(FORCLR)
                and #0f
                call wrtvrm
                inc hl
                ld a,c
                add a,e
                ld c,a
                djnz clrspr_attr_loop
                ld hl,(PATBAS)
                ld bc,#0800
                xor a
                call filvrm
                ret


; Carry is set when both keys are pressed. Preserve the caller's interrupt
; state: storage kernels call BREAKX immediately before interrupt-driven waits.
; The masked return values match the open C-BIOS behavior used by software
; which observes A in addition to carry.
breakx:
                ld a,7
                call snsmat
                and #10                         ; STOP (active-low), clears carry
                ret nz                          ; return A=10h when released
                ld a,6
                call snsmat
                and #02                         ; CTRL (active-low), clears carry
                ret nz                          ; return A=02h when released
                scf
                ret

; Consume a latched STOP/break event from INTFLG. Carry is set on a break so
; callers such as disk kernels and Nextor can abort. A break also discards
; pending keyboard input.
iscntc:
                di
                ld a,(INTFLG)
                or a
                jr z,iscntc_no_break
                xor a
                ld (INTFLG),a                   ; consume the event
                call kilbuf
                scf
                ei
                ret
iscntc_no_break:
                ei
                or a
                ret

; BASIC's break check shares ISCNTC's behavior.
ckcntc:
                jp iscntc

; Store keyboard input in BUFFER until Return or Ctrl-STOP. Echoed unless
; AUTFLG is set. On Return, carry is clear and B is the character count;
; on a break, carry is set. HL returns BUFFER-1 in both cases.
pinlin:
                xor a
                ld (AUTFLG),a
                jr pinlin_impl
inlin:
                ld a,1
                ld (AUTFLG),a
pinlin_impl:
                ld a,(CSRX)
                ld (INLIN_START_COL),a
                ld a,(CSRY)
                ld (INLIN_START_ROW),a
                ld hl,BUFFER
                ld b,0                          ; B = character count
                ld c,0                          ; C = cursor position
inlin_loop:
                push bc
                call breakx
                pop bc
                jp c,inlin_finish_break
                call chget
                ld (INLIN_TMP),a                ; keep the char across the checks
                cp #0d
                jp z,inlin_cr
                cp #08                          ; backspace
                jp z,inlin_backspace
                cp #7f                          ; delete under the cursor
                jp z,inlin_delete
                cp #1c                          ; cursor right
                jp z,inlin_cursor_right
                cp #1d                          ; cursor left
                jp z,inlin_cursor_left
                cp #0b                          ; home
                jp z,inlin_home
                cp #12                          ; insert toggle (always insert)
                jp z,inlin_loop
                cp #20
                jp c,inlin_loop                 ; other control chars ignored
                cp 127
                jp nc,inlin_loop
                ld a,b
                cp 255
                jp nc,inlin_loop                ; line full
                ld a,(INLIN_TMP)
                call inlin_insert
                jp inlin_loop
inlin_backspace:
                ld a,c
                or a
                jp z,inlin_loop                 ; at the start
                ld a,b
                sub c
                jr z,inlin_bs_shift_done        ; nothing after the cursor
                ld (INLIN_CNT),a                ; count = B - C
                ld a,c
inlin_bs_shift:
                push af
                ld hl,BUFFER
                ld d,0
                ld e,a
                add hl,de
                ld e,(hl)                       ; buf[A]
                dec hl
                ld (hl),e                       ; buf[A-1] = buf[A]
                pop af
                inc a
                ld hl,INLIN_CNT
                dec (hl)
                jr nz,inlin_bs_shift
inlin_bs_shift_done:
                dec c
                dec b
                call inlin_render
                jp inlin_loop
inlin_delete:
                ld a,c
                cp b
                jp nc,inlin_loop                ; nothing under the cursor
                ld a,b
                sub c
                dec a                           ; A = B - C - 1
                jr z,inlin_del_shift_done
                ld (INLIN_CNT),a                ; count = B - C - 1
                ld a,c
inlin_del_shift:
                push af
                ld hl,BUFFER
                ld d,0
                ld e,a
                add hl,de
                inc hl
                ld e,(hl)                       ; buf[A+1]
                dec hl
                ld (hl),e                       ; buf[A] = buf[A+1]
                pop af
                inc a
                ld hl,INLIN_CNT
                dec (hl)
                jr nz,inlin_del_shift
inlin_del_shift_done:
                dec b
                call inlin_render
                jp inlin_loop
inlin_cursor_left:
                ld a,c
                or a
                jp z,inlin_loop
                dec c
                ld a,(CSRX)
                dec a
                ld (CSRX),a
                jp inlin_loop
inlin_cursor_right:
                ld a,c
                cp b
                jp nc,inlin_loop
                inc c
                ld a,(CSRX)
                inc a
                ld (CSRX),a
                jp inlin_loop
inlin_home:
                xor a
                ld c,a
                ld a,(INLIN_START_COL)
                ld (CSRX),a
                jp inlin_loop
inlin_cr:
                ; terminate at the current length
                ld hl,BUFFER
                ld d,0
                ld e,b
                add hl,de
                ld (hl),#0d
                xor a                           ; carry clear
inlin_finish:
                ld hl,BUFFER
                dec hl
                ret
inlin_finish_break:
                scf                             ; carry set
                jr inlin_finish

; Insert A at the cursor: shift the tail right, store, advance B and C, and
; redraw the line.
inlin_insert:
                ld (INLIN_TMP),a
                ld a,b
                sub c
                jr z,inlin_insert_store         ; append at the end
                ld (INLIN_CNT),a                ; count = B - C (chars to shift)
                ld a,b
                dec a                           ; A = B - 1
inlin_insert_shift:
                ; buf[A+1] = buf[A]
                push af
                ld hl,BUFFER
                ld d,0
                ld e,a
                add hl,de
                ld e,(hl)
                inc hl
                ld (hl),e
                pop af
                dec a
                ld hl,INLIN_CNT
                dec (hl)
                jr nz,inlin_insert_shift
inlin_insert_store:
                ld hl,BUFFER
                ld d,0
                ld e,c
                add hl,de
                ld a,(INLIN_TMP)
                ld (hl),a                       ; buf[C] = char
                inc b
                inc c
                jr inlin_render

; Redraw the input line from the saved start position and place the cursor at
; start_col + C. With AUTFLG set (INLIN) nothing is displayed.
inlin_render:
                ld a,(AUTFLG)
                or a
                ret nz                          ; no echo for automatic input
                push bc
                ld a,(INLIN_START_ROW)
                ld l,a
                ld a,(INLIN_START_COL)
                ld h,a
                call posit
                ld a,b
                or a
                jr z,inlin_render_clear
                ld e,a
                ld hl,BUFFER
inlin_render_char:
                ld a,(hl)
                inc hl
                push de
                push hl
                call chput
                pop hl
                pop de
                dec e
                jr nz,inlin_render_char
inlin_render_clear:
                ld a,(CSRX)
                ld d,a
                ld a,(LINLEN)
                sub d
                inc a
                ld e,a
inlin_render_space:
                ld a,e
                or a
                jr z,inlin_render_pos
                push de
                ld a,#20
                call chput
                pop de
                dec e
                jr inlin_render_space
inlin_render_pos:
                ld a,(INLIN_START_COL)
                add a,c
                ld h,a
                ld a,(INLIN_START_ROW)
                ld l,a
                pop bc
                jp posit

; QINLIN displays "? " and then performs INLIN.
qinlin:
                push hl
                ld a,"?"
                call chput
                ld a,#20
                call chput
                pop hl
                jp inlin

; Generate a short audible tone on PSG channel A.
beep:
                push bc
                push de
                push hl
                xor a
                out (PSG_ADDRESS),a
                ld a,#9a
                out (PSG_WRITE),a               ; R0: tone period low
                ld a,1
                out (PSG_ADDRESS),a
                xor a
                out (PSG_WRITE),a               ; R1: period high
                ld a,8
                out (PSG_ADDRESS),a
                ld a,#0f
                out (PSG_WRITE),a               ; R8: channel A volume
                ld bc,#2000
beep_delay:
                dec bc
                ld a,b
                or c
                jr nz,beep_delay
                ld a,8
                out (PSG_ADDRESS),a
                xor a
                out (PSG_WRITE),a               ; silence
                pop hl
                pop de
                pop bc
                ret

; Fill FNKSTR with the ten default 16-byte function-key strings.
inifnk:
                ld hl,default_fnkstr
                ld de,FNKSTR
                ld bc,160
                ldir
                ret

; Show or hide the function keys depending on CNSDFG.
fnksb:
                ld a,(CNSDFG)
                or a
                jp nz,dspfnk
                jp erafnk

; Erase the function-key display and clear the display flag.  Write the last
; name-table row directly: routing the fill through CHPUT would move the
; caller's cursor to the bottom of the screen and scroll after the final
; space.  Programs such as BBC BASIC call ERAFNK immediately after INITXT and
; expect the homed cursor to remain intact for their sign-on banner.
erafnk:
                xor a
                ld (CNSDFG),a
                ld hl,(NAMBAS)
                ld a,(CRTCNT)
                dec a
                ld b,a
                ld a,(LINLEN)
                ld e,a
                ld d,0
erafnk_row_offset:
                add hl,de
                djnz erafnk_row_offset
                ld b,0
                ld c,e
                ld a,#20
                jp filvrm

; Display the function-key strings on the bottom line and set the display flag.
dspfnk:
                ld a,#ff
                ld (CNSDFG),a
                ld a,(CRTCNT)
                dec a
                ld l,a
                xor a
                ld h,a                          ; last row, column 0
                call posit
                ld ix,FNKSTR
                ld b,10                         ; ten keys
dspfnk_key:
                push bc
                ld c,16                         ; each string is 16 bytes
dspfnk_char:
                ld a,(ix)
                inc ix
                push bc
                call chput
                pop bc
                dec c
                jr nz,dspfnk_char
                pop bc
                djnz dspfnk_key
                ret

; Force the text mode and refresh the function-key display state.
totext:
                ld a,(LINLEN)
                cp 40
                jr z,totext_40
                call init32
                jr totext_refresh
totext_40:
                call initxt
totext_refresh:
                jp fnksb

; Ten default function-key strings, each 16 bytes, padded with spaces. The
; published defaults are BASIC-oriented; the strings are user-replaceable.
default_fnkstr:
                db "LIST",#0d
                defs 11,32
                db "RUN",#0d
                defs 12,32
                db "LOAD",#22,#0d
                defs 10,32
                db "SAVE",#22,#0d
                defs 10,32
                db "CONT",#0d
                defs 11,32
                db ",",#22,"LPT1:",#22,#0d
                defs 7,32
                db "TRON",#0d
                defs 11,32
                db "TROFF",#0d
                defs 10,32
                db "KEY LIST",#0d
                defs 7,32
                db "SCREEN 0",#0d
                defs 7,32
; Partial international-keyboard input. KEYINT records newly pressed matrix
; positions in the standard 40-byte circular buffer. The CAPS lock toggles
; letter case like the official BIOS; STOP latches INTFLG for BREAKX/ISCNTC,
; and held keys auto-repeat through SCNCNT/REPCNT. Dead keys and the audible
; key click remain later M3 work.
keyboard_scan:
                ld hl,SCNCNT
                dec (hl)                        ; auto-repeat timing
                jr nz,keyboard_scan_press
                ld a,(REPCNT)
                ld (SCNCNT),a
                call keyboard_repeat
keyboard_scan_press:
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
                jr z,keyboard_scan_modifier
                ld a,c
                or a
                jr z,keyboard_scan_next
                ld a,(REPCNT)
                ld (SCNCNT),a                   ; new press restarts the repeat
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

; Modifier-row edges never reach the buffer, but a new CAPS press toggles the
; lock state and the keyboard LED, matching the official BIOS.
keyboard_scan_modifier:
                bit 3,c                         ; CAPS key edge?
                jr z,keyboard_scan_next
                ld a,(REPCNT)
                ld (SCNCNT),a                   ; CAPS restarts the repeat
                ld a,(CAPST)
                cpl
                ld (CAPST),a
                xor #01                         ; the lamp flag is the inverse
                                                ; of the lock (A = 0 lamps on)
                call chgcap                     ; keep the lamp in lockstep
                jr keyboard_scan_next

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
                ld a,(CLIKSW)
                or a
                jr z,keyboard_enqueue_next
                ld a,2                          ; click for a couple of frames
                ld (CLICKCNT),a
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
                jp z,keyboard_translate_row7
                cp 8
                jp z,keyboard_translate_row8
                xor a
                ld (DEADST),a                   ; unsupported rows clear the accent
                ret
keyboard_translate_printable:
                ; The dedicated dead-key key sits between the "/" and "A" keys
                ; (matrix row 2, column 5); it latches DEADST instead of emitting.
                ld a,b
                cp 2
                jr nz,keyboard_translate_lookup
                ld a,e
                cp 5
                jp z,keyboard_deadkey_key
keyboard_translate_lookup:
                ld a,b
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
; CAPS flips letter case, so Shift and the lock invert each other exactly
; like the official BIOS. Ctrl reduces letters to control codes in any case.
keyboard_translate_table:
                add hl,bc
                ld a,(hl)
                bit 1,d
                jr z,keyboard_translate_ctrl
                ld c,a                          ; no Ctrl: apply CAPS
                and #df
                cp 'A'
                jr c,keyboard_translate_keep
                cp 'Z'+1
                jr nc,keyboard_translate_keep
                ld a,(CAPST)
                or a
                jr z,keyboard_translate_keep
                ld a,c
                xor #20
                ld c,a
keyboard_translate_keep:
                ld a,c
                ; Apply any pending accent to this printable character.
                ld (DEADKEY_TMP),a
                ld a,(DEADST)
                or a
                jr z,keyboard_deadkey_clear
                ld a,(DEADKEY_TMP)
                call keyboard_deadkey_combine
                or a
                jr nz,keyboard_deadkey_combined
keyboard_deadkey_clear:
                xor a
                ld (DEADST),a
                ld a,(DEADKEY_TMP)
                ret
keyboard_deadkey_combined:
                push af
                xor a
                ld (DEADST),a
                pop af
                ret

; The dead key latches DEADST like the official international BIOS:
; 1 = grave, 2 = acute (Shift), 3 = circumflex (Code), 4 = umlaut
; (Shift+Code). Nothing is emitted; the next combinable letter combines.
keyboard_deadkey_key:
                ld a,1
                bit 0,d                         ; Shift held? (active-low)
                jr nz,keyboard_deadkey_code
                inc a
keyboard_deadkey_code:
                bit 4,d                         ; Code held? (active-low)
                jr nz,keyboard_deadkey_latch
                add a,2
keyboard_deadkey_latch:
                ld (DEADST),a
                xor a
                ret

; A = a letter. Return the accented code for the pending DEADST accent, or 0
; if the letter cannot be combined. Uses the 4x26 accent table.
keyboard_deadkey_combine:
                and #df                         ; fold to uppercase
                sub 'A'
                cp 26
                jr nc,keyboard_deadkey_not_letter
                ld e,a                          ; E = letter index
                ld d,0
                ld a,(DEADST)
                or a
                jr z,keyboard_deadkey_not_letter
                dec a                           ; 0-3
                ld hl,deadkey_table
                add hl,de
                or a
                jr z,keyboard_deadkey_table_done
keyboard_deadkey_add26:
                ld de,26
                add hl,de
                dec a
                jr nz,keyboard_deadkey_add26
keyboard_deadkey_table_done:
                ld a,(hl)
                ret
keyboard_deadkey_not_letter:
                xor a
                ret

keyboard_translate_ctrl:
                ld c,a
                and #df                         ; letters fold to uppercase
                cp 'A'
                jr c,keyboard_deadkey_clear_ctrl
                cp 'Z'+1
                jr nc,keyboard_deadkey_clear_ctrl
                xor a
                ld (DEADST),a                   ; Ctrl clears a pending accent
                ld a,c
                and #1f                         ; Ctrl+A through Ctrl+Z
                ret
keyboard_deadkey_clear_ctrl:
                xor a
                ld (DEADST),a
                ld a,c
                ret
keyboard_translate_row7:
                ; bit 4 is STOP: latch a break instead of enqueuing. Ctrl-STOP
                ; sets INTFLG = 3; STOP alone sets INTFLG = 4.
                ld a,e
                cp 4
                jr nz,keyboard_translate_row7_key
                bit 1,d                         ; CTRL held? (active-low)
                ld a,3
                jr z,keyboard_translate_stop
                ld a,4
keyboard_translate_stop:
                ld (INTFLG),a
                xor a
                ld (DEADST),a                   ; a break clears pending accent
                ld hl,KEYBUF                    ; a break discards pending input
                ld (PUTPNT),hl
                ld (GETPNT),hl
                xor a
                ret
keyboard_translate_row7_key:
                ld hl,keymap_row7
                jr keyboard_translate_special
keyboard_translate_row8:
                ld hl,keymap_row8
keyboard_translate_special:
                ld d,0
                add hl,de
                ld a,(hl)
                push af
                xor a
                ld (DEADST),a                   ; editing keys clear the accent
                pop af
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

; Re-enqueue the first key held across both the previous and current scan,
; matching the auto-repeat interval. Modifiers and STOP never repeat.
keyboard_repeat:
                ld b,0
                ld hl,OLDKEY
keyboard_repeat_row:
                ld a,b
                call snsmat
                cpl                             ; currently pressed bits
                ld c,a
                ld a,(hl)                       ; previous row (active-low)
                cpl
                and c                           ; held across both scans
                jr nz,keyboard_repeat_found
keyboard_repeat_next_row:
                inc hl
                inc b
                ld a,b
                cp 9
                jr nz,keyboard_repeat_row
                ret
keyboard_repeat_found:
                ld a,b
                cp 6
                jr z,keyboard_repeat_next_row
                push bc
                ld a,6
                call snsmat
                pop bc
                ld d,a                          ; modifier row
                ld a,b
                call snsmat
                cpl
                ld c,a
                ld a,(hl)
                cpl
                and c                           ; held bits (recomputed)
                ld c,a
                ld e,0
keyboard_repeat_bit:
                srl c
                jr nc,keyboard_repeat_next_bit
                ld a,b
                cp 7
                jr nz,keyboard_repeat_translate
                ld a,e
                cp 4
                jr z,keyboard_repeat_next_bit   ; STOP does not repeat
keyboard_repeat_translate:
                push bc
                push de
                call keyboard_translate
                or a
                call nz,keyboard_buffer_put
                pop de
                pop bc
                ret
keyboard_repeat_next_bit:
                inc e
                ld a,e
                cp 8
                jr nz,keyboard_repeat_bit
                jr keyboard_repeat_next_row

; Drive the 1-bit click line for a few frames after a key press when CLIKSW is
; on. The PPI port-C bit 7 feeds the speaker through the same MIX as the PSG.
keyboard_click_update:
                ld a,(CLICKCNT)
                or a
                jr z,keyboard_click_off
                dec a
                ld (CLICKCNT),a
                in a,(PPI_CONTROL_C)
                or #80
                out (PPI_CONTROL_C),a           ; click high
                ret
keyboard_click_off:
                in a,(PPI_CONTROL_C)
                and #7f
                out (PPI_CONTROL_C),a           ; click low
                ret

; Set the CAPS lamp from the input flag and set the key-click switch from the
; input flag. Both entries follow the documented miscellany contract: only AF
; changes and the LED/click 1-bit lines match the value in A. RainBIOS drives
; the lamp on keyboard PPI port-C bit 6 (0 = on, 1 = off, the same convention
; set by the cold-boot `or #40` clear) and the click on port-C bit 7, so the
; CAPS key handler below routes through chgcap to keep the two in lockstep.
;
; CHGCAP, 0132h: A = 00 turns the CAP lamp on, non-00 turns it off.
; CHGSND, 0135h: A = 00 turns the 1-bit click sound off, non-00 turns it on
;                (gated through CLIKSW so KEYINT only drives the click line
;                while the switch is on).
chgcap:
                push de                         ; preserve DE across the port RMW
                push af                         ; preserve the caller's input flag
                in a,(PPI_CONTROL_C)
                and #bf                         ; clear bit 6 (lamp on)
                ld e,a
                pop af                          ; restore the caller's AF
                or a
                ld a,e                          ; base image (bit 6 clear)
                jr z,chgcap_write
                or #40                          ; lamp off: set bit 6
chgcap_write:
                out (PPI_CONTROL_C),a
                pop de
                ret

chgsnd:
                ld (CLIKSW),a
                ret
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


; Test for a standard "CD" SUB-ROM without publishing EXBRSA: doing so would
; advertise the still-unimplemented EXTROM entry. E holds the current slot ID
; because RDSLT and the expansion test preserve it.
v9938_subrom_present:
                ld e,0
v9938_subrom_scan_slot:
                ld a,e
                bit 7,a
                jr nz,v9938_subrom_scan_ready
                cp 4
                jr nc,v9938_subrom_not_found
                or #80
                call expanded_slot_check
                jr nz,v9938_subrom_scan_expanded
                and #03
v9938_subrom_scan_expanded:
                ld e,a
v9938_subrom_scan_ready:
                ld hl,0
                ld a,e
                call rdslt
                cp 'C'
                jr nz,v9938_subrom_scan_next
                inc hl
                ld a,e
                call rdslt
                cp 'D'
                jr z,v9938_subrom_found
v9938_subrom_scan_next:
                ld a,e
                bit 7,a
                jr z,v9938_subrom_next_primary
                and #0c
                cp #0c
                jr z,v9938_subrom_expanded_done
                ld a,e
                add a,4
                ld e,a
                jr v9938_subrom_scan_slot
v9938_subrom_expanded_done:
                ld a,e
                and #03
v9938_subrom_next_primary:
                inc a
                ld e,a
                jr v9938_subrom_scan_slot
v9938_subrom_found:
                xor a                           ; Z: V9938-capable system found
                ret
v9938_subrom_not_found:
                ld a,1                          ; NZ: retain the MSX1 failure path
                or a
                ret

; The public ROM identifies as MSX1, so WRTVDP retains its R0-R7 shadow
; behavior. The guarded Screen 7 path uses a separate helper for R8-R23.
wrtvdp_impl:
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

wrtvdp_v9938:
                push af
                push hl
                ld a,c
                sub 8
                add a,RG8SAV&255
                ld l,a
                ld h,#ff
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

IFDEF MSX2
; MSX2 build only. A live V9938 is detected with the standard MSX2 extended
; BIOS probe: scan every primary and expanded slot for the "CD" signature that
; MSX2 SUB-ROMs carry at their start (the same probe used for the guarded
; Screen 7 handoff). When found, publish the SUB-ROM slot in EXBRSA and load
; the V9938 R8-R23 shadow baseline through the extended-register WRTVDP path.
bootstrap_msx2:
                call v9938_subrom_present
                jr nz,bootstrap_msx2_no_v9938
                ld a,e
                ld (EXBRSA),a
                ld hl,msx2_vdp_registers_8_23
                ld c,8
                ld d,16
bootstrap_msx2_register_loop:
                ld b,(hl)
                call wrtvdp_v9938
                inc hl
                inc c
                dec d
                jr nz,bootstrap_msx2_register_loop
bootstrap_msx2_no_v9938:
                ret
ENDIF

; $015C SUBROM: call a routine in the SUB-ROM, documented as `push IX` then
; `jp SUBROM`. The pushed value restores IX after the call, and the final RET
; returns to the caller of the push sequence, mirroring the reference ABI.
subrom:
                call extrom
                pop ix
                ret

; $015F EXTROM: call the SUB-ROM routine at IX through CALSLT using the slot
; published in EXBRSA. The caller's alternate registers and IY are preserved,
; the SUB-ROM routine receives the caller's normal registers, and the
; interrupt state active at entry is restored on return (CALSLT disables
; interrupts during the transfer).
extrom:
                ex af,af'
                exx
                push af                         ; save alternate AF
                push bc                         ; save alternate BC
                push de                         ; save alternate DE
                push hl                         ; save alternate HL
                ld a,i
                push af                         ; IFF2 snapshot in P/V
                exx
                push iy
                ld a,(EXBRSA)
                push af
                pop iy                          ; IYH = SUB-ROM slot ID
                ex af,af'
                call calslt
                pop iy
                ex af,af'
                exx
                pop af
                jp po,extrom_restore_interrupts
                ei
extrom_restore_interrupts:
                pop hl
                pop de
                pop bc
                pop af
                exx
                ex af,af'
                ret

; $0162 CHKSLZ: scan primary and expanded slots for the standard "CD" SUB-ROM
; signature and republish the discovered slot in EXBRSA. Carry is set when a
; SUB-ROM is found and cleared otherwise, matching the documented contract.
chkslz:
                call v9938_subrom_present
                jr nz,chkslz_not_found
                ld a,e
                ld (EXBRSA),a
                scf
                ret
chkslz_not_found:
                xor a
                ld (EXBRSA),a
                or a                            ; clear carry
                ret

; Partial Screen 7 handoff for software that runs this MSX1 ROM on MSX2
; hardware. A discovered SUB-ROM is used only as the V9938 capability guard;
; RainBIOS programs the documented register interface directly and leaves the
; broader MSX2 MAIN/SUB-ROM ABI to M5.
initv9938_screen7:
                call v9938_subrom_present
                jp nz,unsupported_call
                call disscr
                ld hl,screen7_vdp_registers_0_6
                ld c,0
                ld d,7
                call write_vdp_registers

                ld a,(FORCLR)
                rlca
                rlca
                rlca
                rlca
                and #f0
                ld b,a
                ld a,(BDRCLR)
                and #0f
                or b
                ld b,a
                ld c,7
                call wrtvdp

                ld b,#08
                ld c,8
                call wrtvdp_v9938
                ld a,(RG9SAV)
                or #80                         ; 212 display lines
                ld b,a
                ld c,9
                call wrtvdp_v9938

                ld hl,screen7_vdp_registers_10_23
                ld c,10
                ld d,14
initv9938_screen7_register_loop:
                ld b,(hl)
                call wrtvdp_v9938
                inc hl
                inc c
                dec d
                jr nz,initv9938_screen7_register_loop
                ld a,7
                ld (SCRMOD),a
                jp enascr

filvrm_impl:
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

cold_boot_init_disk_impl:
                call cold_boot_valid_payload
                ret c                           ; validated payload keeps the menu
                ld a,(H_RUNC)
                cp #c9
                ret z
                 call cold_boot_select_sd_card
                 jr nc,cold_boot_init_disk_kernel
                 ld a,1
                 ld (DISK_PRESENT),a
                 call cold_boot_phyd_boot
                 ret
cold_boot_init_disk_kernel:
                 ld a,1
                 ld (DISK_PRESENT),a
                 ld a,(DEVICE)
                or a
                jr nz,cold_boot_init_disk_device_ready
                inc a
                ld (DEVICE),a
cold_boot_init_disk_device_ready:
                xor a
                ld (DISK_SETUP),a
                call H_RUNC
                ret

; The SD Mapper driver exposes both physical cards as Nextor drives. Let the
; user choose when both are mounted, then seed Nextor's initialized boot-drive
; byte before H.RUNC performs its non-returning cleanup and boot pass. Other
; disk kernels and one-card setups retain their normal automatic selection.
cold_boot_select_sd_card:
                ld a,(NEXTOR_DOS_VERSION)
                cp #99
                jp nz,cold_boot_select_sd_not_mapper
                ld a,(NEXTOR_VERSION)
                or a
                jp z,cold_boot_select_sd_not_mapper
                ld a,(IDE_SLOT)
                bit 7,a
                jp z,cold_boot_select_sd_not_mapper
                ld h,#40
                call enaslt
                call sd_mapper_probe
                jr c,cold_boot_select_sd_restore_none
                ld b,0
                ld a,1
                ld (SD_MAPPER_SELECT),a
                ld a,(SD_MAPPER_SELECT)
                bit 1,a
                jr nz,cold_boot_select_sd_check_b
                set 0,b
cold_boot_select_sd_check_b:
                ld a,2
                ld (SD_MAPPER_SELECT),a
                ld a,(SD_MAPPER_SELECT)
                bit 1,a
                jr nz,cold_boot_select_sd_restore
                set 1,b
cold_boot_select_sd_restore:
                ld a,b
                push af
                xor a
                ld (SD_MAPPER_SELECT),a
                ld (SD_MAPPER_BANK),a
                ld a,(BIOSSLT)
                ld h,#40
                call enaslt
                pop af
                cp 4
                jr z,cold_boot_select_sd_not_mapper
                or a
                jr z,cold_boot_select_sd_no_media
                cp 3
                jr nz,cold_boot_select_sd_not_mapper
                ld a,(DEVICE)
                cp 1
                jr nz,cold_boot_select_sd_not_mapper
                ld a,(H_PHYD)
                cp #37
                jr nz,cold_boot_select_sd_not_mapper
                ld hl,sd_boot_choice_message
cold_boot_select_sd_message:
                ld a,(hl)
                or a
                jr z,cold_boot_select_sd_input
                call chput
                inc hl
                jr cold_boot_select_sd_message
cold_boot_select_sd_input:
                call chget
                and #df
                cp 'A'
                jr z,cold_boot_select_sd_a
                cp 'B'
                jr nz,cold_boot_select_sd_input
                ld a,2
                jr cold_boot_select_sd_selected
cold_boot_select_sd_a:
                ld a,1
cold_boot_select_sd_selected:
                ld (NEXTOR_BOOT_DRIVE),a
                ld a,#0d
                call chput
                ld a,#0a
                call chput
                or a
                ret
cold_boot_select_sd_restore_none:
                ld b,4
                jr cold_boot_select_sd_restore
cold_boot_select_sd_not_mapper:
                or a
                ret
cold_boot_select_sd_no_media:
                ld a,(DEVICE)
                cp 1
                jr nz,cold_boot_select_sd_not_mapper
                scf
                ret

; If an empty SD Mapper displaced another disk kernel's H.RUNC hook, retain its
; standard H.PHYD path. This is the same cold-boot sector contract used by the
; production NMS 8250 disk ROM and returns when drive A is not bootable.
cold_boot_phyd_boot:
                ld hl,#c000
                ld de,0
                ld bc,#01f9
                xor a
                call H_PHYD
                ret c
                ld a,(#c000)
                cp #eb
                jr z,cold_boot_phyd_go
                cp #e9
                ret nz
cold_boot_phyd_go:
                ld sp,#e000
                xor a
                scf
                ld hl,#f323                   ; HL = DISKVE (error-handler pointer)
                ld de,0                       ; DE = ENAKRN entry (no kernel yet)
                jp #c01e

; PAYLOAD_SLOT shares the pre-DOS scratch area and can be overwritten by a disk
; kernel allocation. Recheck the immutable descriptor before allowing a payload
; to suppress H.RUNC. Carry is set only for the RBP1 magic validated earlier.
cold_boot_valid_payload:
                ld a,(PAYLOAD_SLOT)
                cp #ff
                jr z,cold_boot_valid_payload_no
                ld e,a
                ld hl,#7ff0
                ld a,e
                call rdslt
                cp 'R'
                jr nz,cold_boot_valid_payload_no
                inc hl
                ld a,e
                call rdslt
                cp 'B'
                jr nz,cold_boot_valid_payload_no
                inc hl
                ld a,e
                call rdslt
                cp 'P'
                jr nz,cold_boot_valid_payload_no
                inc hl
                ld a,e
                call rdslt
                cp '1'
                jr nz,cold_boot_valid_payload_no
                scf
                ret
cold_boot_valid_payload_no:
                or a
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

; Initialize the PSG hardware registers atomically. The public entry enables
; interrupts on return; cold boot calls the private body while it still owns a
; DI section. R7 keeps port A as input and port B as output; R15 makes both
; trigger lines inputs, holds both mouse strobes low, selects connector 1, and
; leaves the active-low Kana LED off. PLAY statement work areas remain pending.
gicini:
                call gicini_impl
                ei
                ret
gicini_impl:
                di
                ld hl,psg_initial_registers
                ld c,0
gicini_register:
                ld a,c
                out (PSG_ADDRESS),a
                ld a,(hl)
                out (PSG_WRITE),a
                inc hl
                inc c
                ld a,c
                cp 16
                jr nz,gicini_register
                ; Initialize the PLAY statement work area: point QUEUES at the
                ; queue table, mark the interpreter free, and clear the voice
                ; static data and the three voice queues. MUSICF/PLYCNT and the
                ; queue counters start at zero.
                ld hl,QUETAB
                ld (QUEUES),hl
                ld a,#ff
                ld (FRCNEW),a
                ld hl,PLAY_AREA
                xor a
                ld (hl),a
                ld de,PLAY_AREA+1
                ld bc,PLAY_AREA_END-PLAY_AREA-1
                ldir
                ld hl,QUETAB
                xor a
                ld (hl),a
                ld de,QUETAB+1
                ld bc,QUEUE_END-QUETAB-1
                ldir
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
                ld a,CAS_MOTOR_FRAMES
                ld (CAS_MOTOR_TIMER),a
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
                ld a,1
                ld (CAS_MOTOR),a
                ld a,CAS_MOTOR_FRAMES
                ld (CAS_MOTOR_TIMER),a
                ret
stmotr_off:
                xor a
                ld (CAS_MOTOR),a
                ld (CAS_MOTOR_TIMER),a
                ld a,#09
                out (PPI_CONTROL),a
                ret
stmotr_toggle:
                in a,(PPI_CONTROL_C)
                xor #10
                out (PPI_CONTROL_C),a
                and #10
                jr z,stmotr_toggle_off
                ld a,1
                ld (CAS_MOTOR),a
                ld a,CAS_MOTOR_FRAMES
                ld (CAS_MOTOR_TIMER),a
                ret
stmotr_toggle_off:
                xor a
                ld (CAS_MOTOR),a
                ld (CAS_MOTOR_TIMER),a
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

; Detect the memory-mapper segment count and publish it in MAPPER_SEGMENTS.
; Page 2 is probed: map segment 0, write a marker, then test each power of two.
; The smallest power of two that maps back to segment 0 is the segment count,
; because the mapper register masks the value with segments-1. Machines without
; a mapper ignore the reserved ports, so every probe keeps the marker and the
; count is one (the plain 64 KiB). The 3,2,1,0 baseline is restored afterward.
bootstrap_size_mapper:
                ld a,1
                ld (MAPPER_SEGMENTS),a
                xor a
                out (MAPPER_PAGE2),a           ; segment 0 in page 2
                ld a,#5a
                ld (#8000),a                   ; marker
                ld b,1
bootstrap_size_bit:
                ld a,b
                out (MAPPER_PAGE2),a
                ld a,(#8000)
                cp #5a
                jr z,bootstrap_size_found
                ld a,b
                add a,a
                ld b,a
                jr nc,bootstrap_size_bit
                ld a,128                       ; 4 MiB maps cap at 128 segments
                ld (MAPPER_SEGMENTS),a
                jr bootstrap_size_restore
bootstrap_size_found:
                ld a,b
                ld (MAPPER_SEGMENTS),a
bootstrap_size_restore:
                ld a,3
                out (MAPPER_PAGE0),a
                ld a,2
                out (MAPPER_PAGE1),a
                ld a,1
                out (MAPPER_PAGE2),a
                xor a
                out (MAPPER_PAGE3),a
                xor a
                ld (#8000),a                   ; clear the marker
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
                push de
                call RDPRIM
                ld b,e
                pop de
                ld a,b
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
                call RDPRIM
                ld a,e
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
                call WRPRIM
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
                call WRPRIM
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

; Inter-slot call. Primary and expanded targets in IX are accepted in every
; page. Page-1/page-2 targets and page-3 targets that already occupy page 3
; leave this page-0 routine and the page-3 stack visible. Page-0 targets switch
; page 0 through the page-3 CLPRIM helper because the PPI write hides this page;
; page-3 targets in another slot get a return frame installed in their own
; page-3 RAM. Restoration state is kept in the call's stack frame because the
; called routine may destroy every normal register.
calslt:
                di
                ex af,af'
                exx
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
                jr z,calslt_page_supported
                cp #c0
                jp z,calslt_page3_primary

; Page-0 primary target. The PPI write would hide this page-0 code, so CLPRIM
; (copied to page-3 RAM at boot) performs the switch, the call, and the map
; restore. CLPRIM's `pop af` recovers the old map from the word pushed here.
calslt_page0_primary:
                ld a,b
                and #03
                ld c,a
                call primary_slot_map
                ld e,a                         ; E = new map
                ld a,d
                push af                        ; old map for CLPRIM's pop af
                ld a,e
                exx
                jp CLPRIM

calslt_page_supported:
                ld a,b
                and #03
                ld c,a
                call primary_slot_map
                push de
                out (PPI_SLOT),a
                ld hl,calslt_return
                push hl
                exx
                ex af,af'
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
                jr z,calslt_expanded_page_supported
                cp #c0
                jp z,calslt_expanded_page3

; Page-0 expanded target. Writing the page-0 subslot selector hides page 0 only
; when the target primary is also the primary currently mapped in page 0; that
; case fails closed. Otherwise the selector is written from this page-0 code,
; CLPRIM performs the page-0 switch and call, and the return frame restores the
; selector and the previous map.
calslt_page0_expanded:
                ld a,b
                call expanded_slot_check
                jr z,calslt_unsupported
                in a,(PPI_SLOT)
                and #03
                ld e,a
                ld a,c
                and #03
                cp e
                jr nz,calslt_page0_expanded_ok
                jp calslt_unsupported
calslt_page0_expanded_ok:
                ld a,c
                call expanded_temporary_select
                ld e,b                         ; old secondary selector
                in a,(PPI_SLOT)
                ld d,a                         ; old primary map
                ld h,d
                ld l,e
                push hl                        ; old map, old selector
                ld b,d
                push bc                        ; old map, primary slot
                ld hl,SLTTBL
                ld a,l
                add a,c
                ld l,a
                push hl                        ; selector mirror address
                ld hl,calslt_page0_expanded_return
                push hl
                ld h,d
                ld l,0
                push hl                        ; old map for CLPRIM's pop af
                ld a,d
                and #fc
                or c                           ; new page-0 map
                exx
                jp CLPRIM

calslt_expanded_page_supported:
                ld a,b
                call expanded_slot_check
                jr z,calslt_unsupported
                call expanded_temporary_select
                ld e,b                         ; old secondary selector
                call primary_slot_map
                out (PPI_SLOT),a
                ld l,e
                push hl                        ; selector restored after return
                ld b,d
                push bc                        ; old primary map, primary slot
                ld hl,SLTTBL
                ld a,l
                add a,c
                ld l,a
                push hl                        ; selector mirror address
                ld hl,calslt_expanded_return
                push hl
                push de                        ; inner old primary map in D
                ld hl,calslt_return
                push hl
                exx
                ex af,af'
                jp (ix)

calslt_unsupported:
                exx
                ex af,af'
                jp unsupported_call

; Expanded-slot software may patch the saved primary and secondary selectors
; in the standard CALSLT frame after changing the RAM slot configuration.
; Recover those live values through the alternate register set so the target's
; normal AF/BC/DE/HL results survive unchanged.
calslt_expanded_return:
                ex af,af'
                exx
                pop hl                         ; selector mirror address
                pop bc                         ; B = primary map, C = primary
                pop de                         ; E = secondary selector
                ld a,e
                call expanded_store_selector
                call expanded_write_selector
                ld a,b
                out (PPI_SLOT),a
                exx
                ex af,af'
                ret

; Page-0 expanded targets return here after CLPRIM restores the primary map.
; Recover the target primary's selector through the SLTTBL mirror and FFFFh.
calslt_page0_expanded_return:
                ex af,af'
                exx
                pop hl                         ; selector mirror address
                pop bc                         ; B = old primary map, C = primary
                pop de                         ; E = old secondary selector
                ld a,e
                call expanded_store_selector
                call expanded_write_selector
                ld a,b
                out (PPI_SLOT),a
                exx
                ex af,af'
                ret

; Page-3 primary target. If the target slot already occupies page 3 the switch
; is a no-op and the ordinary returning-call path keeps the stack visible.
; Otherwise the target's page-3 memory must be writable RAM: a return frame is
; installed there and the caller's stack and previous mapping are recovered
; after the target returns.
calslt_page3_primary:
                ld a,b
                and #03
                ld c,a
                push bc                        ; save slot ID for the no-op path
                call primary_slot_map          ; A = new map, D = old map
                ld e,a                         ; E = new map
                pop bc                         ; B = slot ID, C = primary
                in a,(PPI_SLOT)
                and #c0
                ld h,a                         ; H = current page-3 bits
                ld a,e
                and #c0
                cp h
                jp z,calslt_page_supported     ; no-op switch: normal call
                ld hl,0
                add hl,sp                      ; HL = caller's SP
                push hl
                pop bc                         ; BC = caller's SP
                ld a,e
                out (PPI_SLOT),a               ; switch page 3 to the target
                ld hl,CALSLT_P3_FRAME
                ld a,#55
                ld (hl),a
                cp (hl)
                jp nz,calslt_page3_fail
                ld a,#aa
                ld (hl),a
                cp (hl)
                jp nz,calslt_page3_fail
                ld a,b
                ld (CALSLT_P3_FRAME+4),a       ; caller SP high
                ld a,c
                ld (CALSLT_P3_FRAME+5),a       ; caller SP low
                ld a,d
                ld (CALSLT_P3_FRAME+2),a       ; old primary map
                xor a
                ld (CALSLT_P3_FRAME+3),a
                ld (CALSLT_P3_FRAME+6),a       ; old selector = 0
                ld (CALSLT_P3_FRAME+7),a
                ld (CALSLT_P3_FRAME+8),a       ; primary flag
                ld hl,calslt_page3_return
                ld (CALSLT_P3_FRAME),hl
                ld sp,CALSLT_P3_FRAME
                exx
                ex af,af'
                jp (ix)

; Page-3 expanded target. A target that already occupies page 3 (same selector
; and same primary) uses the ordinary expanded returning-call path; anything
; else gets the page-3 return frame so the caller's stack survives. The old
; selector is captured from the single expanded_temporary_select call so the
; frame restores the pre-call value rather than the freshly written one.
calslt_expanded_page3:
                ld a,b
                call expanded_slot_check
                jp z,calslt_unsupported
                push bc
                call expanded_temporary_select ; A = new selector, B = old selector
                ld e,b                         ; E = old selector (for the frame)
                cp b                           ; selector unchanged?
                pop bc                         ; B = slot ID, Z preserved
                jp nz,calslt_page3_expanded_frame
                ld a,b
                and #03
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                ld d,a
                in a,(PPI_SLOT)
                and #c0
                cp d
                jp nz,calslt_page3_expanded_frame
                jp calslt_expanded_page_supported   ; no-op switch
calslt_page3_expanded_frame:
                ld a,b
                and #03
                ld c,a                         ; C = primary
                in a,(PPI_SLOT)
                ld d,a                         ; D = old primary map
                ld a,d
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
                or b                           ; A = new page-3 map
                out (PPI_SLOT),a               ; switch page 3 to the target primary
                ld a,c
                ld (CALSLT_P3_FRAME+9),a       ; target primary slot (C intact here)
                ld hl,0
                add hl,sp                      ; HL = caller's SP
                ld b,h
                ld c,l                         ; BC = caller's SP
                ld hl,CALSLT_P3_FRAME
                ld a,#55
                ld (hl),a
                cp (hl)
                jp nz,calslt_page3_expanded_fail
                ld a,#aa
                ld (hl),a
                cp (hl)
                jp nz,calslt_page3_expanded_fail
                ld a,b
                ld (CALSLT_P3_FRAME+4),a       ; caller SP high
                ld a,c
                ld (CALSLT_P3_FRAME+5),a       ; caller SP low
                ld a,d
                ld (CALSLT_P3_FRAME+2),a       ; old primary map
                xor a
                ld (CALSLT_P3_FRAME+3),a
                ld a,e
                ld (CALSLT_P3_FRAME+6),a       ; old selector
                xor a
                ld (CALSLT_P3_FRAME+7),a
                ld a,#ff
                ld (CALSLT_P3_FRAME+8),a       ; expanded flag
                ld hl,calslt_page3_return
                ld (CALSLT_P3_FRAME),hl
                ld sp,CALSLT_P3_FRAME
                exx
                ex af,af'
                jp (ix)

; Page-3 target in another slot returns here after its RET pops the frame
; address. The caller's SP was parked in the alternate BC by the frame's EXX,
; so the frame only supplies the previous mapping and, for expanded targets,
; the primary selector to restore. Frame reads happen while page 3 still maps
; the target; the mirror write happens after the map is restored.
calslt_page3_return:
                ex af,af'
                exx                          ; normal BC = caller's SP
                ld a,(CALSLT_P3_FRAME+8)     ; expanded flag
                ld d,a
                bit 7,a
                jr z,calslt_page3_ret_map
                ld a,(CALSLT_P3_FRAME+2)     ; old primary map
                ld l,a
                ld a,(CALSLT_P3_FRAME+9)     ; target primary slot
                ld h,a
                ld a,(CALSLT_P3_FRAME+6)     ; old selector
                ld e,a
                ld (#ffff),a                 ; restore the target primary's selector
                jr calslt_page3_ret_restore
calslt_page3_ret_map:
                ld a,(CALSLT_P3_FRAME+2)     ; old primary map
                ld l,a
calslt_page3_ret_restore:
                ld a,l
                out (PPI_SLOT),a             ; restore page 3 = old slot
                ld a,d                       ; expanded flag
                bit 7,a
                jr z,calslt_page3_ret_done
                ld a,h                       ; primary slot
                ld hl,SLTTBL
                add a,l
                ld l,a
                jr nc,calslt_page3_ret_mirror
                inc h
calslt_page3_ret_mirror:
                ld (hl),e                    ; keep the SLTTBL mirror consistent
calslt_page3_ret_done:
                ld h,b
                ld l,c
                ld sp,hl                     ; restore caller's SP
                exx
                ex af,af'
                ret

calslt_page3_fail:
                ld a,d
                out (PPI_SLOT),a               ; restore page 3 = old slot
                exx
                ex af,af'
                jp unsupported_call

calslt_page3_expanded_fail:
                ld a,e
                ld (#ffff),a                   ; restore the target primary's selector
                ld a,d
                out (PPI_SLOT),a               ; restore page 3 = old slot
                exx
                ex af,af'
                jp unsupported_call

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

; Execute the permanent page-0 switch from a stack trampoline. The generated
; code restores IY, IX, and HL before the PPI write, then returns through the
; caller's original stack frame after page 0 has changed.
                push hl
                push ix
                push iy
                ld ix,0
                add ix,sp
                ld bc,#c9a8                    ; OUT operand, RET
                push bc
                ld bc,#d3e1                    ; POP HL, OUT opcode
                push bc
                ld bc,#e1dd                    ; POP IX
                push bc
                ld bc,#e1fd                    ; POP IY
                push bc
                ld bc,#f9dd                    ; LD SP,IX
                push bc
                ld iy,0
                add iy,sp
                jp (iy)

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

; Capture the active-low joystick matrix for both connectors each VBlank so
; GTSTCK/GTTRIG read a consistent, interrupt-serviced snapshot. PSG R15 is
; restored, so the keyboard scan's R15 baseline is untouched.
controller_capture:
                ld a,PSG_PORT_B
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                ld e,a                          ; original R15
                xor a
                call controller_read_port
                ld (CONTROLLER_PORT1),a
                ld a,1
                call controller_read_port
                ld (CONTROLLER_PORT2),a
                ld a,PSG_PORT_B
                out (PSG_ADDRESS),a
                ld a,e
                out (PSG_WRITE),a
                ret

; Auto-stop the cassette motor about two seconds after it started, unless a
; cassette call restarted the countdown. Active TAP reads and writes disable
; the interrupt for their busy periods, so the timer only advances while the
; motor is idle.
cassette_motor_tick:
                ld a,(CAS_MOTOR)
                or a
                ret z
                ld a,(CAS_MOTOR_TIMER)
                or a
                jr z,cassette_motor_stop
                dec a
                ld (CAS_MOTOR_TIMER),a
                ret
cassette_motor_stop:
                xor a
                ld (CAS_MOTOR),a
                ld a,#09
                out (PPI_CONTROL),a
                ret

; Auto-stop the floppy motor about two seconds after the last disk access.
; The NMS 8250 disk ROM arms the timer through disk_motor_arm; when it expires
; the handler writes the motor-off value to the FDC drive register, guarded by
; DISK_PRESENT so the write only happens on a machine whose disk ROM owns page
; 1's FDC window.
disk_motor_tick:
                ld a,(DISK_MOTOR)
                or a
                ret z
                ld a,(DISK_MOTOR_TIMER)
                or a
                jr z,disk_motor_stop
                dec a
                ld (DISK_MOTOR_TIMER),a
                ret
disk_motor_stop:
                xor a
                ld (DISK_MOTOR),a
                ld a,(DISK_PRESENT)
                or a
                ret z
                xor a
                ld (FDC_DRIVE),a
                ret

; Arm the floppy motor-off timer. Callers (the NMS 8250 disk ROM) invoke this
; after starting the motor so the IM 1 handler stops it after the timeout.
disk_motor_arm:
                ld a,1
                ld (DISK_MOTOR),a
                ld a,DISK_MOTOR_FRAMES
                ld (DISK_MOTOR_TIMER),a
                ret

; Cursor keys and both joystick connectors use the standard 0=center,
; 1..8=clockwise-from-up direction values. GTSTCK may change all registers.
; Joystick directions come from the per-frame interrupt snapshot.
gtstck:
                or a
                jr z,gtstck_keyboard
                dec a
                jr z,gtstck_port1
                dec a
                jr z,gtstck_port2
                xor a
                ret
gtstck_keyboard:
                ld a,8
                call snsmat
                cpl
                and #f0
                rrca
                rrca
                rrca
                rrca
                ld e,a
                ld d,0
                ld hl,keyboard_direction_table
                add hl,de
                ld a,(hl)
                ret
gtstck_port1:
                ld a,(CONTROLLER_PORT1)
                jr gtstck_joystick
gtstck_port2:
                ld a,(CONTROLLER_PORT2)
gtstck_joystick:
                cpl
                and #0f
                ld e,a
                ld d,0
                ld hl,joystick_direction_table
                add hl,de
                ld a,(hl)
                ret

; Space and connector buttons return FFh while pressed and 00h when released.
; Only AF changes, matching the published GTTRIG contract. Connector buttons
; come from the per-frame interrupt snapshot.
gttrig:
                push bc
                push de
                push hl
                ld c,a
                or a
                jr z,gttrig_space
                cp 5
                jr nc,gttrig_released
                ld e,#10                       ; connector button A
                cp 3
                jr c,gttrig_port
                ld e,#20                       ; connector button B
                sub 2
gttrig_port:
                dec a                          ; selectors 1/2 become ports 0/1
                or a
                jr nz,gttrig_port2
                ld a,(CONTROLLER_PORT1)
                jr gttrig_check
gttrig_port2:
                ld a,(CONTROLLER_PORT2)
gttrig_check:
                and e
                jr z,gttrig_pressed
                jr gttrig_released
gttrig_space:
                ld a,8
                call snsmat
                and #01
                jr z,gttrig_pressed
gttrig_released:
                xor a
                jr gttrig_done
gttrig_pressed:
                ld a,#ff
                or a
gttrig_done:
                pop hl
                pop de
                pop bc
                ret

; GTPAD 12/16 latch signed relative mouse movement from connector 1/2 into
; the standard PADX/PADY work areas. Selectors 13/14 and 17/18 return the
; cached axes. Touch-panel selectors 0-3 are touchpad connector 1 and 4-7
; touchpad connector 2: 0/4 fetch the coordinates, 1/5 return X (PADX),
; 2/6 return Y (PADY), and 3/7 return the trigger (FFh pressed, 00h
; released). Unsupported selectors return 0.
gtpad:
                di
                cp 12
                jp z,gtpad_request_port1
                cp 16
                jp z,gtpad_request_port2
                cp 13
                jp z,gtpad_x
                cp 17
                jp z,gtpad_x
                cp 14
                jp z,gtpad_y
                cp 18
                jp z,gtpad_y
                cp 8
                jp nc,gtpad_zero
                ; Touch panel: port 0 (selectors 0-3) or port 1 (4-7). The
                ; carry flag set by the cp 4 / sub 4 picks the connector.
                cp 4
                ld de,#0cec            ; port 0 masks (D = other-port OR, E = AND)
                jr c,gtpad_touchpad_sel
                ld de,#03d3            ; port 1 masks
                sub 4
gtpad_touchpad_sel:
                dec a                   ; fetch data?
                jp m,gtpad_touchpad_read
                dec a                   ; X position?
                ld a,(PADX)
                ret m                   ; flags kept from the dec
                ld a,(PADY)
                ret z                   ; Y position
                ; Selector 3/7: trigger status, sharing the read setup.
gtpad_touchpad_read:
                push af
                ex de,hl
                ld (TPAD_MASK),hl       ; TPAD_MASK = AND, +1 = OR
                sbc a,a                 ; port 0 -> FF, port 1 -> 00 (carry)
                cpl
                and #40                 ; R15 bit 6 selects connector 2
                ld c,a
                ld a,15
                call rdpsg
                and #bf
                or c
                out (PSG_WRITE),a
                pop af
                jp m,gtpad_touchpad_fetch
                ; Trigger status: IOA bit 3 (trigger A).
                call gtpad_ingi
                ei
                and #08
                sub 1
                sbc a,a                 ; FFh when trigger, else 00h
                ret
gtpad_touchpad_fetch:
                ld c,0                  ; serial data 0, channel 0
                call gtpad_redpad
                call gtpad_redpad
                jr c,gtpad_touchpad_nosense
                call gtpad_read_xy
                jr c,gtpad_touchpad_nosense
                push de
                call gtpad_read_xy
                pop bc
                jr c,gtpad_touchpad_nosense
                ld a,b
                sub d
                jr nc,gtpad_touchpad_dx
                cpl
                inc a
gtpad_touchpad_dx:
                cp 5
                jr nc,gtpad_touchpad_fetch
                ld a,c
                sub e
                jr nc,gtpad_touchpad_dy
                cpl
                inc a
gtpad_touchpad_dy:
                cp 5
                jr nc,gtpad_touchpad_fetch
                ld a,d
                ld (PADX),a
                ld a,e
                ld (PADY),a
gtpad_touchpad_nosense:
                ei
                ld a,h
                sub 1
                sbc a,a                 ; FFh when data fetched, else 00h
                ret

; Read the X and Y coordinates from the touchpad into D (X) and E (Y).
; Carry is set when the chip does not respond.
gtpad_read_xy:
                ld c,#0a                ; serial data 1, channel 3
                call gtpad_redpad
                ret c
                ld d,l
                push de
                ld c,0
                call gtpad_redpad
                pop de
                ld e,l
                xor a
                ld h,a                  ; flag data fetched
                ret

; Read one serial byte from the touchpad: bit-bang the clock on the IOB
; (pin 6), sample SO from IOA (bit 2), and return the byte in L with the
; -SENSE line in carry.
gtpad_redpad:
                call gtpad_touchpad_select
                ld b,8
                ld d,c                  ; OR mask = serial data bits
gtpad_redpad_bit:
                res 0,d                 ; pin 6 port 0 clock high
                res 2,d                 ; pin 6 port 1 clock high
                call gtpad_outgi
                call gtpad_ingi
                ld h,a
                rra
                rra
                rra                     ; SO (IOA bit 2) into carry
                rl l                    ; shift into the result
                set 0,d                 ; pin 6 port 0 clock low
                set 2,d                 ; pin 6 port 1 clock low
                call gtpad_outgi
                djnz gtpad_redpad_bit
                set 4,d                 ; pulse port 0 = 1 (deselect)
                set 5,d                 ; pulse port 1 = 1 (deselect)
                call gtpad_outgi
                ld a,h
                rra                     ; -SENSE into carry
                ret

; Wait for the touchpad conversion to finish (EOC high on IOA bit 1) and
; select the chip by clearing the pulse bits.
gtpad_touchpad_select:
                ld a,#35
                or c
                ld d,a
                call gtpad_outgi
gtpad_eoc_wait:
                call gtpad_ingi
                and #02
                jr z,gtpad_eoc_wait
                res 4,d
                res 5,d
                ; fall through to gtpad_outgi

; Write the touchpad serial bits to the PSG IOB using the stored masks:
; clear this connector's clock/data/pulse bits, set them from D, and force
; the other connector's bits high.
gtpad_outgi:
                push hl
                push de
                ld hl,(TPAD_MASK)
                ld a,l
                cpl
                and d
                ld d,a
                ld a,15
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                and l
                or d
                or h
                out (PSG_WRITE),a
                pop de
                pop hl
                ret

; Read the PSG IOA port (port A).
gtpad_ingi:
                ld a,14
                jp rdpsg

gtpad_request_port1:
                xor a
                jr gtpad_request
gtpad_request_port2:
                ld a,1
gtpad_request:
                call mouse_read_port
                ld a,#ff
                jr gtpad_done
gtpad_x:
                ld a,(PADX)
                jr gtpad_done
gtpad_y:
                ld a,(PADY)
                jr gtpad_done
gtpad_zero:
                xor a
gtpad_done:
                ei
                ret

; GTPDL: read a paddle (1-8) as 0-255. The documented paddle is a one-shot
; multivibrator: firing the pin-8 trigger makes the input line go low for a
; pulse whose width is set by the variable resistor. Measure the low pulse on
; the PSG port-A pin with a bounded loop. Without a paddle the line stays high
; and the result is 0. Paddles 9-12 are unsupported and return 0.
gtpdl:
                di
                dec a                           ; paddle 1-8 -> 0-7
                cp 8
                jr nc,gtpdl_zero
                ld c,a                          ; C = paddle index
                ; select the interface: R15 bit 6 (0 = port 1, 1 = port 2)
                ld a,PSG_PORT_B
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                push af                         ; save the original R15
                ld b,a
                bit 2,c
                jr z,gtpdl_iface1
                or #40
                jr gtpdl_iface_done
gtpdl_iface1:
                and #bf
gtpdl_iface_done:
                ld b,a                          ; B = R15, interface selected
                out (PSG_WRITE),a
                ; trigger mask: port 1 = bit 4, port 2 = bit 5
                bit 2,c
                ld a,#10
                jr z,gtpdl_trigger_mask
                ld a,#20
gtpdl_trigger_mask:
                ld d,a                          ; D = trigger mask
                ; fire the one-shot: trigger low, then high
                ld a,b
                cpl
                or d
                cpl                             ; clear the trigger bit only
                out (PSG_WRITE),a
                nop
                ld a,b
                or d                            ; arm the trigger
                out (PSG_WRITE),a
                ; pin mask = 1 << (paddle & 3)
                ld a,c
                and #03
                ld b,a
                inc b                           ; 1..4 shifts
                ld a,1
gtpdl_pin_shift:
                dec b
                jr z,gtpdl_pin_mask
                add a,a
                jr gtpdl_pin_shift
gtpdl_pin_mask:
                ld e,a                          ; E = pin mask
                ; measure the low pulse on the port-A pin
                ld a,PSG_PORT_A
                out (PSG_ADDRESS),a
                ld b,0                          ; counter
gtpdl_measure:
                in a,(PSG_READ)
                and e
                jr nz,gtpdl_done                ; line high: pulse ended
                inc b
                jr nz,gtpdl_measure             ; stop at 255
gtpdl_done:
                ld a,PSG_PORT_B
                out (PSG_ADDRESS),a
                pop af                          ; A = original R15
                out (PSG_WRITE),a               ; restore R15
                ld a,b                          ; paddle result
                ei
                ret
gtpdl_zero:
                xor a
                ei
                ret

; Read the active-low six input lines from connector A=0/1. R15 is modified
; only for that connector: trigger lines become inputs, pin 8 is low, and the
; requested connector is selected. Kana LED and the other connector are kept.
controller_read_port:
                ld c,a
                ld a,PSG_PORT_B
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                ld b,a
                ld a,c
                or a
                ld a,b
                jr nz,controller_select_port2
                and #af                         ; select port 1, pin 8 low
                or #03                          ; port 1 buttons are inputs
                jr controller_port_selected
controller_select_port2:
                and #df                         ; port 2 pin 8 low
                or #4c                          ; select port 2, buttons inputs
controller_port_selected:
                out (PSG_WRITE),a               ; R15 is still selected
                ld a,PSG_PORT_A
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                ret

; Perform the standard X-high, X-low, Y-high, Y-low mouse transaction. Wire
; deltas are negated to the BIOS convention of positive right/down movement.
mouse_read_port:
                ld c,a
                ld a,PSG_PORT_B
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                ld d,a
                ld a,c
                or a
                ld a,d
                jr nz,mouse_select_port2
                and #af
                or #03
                ld c,#10
                jr mouse_port_selected
mouse_select_port2:
                and #df
                or #4c
                ld c,#20
mouse_port_selected:
                ld d,a                          ; selected port, pin 8 low
                out (PSG_WRITE),a               ; R15 is still selected

                or c                            ; latch and expose X high
                out (PSG_WRITE),a
                call mouse_delay_long
                call mouse_read_nibble
                rlca
                rlca
                rlca
                rlca
                ld e,a

                ld a,d                          ; expose X low
                call mouse_write_port_b
                call mouse_delay_short
                call mouse_read_nibble
                or e
                neg
                ld (PADX),a

                ld a,d                          ; expose Y high
                or c
                call mouse_write_port_b
                call mouse_delay_short
                call mouse_read_nibble
                rlca
                rlca
                rlca
                rlca
                ld e,a

                ld a,d                          ; expose Y low and leave strobe low
                call mouse_write_port_b
                call mouse_delay_short
                call mouse_read_nibble
                or e
                neg
                ld (PADY),a
                ret

mouse_write_port_b:
                push af
                ld a,PSG_PORT_B
                out (PSG_ADDRESS),a
                pop af
                out (PSG_WRITE),a
                ret

mouse_read_nibble:
                ld a,PSG_PORT_A
                out (PSG_ADDRESS),a
                in a,(PSG_READ)
                and #0f
                ret

; Working open-source drivers use roughly 100 us before the first sample and
; 40 us after later strobe edges on a 3.58 MHz Z80.
mouse_delay_long:
                ld b,30
mouse_delay_long_loop:
                djnz mouse_delay_long_loop
                ret
mouse_delay_short:
                ld b,10
mouse_delay_short_loop:
                djnz mouse_delay_short_loop
                ret

; Standardized F380h-F399h primary-slot primitives. Callers prepare complete
; old/new PPI images; CLPRIM also receives the target in IX and target AF in
; the alternate set, with the old PPI image saved on the stack.
slot_helpers_image:
                out (PPI_SLOT),a
                ld e,(hl)
                jr slot_helper_restore
slot_helper_write:
                out (PPI_SLOT),a
                ld (hl),e
slot_helper_restore:
                ld a,d
                out (PPI_SLOT),a
                ret
slot_helper_call:
                out (PPI_SLOT),a
                ex af,af'
                call CLPRM1
                ex af,af'
                pop af
                out (PPI_SLOT),a
                ex af,af'
                ret
slot_helper_jump:
                jp (ix)
slot_helpers_image_end:

                include "ide_nms8250_driver.asm"
                include "zx0_decompress.asm"

cold_boot_vdp_registers:
                db #02,#e0,#06,#ff,#03,#36,#07,#01

; V9938 Screen 7 register baseline. R7 follows the public color variables and
; R9 preserves the existing 50/60 Hz selection, so both are written in code.
screen7_vdp_registers_0_6:
                db #0a,#20,#1f,#80,#01,#f7,#1e
screen7_vdp_registers_10_23:
                db #00,#01,#00,#00,#00,#00,#0f,#00
                db #00,#00,#00,#3b,#05,#00

IFDEF MSX2
; V9938 R8-R23 shadow baseline published at MSX2 boot. R8 enables 16x16
; sprites; the remaining extended registers start in their power-on state.
msx2_vdp_registers_8_23:
                db #08,#00,#00,#00,#00,#00,#00,#00
                db #00,#00,#00,#00,#00,#00,#00,#00
ENDIF

text40_vdp_registers:
                db #00,#b0,#00,#00,#01,#36,#07,#f1
text32_vdp_registers:
                db #00,#a0,#06,#80,#00,#36,#07,#f1
graphics2_vdp_registers:
                db #02,#a0,#06,#ff,#03,#36,#07,#01

psg_initial_registers:
                db #55,#00,#00,#00,#00,#00,#00,#b8
                db #00,#00,#00,#0b,#00,#00,#00,#8f

; Pressed-bit indices are L/U/D/R for the keyboard table and U/D/L/R for the
; joystick table. Electrically contradictory direction pairs report center.
keyboard_direction_table:
                db 0,7,1,8,5,6,0,0,3,0,2,0,4,0,0,0
joystick_direction_table:
                db 0,1,5,0,7,8,6,0,3,2,4,0,0,0,0,0

; International keyboard matrix rows 0-5, bit 0 first. A zero entry is not
; translated in this first keyboard slice.
keymap_unshifted:
                db '0', '1', '2', '3', '4', '5', '6', '7'
                db '8', '9', '-', '=', #5c, '[', ']', ';'
                db #27, '`', ',', '.', '/', 0,   'a', 'b'
                db 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'
                db 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r'
                db 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
keymap_shifted:
                db ')', '!', '@', '#', '$', '%', '^', '&'
                db '*', '(', '_', '+', '|', '{', '}', ':'
                db '"', '~', '<', '>', '?', 0,   'A', 'B'
                db 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'
                db 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'
                db 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
keymap_row7:
                db 0,0,#1b,#09,#03,#08,0,#0d
keymap_row8:
                db #20,#0b,#12,#7f,#1d,#1e,#1f,#1c

; Accented characters produced by a dead key followed by a letter. Four rows of
; 26 entries indexed by (letter - 'a'); a zero entry means no accented form, so
; the plain letter is emitted instead. Codes follow the MSX international
; character set.
deadkey_table:
                db #85,0, 0,0, #8a,0, 0,0, #8d,0, 0,0, 0,0, #95,0, 0,0, 0,0, #97,0, 0,0, 0,0   ; grave
                db #a0,0, 0,0, #82,0, 0,0, #a1,0, 0,0, 0,0, #a2,0, 0,0, 0,0, #a3,0, 0,0, 0,0   ; acute
                db #83,0, 0,0, #88,0, 0,0, #8c,0, 0,0, 0,0, #93,0, 0,0, 0,0, #96,0, 0,0, 0,0   ; circumflex
                db #84,0, 0,0, #89,0, 0,0, #8b,0, 0,0, 0,0, #94,0, 0,0, 0,0, #81,0, 0,0, #98,0 ; umlaut

jingle_notes:
                db #d6,#00                     ; C5
                db #aa,#00                     ; E5
                db #8f,#00                     ; G5
                db #6b,#00                     ; C6

sd_boot_choice_message:
                db #0d,#0a,"SELECT SD BOOT CARD: A OR B? ",0

storage_boot_failed_message:
                db "STORAGE BOOT FAILED",0

boot_font:
                incbin "boot_font.bin"
options_name_ready_zx0:
                incbin "options_name_ready.zx0"
options_name_missing_zx0:
                incbin "options_name_missing.zx0"
options_color_zx0:
                incbin "options_color.zx0"

logo_pattern_zx0:
                incbin "logo_pattern.zx0"
logo_name_zx0:
                incbin "logo_name.zx0"
logo_color_zx0:
                incbin "logo_color.zx0"

                assert $<=#4000
                defs #4000-$,#ff
embedded_basic_payload:
                db "RBC1"
                dw #4010
                dw embedded_basic_payload_zx0_end-embedded_basic_payload_zx0
embedded_basic_payload_zx0:
                incbin "bbcbasic_msx_console.zx0"
embedded_basic_payload_zx0_end:
                defs #8000-$,#ff
embedded_basic_payload_end:
                assert $==#8000
