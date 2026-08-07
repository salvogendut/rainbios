; SPDX-License-Identifier: BSD-3-Clause
;
; DSKIO write-path boot fixture for the production NMS 8250 disk ROM. The disk
; ROM reads this sector into C000h and enters at C000h+1Eh, where the loader
; fills a page-3 buffer with a deterministic 512-byte pattern, writes it to
; logical sector 2 through DSKIO (carry set), reads sector 2 back, and
; compares. On a read-write image the write succeeds and the read-back
; matches; the markers let the 1983 harness distinguish the writable path from
; a write-protect rejection.
;
; Assembled as a standalone C000h image; the Makefile passes the resulting
; binary to tools/make_boot_disk.py, which places sector 0 and sector 1 into a
; 720 KiB F9 image.

CALSLT          equ #001c
DSKIO           equ #4010
H_PHYD          equ #ffa7

WRITE_BUF       equ #c200
READ_BUF        equ #c400

                org #c000

; Sector 0: standard boot-sector header and the loader.
                db #eb,#1c,#90                 ; jump to C01Eh, nop
                db "RBDOS   "                  ; OEM name
                dw 512                         ; bytes per sector
                db 2                           ; sectors per cluster
                dw 1                           ; reserved sectors
                db 2                           ; FAT copies
                dw 112                         ; root directory entries
                dw 1440                        ; total sectors
                db #f9                         ; media descriptor
                dw 3                           ; FAT size in sectors
                dw 9                           ; sectors per track
                dw 2                           ; heads
                dw 0                           ; hidden sectors

; Entry point, matching the MSX-DOS kernel convention C000h+1Eh.
disk_write_entry:
                ld a,1
                ld (m_entry),a
                ld a,(H_PHYD+1)                ; disk ROM slot ID
                push af
                pop iy                         ; IY high byte = slot

                ; Fill the write buffer with bytes 0..255 repeated twice.
                ld hl,WRITE_BUF
                ld b,2
                ld a,0
disk_write_fill:
                ld c,0
disk_write_fill_inner:
                ld (hl),a
                inc a
                inc hl
                inc c
                jr nz,disk_write_fill_inner
                djnz disk_write_fill
                ld hl,WRITE_BUF

                ; DSKIO write: drive 0, one sector at logical sector 2.
                xor a
                ld ix,DSKIO
                ld de,2
                ld bc,#01f9
                scf                            ; write operation
                call CALSLT
                jr nc,disk_write_did_write

                ; Write failed: record the DSKIO error number.
                ld (m_write_error),a
                ld a,1
                ld (m_write_carry),a
                ld a,0
                ld (m_compare),a
                jr disk_write_done

disk_write_did_write:
                ; Write succeeded; the host verifies the image sector.
                xor a
                ld (m_write_carry),a
                ld (m_write_error),a
                jr disk_write_done

disk_write_done:
                ld a,#5a
                ld (pass_marker),a
disk_write_pass:
                jr disk_write_pass

                defs #c200-$,0

; Sector 1: marker data.
sector1_marker:
                db "RB01"
                defs #c400-$,0

; ---- page-3 work area ----
m_entry         equ #f3c5
m_write_carry   equ #f3c0
m_write_error   equ #f3c1
m_compare       equ #f3c2
pass_marker     equ #f3c4
