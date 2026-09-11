; RainBIOS/BBC BASIC private storage bridge. A=0 selects SAVE, A=1 LOAD, and
; A=2 dispatches a storage OSCLI command;
; HL addresses the CR-terminated name, DE the program buffer, and BC its byte
; count/capacity. Only A:NAME selects floppy storage. Other names tail-call the
; cassette routines published in the payload header, preserving the standalone
; cartridge's legacy behavior without baking their linked addresses into BIOS.
basic_storage_dispatch:
                cp 2
                jp z,basic_storage_oscli
                or a
                ld ix,(BASIC_CASS_SAVE)
                jr z,basic_storage_fallback_ready
                ld ix,(BASIC_CASS_LOAD)
basic_storage_fallback_ready:
                push af
                push hl
                ld a,(hl)
                and #df
                cp 'A'
                jr nz,basic_storage_cassette
                inc hl
                ld a,(hl)
                cp ':'
                jr nz,basic_storage_cassette
                pop hl
                pop af
                or a
                jr z,basic_storage_save
                jr basic_storage_load
basic_storage_cassette:
                pop hl
                pop af
                push ix
                ret

basic_storage_save:
                push bc
                push de
                call basic_storage_filename
                jr nc,basic_storage_bad_filename
                pop de
                pop bc
                ld (BASIC_FS_WORK),bc
                push hl
                push de
                call basic_storage_disk_slot
                jr nc,basic_storage_unavailable_stacked
                pop de
                pop hl
                push af
                pop iy
                ld ix,BASIC_FS_WRITE
                ld bc,BASIC_FS_WORK
                xor a
                call calslt
                ret nc
                jp basic_storage_disk_error

basic_storage_load:
                push bc
                push de
                call basic_storage_filename
                jr nc,basic_storage_bad_filename
                pop de
                pop bc
                ld (BASIC_FS_WORK),bc
                push hl
                push de
                call basic_storage_disk_slot
                jr nc,basic_storage_unavailable_stacked
                pop de
                pop hl
                push af
                pop iy
                ld ix,BASIC_FS_LOAD
                ld bc,BASIC_FS_WORK
                xor a
                call calslt
                jr nc,basic_storage_load_ok
                cp 23                           ; DESTINATION CAPACITY EXCEEDED
                jp nz,basic_storage_disk_error
                or a                            ; CORE REPORTS "NO ROOM"
                ret
basic_storage_load_ok:
                scf
                ret

basic_storage_unavailable_stacked:
                pop de
                pop hl
basic_storage_unavailable:
                ld hl,basic_storage_unavailable_message
                jp basic_storage_raise
basic_storage_bad_filename:
                ld hl,basic_storage_bad_filename_message
                jp basic_storage_raise

; Convert A:NAME in place to uppercase NAME____BBC. The deliberately compact
; grammar accepts one through eight ASCII letters, digits, '_' or '-'; the
; fixed .BBC extension makes tokenized program files obvious in a FAT listing.
; Carry is set on success with HL restored to the 11-byte result.
basic_storage_filename:
                push hl
                ld d,h
                ld e,l
                inc hl
                inc hl
                ld b,8
                ld c,0
basic_storage_filename_char:
                ld a,(hl)
                cp #0d
                jr z,basic_storage_filename_end
                inc hl
                cp 'a'
                jr c,basic_storage_filename_upper
                cp 'z'+1
                jr nc,basic_storage_filename_upper
                sub #20
basic_storage_filename_upper:
                cp 'A'
                jr c,basic_storage_filename_digit
                cp 'Z'+1
                jr c,basic_storage_filename_store
basic_storage_filename_digit:
                cp '0'
                jr c,basic_storage_filename_symbol
                cp '9'+1
                jr c,basic_storage_filename_store
basic_storage_filename_symbol:
                cp '_'
                jr z,basic_storage_filename_store
                cp '-'
                jr nz,basic_storage_filename_fail
basic_storage_filename_store:
                ld (de),a
                inc de
                inc c
                djnz basic_storage_filename_char
                ld a,(hl)
                cp #0d
                jr nz,basic_storage_filename_fail
basic_storage_filename_end:
                ld a,c
                or a
                jr z,basic_storage_filename_fail
                ld a,b
                or a
                jr z,basic_storage_filename_extension
                ld a,' '
basic_storage_filename_pad:
                ld (de),a
                inc de
                djnz basic_storage_filename_pad
basic_storage_filename_extension:
                ld a,'B'
                ld (de),a
                inc de
                ld (de),a
                inc de
                inc a                           ; 'C' follows 'B'
                ld (de),a
                pop hl
                scf
                ret
basic_storage_filename_fail:
                pop hl
                or a
                ret

; Accept only the disk-system master currently published through H.PHYD and
; only when its page-1 ROM advertises the version-1 RBFS capability block.
; This avoids a hard-coded Omega slot and never jumps into an unrelated disk
; ROM which happens to occupy the standard page-1 window.
basic_storage_disk_slot:
                ld hl,(H_PHYD)
                ld a,l
                cp #f7
                jr nz,basic_storage_disk_slot_fail
                ld a,h
                ld (BASIC_FS_WORK+FS_SLOT_OFFSET),a
                ld hl,BASIC_FS_SIG
                ld a,(BASIC_FS_WORK+FS_SLOT_OFFSET)
                call rdslt
                cp 'R'
                jr nz,basic_storage_disk_slot_fail
                inc hl
                ld a,(BASIC_FS_WORK+FS_SLOT_OFFSET)
                call rdslt
                cp 'B'
                jr nz,basic_storage_disk_slot_fail
                inc hl
                ld a,(BASIC_FS_WORK+FS_SLOT_OFFSET)
                call rdslt
                cp 'F'
                jr nz,basic_storage_disk_slot_fail
                inc hl
                ld a,(BASIC_FS_WORK+FS_SLOT_OFFSET)
                call rdslt
                cp 'S'
                jr nz,basic_storage_disk_slot_fail
                inc hl
                ld a,(BASIC_FS_WORK+FS_SLOT_OFFSET)
                call rdslt
                cp 1
                jr nz,basic_storage_disk_slot_fail
                inc hl
                ld a,(BASIC_FS_WORK+FS_SLOT_OFFSET)
                call rdslt
                and 7                           ; BOUNDED LOAD/MULTI/REPLACE
                cp 7
                jr nz,basic_storage_disk_slot_fail
                ld a,(BASIC_FS_WORK+FS_SLOT_OFFSET)
                scf
                ret
basic_storage_disk_slot_fail:
                or a
                ret

basic_storage_disk_error:
                or a
                jr z,basic_storage_write_protected
                cp 2
                jr z,basic_storage_no_disk
                cp 3
                jr z,basic_storage_write_protected
                cp 17
                jr z,basic_storage_not_found
                cp 18
                jr z,basic_storage_not_file
                cp 19
                jr z,basic_storage_bad_disk
                cp 20
                jr z,basic_storage_bad_disk
                cp 21
                jr z,basic_storage_disk_full
                cp 22
                jr z,basic_storage_directory_full
                ld hl,basic_storage_io_error_message
                jr basic_storage_raise
basic_storage_write_protected:
                ld hl,basic_storage_write_protected_message
                jr basic_storage_raise
basic_storage_no_disk:
                ld hl,basic_storage_no_disk_message
                jr basic_storage_raise
basic_storage_not_found:
                ld hl,basic_storage_not_found_message
                jr basic_storage_raise
basic_storage_not_file:
                ld hl,basic_storage_not_file_message
                jr basic_storage_raise
basic_storage_bad_disk:
                ld hl,basic_storage_bad_disk_message
                jr basic_storage_raise
basic_storage_disk_full:
                ld hl,basic_storage_disk_full_message
                jr basic_storage_raise
basic_storage_directory_full:
                ld hl,basic_storage_directory_full_message
basic_storage_raise:
                ld a,198
                push hl                         ; EXTERR POPS INLINE TEXT POINTER
                ld hl,(BASIC_EXTERR)
                push hl
                ret

basic_storage_unavailable_message:      db "No disk service",0
basic_storage_bad_filename_message:     db "Bad filename",0
basic_storage_write_protected_message:  db "Disk write protected",0
basic_storage_no_disk_message:          db "No disk",0
basic_storage_not_found_message:        db "File not found",0
basic_storage_not_file_message:         db "Not a file",0
basic_storage_bad_disk_message:         db "Bad disk",0
basic_storage_disk_full_message:        db "Disk full",0
basic_storage_directory_full_message:   db "Directory full",0
basic_storage_io_error_message:         db "Disk I/O error",0
