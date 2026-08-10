; SPDX-License-Identifier: BSD-3-Clause
;
; Clean-room DOS1 boot and BDOS compatibility layer.  This code is based on
; the published MSX-DOS FCB and BDOS contracts.  It contains no proprietary
; Disk ROM or MSXDOS.SYS code or data.

BDOS_ENTRY              equ #f37d
DOS_ENABLE_ENTRY        equ #f368
DOS_DISABLE_ENTRY       equ #f36b
DOS_XFER_ENTRY          equ #f36e

BIOS_CHGET              equ #009f
BIOS_CHPUT              equ #00a2
BIOS_CHSNS              equ #009c
BIOS_ENASLT             equ #0024
PPI_SLOT                equ #a8
RAMAD0                  equ #f341
RAMAD1                  equ #f342
SLTTBL                  equ #fcc5

DOS_DTA                 equ #f23d
DOS_FILE_SIZE           equ #f002
DOS_OPEN_FCB            equ #f004
DOS_PAGE0_RAM           equ #f006
DOS_DEFAULT_DRIVE       equ #f247
DOS_MSDOS_DRIVE         equ #f306
DOS_REQUEST_RECORDS     equ #f008
DOS_RECORD_SIZE         equ #f00a
DOS_BYTE_OFFSET         equ #f00c
DOS_TRANSFER_RECORDS    equ #f00e
DOS_TRANSFER_BYTES      equ #f010
DOS_TRANSFER_STATUS     equ #f012
DOS_BIOS_PRIMARY        equ #f013
DOS_IRQ_PRIMARY         equ #f014
DOS_CALL_PRIMARY        equ #f015
DOS_RUNTIME_ACTIVE      equ #f016
DOS_DPB                 equ #f197
DOS_KERNEL_WORK_START   equ #d361
DOS_FAT_BUFFER          equ #e565
DOS_REBOOT              equ #f340
DOS_ROM_SLOT            equ #f348
DOS_SYSTEM_BOTTOM       equ #f34b
DOS_BOOTED              equ #f346
DOS_DRIVE_COUNT         equ #f347
DOS_WORK_START          equ #f349
DOS_CURRENT_DPB         equ #f353
DOS_DPB_LIST            equ #f355
; The DOS1 1.x resident dispatcher target installed behind CALL 0005h.
DOS_RUNTIME_ENTRY       equ #ca06

DOS_PAGE3_STUBS         equ #f100
DOS_PAGE1_ENABLE        equ DOS_PAGE3_STUBS
DOS_PAGE1_DISABLE       equ DOS_PAGE3_STUBS+(disk_bdos_page3_disable_source-disk_bdos_page3_stubs_source)
DOS_PAGE1_XFER          equ DOS_PAGE3_STUBS+(disk_bdos_page3_xfer_source-disk_bdos_page3_stubs_source)
DOS_PAGE1_COPY          equ DOS_PAGE3_STUBS+(disk_bdos_page3_copy_source-disk_bdos_page3_stubs_source)
DOS_BDOS_GATE           equ DOS_PAGE3_STUBS+(disk_bdos_page3_bdos_source-disk_bdos_page3_stubs_source)
DOS_IRQ_GATE            equ DOS_PAGE3_STUBS+(disk_bdos_page3_interrupt_source-disk_bdos_page3_stubs_source)
DOS_IRQ_RETURN          equ DOS_PAGE3_STUBS+(disk_bdos_page3_interrupt_return_source-disk_bdos_page3_stubs_source)
DOS_PAGE1_SELECT        equ DOS_PAGE3_STUBS+(disk_bdos_page3_select_source-disk_bdos_page3_stubs_source)

DOS_WORK                equ #c200
DOS_STAGE               equ #8000
DOS_STAGE_LIMIT         equ #c000
FCB_CURRENT_BLOCK       equ 12
FCB_RECORD_SIZE         equ 14
FCB_FILE_SIZE           equ 16
FCB_CURRENT_RECORD      equ 32
FCB_RANDOM_RECORD       equ 33

disk_bdos_install:
                ld hl,disk_bdos_page3_stubs_source
                ld de,DOS_PAGE3_STUBS
                ld bc,disk_bdos_page3_stubs_end-disk_bdos_page3_stubs_source
                ldir
                ld a,(H_PHYD+1)
                ld (DOS_ROM_SLOT),a

                ld hl,DOS_ENABLE_ENTRY
                ld (hl),#c3
                inc hl
                ld de,DOS_PAGE1_ENABLE
                ld (hl),e
                inc hl
                ld (hl),d

                ld hl,DOS_DISABLE_ENTRY
                ld (hl),#c3
                inc hl
                ld de,DOS_PAGE1_DISABLE
                ld (hl),e
                inc hl
                ld (hl),d

                ld hl,DOS_XFER_ENTRY
                ld (hl),#c3
                inc hl
                ld de,DOS_PAGE1_XFER
                ld (hl),e
                inc hl
                ld (hl),d

                ld hl,BDOS_ENTRY
                ld (hl),#c3
                inc hl
                ld de,DOS_BDOS_GATE
                ld (hl),e
                inc hl
                ld (hl),d

                ld hl,#0080
                ld (DOS_DTA),hl
                xor a
                ld (DOS_PAGE0_RAM),a
                ld (DOS_DEFAULT_DRIVE),a
                ld (DOS_MSDOS_DRIVE),a
                ld (DOS_RUNTIME_ACTIVE),a
                ld (DOS_REBOOT),a
                ld a,#eb
                ld (DOS_BOOTED),a
                ld a,4
                ld (DOS_DRIVE_COUNT),a
                xor a
                ld (DOS_DPB),a
                ld hl,disk_dpb
                ld de,DOS_DPB+1
                ld bc,18
                ldir
                ld hl,DOS_FAT_BUFFER
                ld (DOS_DPB+19),hl
                ld hl,DOS_KERNEL_WORK_START
                ld (DOS_WORK_START),hl
                ld hl,0
                ld (DOS_CURRENT_DPB),hl
                ld hl,DOS_DPB
                ld (DOS_DPB_LIST),hl
                ld hl,#d0d5
                ld (DOS_SYSTEM_BOTTOM),hl
                ret

disk_dos_init:
                call disk_bdos_runtime_entry_install
                ld a,1
                ld (DOS_RUNTIME_ACTIVE),a
                ld hl,(DOS_SYSTEM_BOTTOM)
                ret

disk_bdos_runtime_entry_install:
                ; MSXDOS.SYS clears its resident range after $$INIT and then
                ; loads COMMAND.COM through RDBLK. Reinstall this original
                ; RainBIOS trampoline after each completed block read so the
                ; final CALL 0005h vector has a live page-3 target.
                push hl
                push de
                ld hl,DOS_RUNTIME_ENTRY
                ld (hl),#c3
                inc hl
                ld de,BDOS_ENTRY
                ld (hl),e
                inc hl
                ld (hl),d
                pop de
                pop hl
                ret

disk_dos_bios:
                call disk_bdos_bios_page0_enter
                ei
                call BIOS_CHSNS
                ld a,0
                jr z,disk_dos_bios_none
                dec a
disk_dos_bios_none:
                call disk_bdos_bios_page0_leave
                ret

disk_dos_console_in:
                call disk_bdos_bios_page0_enter
                ei
                call BIOS_CHGET
                call disk_bdos_bios_page0_leave
                ret

disk_dos_console_out:
                ld a,e
disk_dos_console_out_a:
                call disk_bdos_bios_page0_enter
                ei
                call BIOS_CHPUT
                call disk_bdos_bios_page0_leave
                ret

; Disk-ROM services remain resident in page 1, so they can expose the main
; BIOS temporarily whenever a DOS console operation needs a page-0 routine.
; Interrupts are enabled only after the BIOS vector is visible again.
disk_bdos_bios_page0_enter:
                di
                push af
                push bc
                in a,(PPI_SLOT)
                ld (DOS_CALL_PRIMARY),a
                and #fc
                ld b,a
                ld a,(DOS_BIOS_PRIMARY)
                or b
                out (PPI_SLOT),a
                pop bc
                pop af
                ret

disk_bdos_bios_page0_leave:
                di
                push af
                ld a,(DOS_CALL_PRIMARY)
                out (PPI_SLOT),a
                pop af
                ei
                ret

; These routines are copied to page-3 RAM during installation.  They are
; deliberately self-contained: page 1 may disappear underneath them while
; they switch between the Disk ROM and the RAM slot.  All internal branches
; are relative, so the block remains position-independent after the copy.
disk_bdos_page3_stubs_source:
                push af
                ld a,(DOS_ROM_SLOT)
                jp DOS_PAGE1_SELECT

disk_bdos_page3_disable_source:
                push af
                ld a,(RAMAD1)
                jp DOS_PAGE1_SELECT

disk_bdos_page3_xfer_source:
                call DOS_PAGE1_DISABLE
                jp (hl)

; Copy a block from page 3 into page-1 RAM while this routine remains safely
; resident in page 3. Restore the Disk ROM before returning to its caller.
disk_bdos_page3_copy_source:
                call DOS_PAGE1_DISABLE
                ldir
                call DOS_PAGE1_ENABLE
                ret

disk_bdos_page3_bdos_source:
                call DOS_PAGE1_ENABLE
                call disk_bdos_dispatch
                push af
                ld a,(DOS_RUNTIME_ACTIVE)
                or a
                jr z,disk_bdos_page3_bdos_return_source
                call DOS_PAGE1_DISABLE
disk_bdos_page3_bdos_return_source:
                pop af
                ret

; DOS replaces page 0 with RAM, including the IM 1 vector at 0038h.  The
; interrupt bridge must therefore live in page 3 as well as the slot gates.
; It exposes the main BIOS in page 0, lets the BIOS service and acknowledge
; the interrupt, then restores DOS RAM before returning to the application.
disk_bdos_page3_interrupt_source:
                di
                push af
                push bc
                in a,(PPI_SLOT)
                ld (DOS_IRQ_PRIMARY),a
                and #fc
                ld b,a
                ld a,(DOS_BIOS_PRIMARY)
                or b
                out (PPI_SLOT),a
                pop bc
                pop af
                push hl
                ld hl,DOS_IRQ_RETURN
                ex (sp),hl
                jp #0038

disk_bdos_page3_interrupt_return_source:
                di
                push af
                ld a,(DOS_IRQ_PRIMARY)
                out (PPI_SLOT),a
                pop af
                ei
                reti

disk_bdos_page3_select_source:
                push bc
                push de
                push hl
                ld e,a
                bit 7,e
                jr z,disk_bdos_page3_primary_source

                ; The normal RainBIOS layout keeps internal expanded slots
                ; and page-3 RAM under the same primary slot.  In that case
                ; update page 1's secondary selector before its primary map.
                and #03
                ld c,a
                in a,(PPI_SLOT)
                and #c0
                rlca
                rlca
                cp c
                jr nz,disk_bdos_page3_primary_source
                ld b,0
                ld hl,SLTTBL
                add hl,bc
                ld a,(hl)
                and #f3
                ld d,a
                ld a,e
                and #0c
                or d
                ld (hl),a
                ld (#ffff),a

disk_bdos_page3_primary_source:
                ld a,e
                and #03
                add a,a
                add a,a
                ld e,a
                in a,(PPI_SLOT)
                and #f3
                or e
                out (PPI_SLOT),a
                pop hl
                pop de
                pop bc
                pop af
                ret
disk_bdos_page3_stubs_end:

disk_bdos_dispatch:
                ld a,c
                or a
                jp z,disk_bdos_reset
                cp #01
                jp z,disk_dos_console_in
                cp #02
                jp z,disk_dos_console_out
                cp #06
                jp z,disk_bdos_direct_console
                cp #09
                jp z,disk_bdos_string_output
                cp #0a
                jp z,disk_bdos_buffered_console
                cp #0b
                jp z,disk_dos_bios
                cp #0c
                jp z,disk_bdos_version
                cp #0d
                jp z,disk_bdos_disk_reset
                cp #0e
                jp z,disk_bdos_select_disk
                cp #0f
                jp z,disk_bdos_open
                cp #10
                jp z,disk_bdos_close
                cp #11
                jp z,disk_bdos_find_first
                cp #12
                jp z,disk_bdos_find_next
                cp #14
                jp z,disk_bdos_sequential_read
                cp #18
                jp z,disk_bdos_login_vector
                cp #19
                jp z,disk_bdos_default_drive
                cp #1a
                jp z,disk_bdos_set_dta
                cp #1b
                jp z,disk_bdos_allocation
                cp #21
                jp z,disk_bdos_random_read
                cp #24
                jp z,disk_bdos_set_random_record
                cp #27
                jp z,disk_bdos_random_block_read
                ld a,#ff
                ret

; MSXDOS.SYS invokes the resident kernel dispatcher with the function number
; in L; Disk BASIC uses C through F37Dh.  Both paths share the same clean-room
; service implementation.
disk_bdos_dispatch_l:
                ld c,l
                jp disk_bdos_dispatch

disk_dos_runtime_init:
                xor a
                ret

disk_bdos_reset:
                jp #0000

disk_bdos_direct_console:
                ld a,e
                inc a
                jr z,disk_bdos_direct_input
                jp disk_dos_console_out
disk_bdos_direct_input:
                call disk_dos_bios
                or a
                ret z
                jp disk_dos_console_in

; Read and echo a DOS1/CP/M style buffered command line. DE points at a
; caller-owned buffer whose first byte is its character capacity; the second
; byte receives the length excluding the terminating carriage return, and the
; characters begin at DE+2. The call blocks until Return, as COMMAND.COM
; requires, and stores a trailing carriage return immediately after the text.
disk_bdos_buffered_console:
                push de
                ld a,(de)
                ld b,a
                inc de
                xor a
                ld (de),a
                inc de
                ex de,hl
                ld c,0
disk_bdos_buffered_console_loop:
                call disk_dos_console_in
                cp #0d
                jr z,disk_bdos_buffered_console_done
                cp #08
                jr z,disk_bdos_buffered_console_backspace
                cp #7f
                jr z,disk_bdos_buffered_console_backspace
                cp #20
                jr c,disk_bdos_buffered_console_loop
                push af
                ld a,c
                cp b
                jr nc,disk_bdos_buffered_console_full
                pop af
                ld (hl),a
                inc hl
                inc c
                ld e,a
                call disk_dos_console_out
                jr disk_bdos_buffered_console_loop
disk_bdos_buffered_console_full:
                pop af
                jr disk_bdos_buffered_console_loop
disk_bdos_buffered_console_backspace:
                ld a,c
                or a
                jr z,disk_bdos_buffered_console_loop
                dec c
                dec hl
                ld e,#08
                call disk_dos_console_out
                ld e,#20
                call disk_dos_console_out
                ld e,#08
                call disk_dos_console_out
                jr disk_bdos_buffered_console_loop
disk_bdos_buffered_console_done:
                ld (hl),#0d
                pop hl
                inc hl
                ld (hl),c
                ld e,#0d
                call disk_dos_console_out
                ld e,#0a
                call disk_dos_console_out
                xor a
                ret

disk_bdos_string_output:
                ld a,(de)
                cp '$'
                ret z
                push de
                ld e,a
                call disk_dos_console_out
                pop de
                inc de
                jr disk_bdos_string_output

disk_bdos_version:
                ld hl,#0022
                xor a
                ret

disk_bdos_disk_reset:
                xor a
                ld (DOS_DEFAULT_DRIVE),a
                ld (DOS_MSDOS_DRIVE),a
                ld hl,#0080
                ld (DOS_DTA),hl
                ret

disk_bdos_select_disk:
                ld a,e
                or a
                jp nz,disk_bdos_fail
                ld (DOS_DEFAULT_DRIVE),a
                ld (DOS_MSDOS_DRIVE),a
                ret

disk_bdos_default_drive:
                ld a,(DOS_DEFAULT_DRIVE)
                ret

disk_bdos_login_vector:
                ld hl,1
                xor a
                ret

disk_bdos_set_dta:
                ld (DOS_DTA),de
                xor a
                ret

disk_bdos_allocation:
                ld a,e
                or a
                jr nz,disk_bdos_fail
                ld a,DISK_CLUSTER_SIZE
                ld bc,DISK_SECTOR_SIZE
                ld de,DISK_CLUSTERS
                ld hl,DISK_CLUSTERS
                ld ix,DOS_DPB
                ld iy,0
                ret

; OPEN validates and stages a regular root-directory file through RainBIOS's
; independently implemented FS.LOAD path.
disk_bdos_open:
                push de
                ld a,(de)
                or a
                jr z,disk_bdos_open_drive_ok
                cp 1
                jr nz,disk_bdos_open_failed_pop
disk_bdos_open_drive_ok:
                inc de
                ex de,hl
                ld de,DOS_STAGE
                ld bc,DOS_WORK
                xor a
                call disk_fs_load
                jr c,disk_bdos_open_failed_pop
                ld (DOS_FILE_SIZE),bc
                pop de
                ld (DOS_OPEN_FCB),de

                push de
                ld hl,FCB_CURRENT_BLOCK
                add hl,de
                xor a
                ld b,24
disk_bdos_open_clear:
                ld (hl),a
                inc hl
                djnz disk_bdos_open_clear
                pop de

                push de
                ld hl,FCB_RECORD_SIZE
                add hl,de
                ld (hl),#80
                inc hl
                ld (hl),0
                inc hl
                ld bc,(DOS_FILE_SIZE)
                ld (hl),c
                inc hl
                ld (hl),b
                inc hl
                xor a
                ld (hl),a
                inc hl
                ld (hl),a
                pop de
                xor a
                ret
disk_bdos_open_failed_pop:
                pop de
disk_bdos_fail:
                ld a,#ff
                ret

disk_bdos_close:
                xor a
                ret

; Sequential and one-record random reads share the block-reader semantics.
; Current-block support is deliberately bounded to the first 128 records in
; this boot slice; later slices can lift that without changing the ABI.
disk_bdos_sequential_read:
                push de
                ld hl,FCB_CURRENT_BLOCK
                add hl,de
                ld a,(hl)
                inc hl
                or (hl)
                jr nz,disk_bdos_sequential_fail
                ld hl,FCB_CURRENT_RECORD
                add hl,de
                ld a,(hl)
                pop de
                push de
                ld hl,FCB_RANDOM_RECORD
                add hl,de
                ld (hl),a
                inc hl
                ld (hl),0
                inc hl
                ld (hl),0
                pop de
                ld hl,1
                call disk_bdos_random_block_read
                or a
                ret nz
                push de
                ld hl,FCB_CURRENT_RECORD
                add hl,de
                inc (hl)
                pop de
                xor a
                ret
disk_bdos_sequential_fail:
                pop de
                ld a,1
                ret

disk_bdos_random_read:
                ld hl,1
                jp disk_bdos_random_block_read

; RDBLK implements complete-record reads in the 16-bit record domain. FS.LOAD
; has already materialized the file in DOS_STAGE, so random access is a bounded
; copy into the current DTA. A short final read returns A=1 and the number of
; complete records in HL, as required by the DOS1 contract.
disk_bdos_random_block_read:
                ld (DOS_REQUEST_RECORDS),hl
                ld (DOS_OPEN_FCB),de
                push de
                ld hl,FCB_RANDOM_RECORD
                add hl,de
                ld e,(hl)
                inc hl
                ld d,(hl)
                inc hl
                ld a,(hl)
                or a
                jp nz,disk_bdos_random_fail_pop

                push de                         ; random record
                ld de,(DOS_OPEN_FCB)
                ld hl,FCB_RECORD_SIZE
                add hl,de
                ld c,(hl)
                inc hl
                ld b,(hl)                       ; BC = record size
                ld a,b
                or c
                jp z,disk_bdos_random_fail_record
                ld (DOS_RECORD_SIZE),bc

                pop de                          ; random record
                call disk_bdos_multiply16       ; HL = byte offset
                jp c,disk_bdos_random_fail_pop
                ld (DOS_BYTE_OFFSET),hl
                ld de,(DOS_FILE_SIZE)
                or a
                sbc hl,de
                jr c,disk_bdos_random_offset_ok
                jr z,disk_bdos_random_offset_ok
                jp disk_bdos_random_fail_pop
disk_bdos_random_offset_ok:

                ld bc,(DOS_RECORD_SIZE)
                ld de,(DOS_REQUEST_RECORDS)
                call disk_bdos_multiply16       ; HL = requested bytes
                jp c,disk_bdos_random_fail_pop
                push hl                         ; requested bytes
                ld hl,(DOS_FILE_SIZE)
                ld de,(DOS_BYTE_OFFSET)
                or a
                sbc hl,de                       ; HL = bytes available
                pop de                          ; DE = requested bytes
                or a
                sbc hl,de
                jr c,disk_bdos_random_partial

                ld hl,(DOS_REQUEST_RECORDS)
                ld (DOS_TRANSFER_RECORDS),hl
                ex de,hl
                ld (DOS_TRANSFER_BYTES),hl
                xor a
                ld (DOS_TRANSFER_STATUS),a
                jr disk_bdos_random_copy

disk_bdos_random_partial:
                add hl,de                       ; restore bytes available
                ld de,(DOS_RECORD_SIZE)
                call disk_bdos_divide16         ; HL = complete records
                ld (DOS_TRANSFER_RECORDS),hl
                ld bc,(DOS_RECORD_SIZE)
                ex de,hl                        ; DE = complete records
                call disk_bdos_multiply16
                jp c,disk_bdos_random_fail_pop
                ld (DOS_TRANSFER_BYTES),hl
                ld a,1
                ld (DOS_TRANSFER_STATUS),a

disk_bdos_random_copy:
                ld hl,(DOS_BYTE_OFFSET)
                ld de,DOS_STAGE
                add hl,de                       ; HL = source
                ld bc,(DOS_TRANSFER_BYTES)
                push hl
                add hl,bc
                ld a,h
                cp #f0
                jp nc,disk_bdos_random_fail_source
                pop hl
                ld de,(DOS_DTA)
                ld a,b
                or c
                jr z,disk_bdos_random_update
                ld a,d
                cp #40
                jr c,disk_bdos_random_page0
                cp #80
                jr c,disk_bdos_random_page1
                jr disk_bdos_random_copy_now
disk_bdos_random_page0:
                push hl
                push de
                push bc
                ex de,hl                       ; HL = page-0 destination
                add hl,bc
                ld a,h
                cp #40
                jr nc,disk_bdos_random_fail_page0
                pop bc
                pop de
                pop hl
                push hl
                push de
                push bc
                call disk_bdos_prepare_page0
                pop bc
                pop de
                pop hl
                jr disk_bdos_random_copy_now
disk_bdos_random_page1:
                push hl
                push de
                push bc
                ex de,hl                       ; HL = page-1 destination
                add hl,bc
                dec hl                         ; last byte must remain in page 1
                ld a,h
                cp #80
                jr nc,disk_bdos_random_fail_page1
                pop bc
                pop de
                pop hl
                call DOS_PAGE1_COPY
                jr disk_bdos_random_update
disk_bdos_random_copy_now:
                ldir

disk_bdos_random_update:
                ld de,(DOS_OPEN_FCB)
                ld hl,FCB_RANDOM_RECORD
                add hl,de
                ld e,(hl)
                inc hl
                ld d,(hl)
                ld bc,(DOS_TRANSFER_RECORDS)
                ex de,hl
                add hl,bc
                ex de,hl
                dec hl
                ld (hl),e
                inc hl
                ld (hl),d
                inc hl
                jr nc,disk_bdos_random_no_carry
                inc (hl)
disk_bdos_random_no_carry:
                call disk_bdos_runtime_entry_install
                ld de,(DOS_OPEN_FCB)
                ld hl,(DOS_TRANSFER_RECORDS)
                ld a,(DOS_TRANSFER_STATUS)
                pop iy                          ; fixed kernel ABI returns FCB in IY
                ld ix,DOS_DPB
                ld de,0                         ; fixed kernel RDBLK return ABI
                cp a                            ; publish the completed-read flags
                ret
disk_bdos_random_fail_record:
                pop de
                jr disk_bdos_random_fail_pop
disk_bdos_random_fail_page0:
                pop bc
                pop de
                pop hl
                jr disk_bdos_random_fail_pop
disk_bdos_random_fail_page1:
                pop bc
                pop de
                pop hl
                jr disk_bdos_random_fail_pop
disk_bdos_random_fail_source:
                pop hl
disk_bdos_random_fail_pop:
                pop iy
                ld ix,DOS_DPB
                ld de,0
                ld hl,0
                ld a,1
                ret

; BC * DE -> HL, carry set on 16-bit overflow.
disk_bdos_multiply16:
                ld hl,0
disk_bdos_multiply_loop:
                srl d
                rr e
                jr nc,disk_bdos_multiply_skip
                add hl,bc
                jr c,disk_bdos_multiply_overflow
disk_bdos_multiply_skip:
                ld a,d
                or e
                jr z,disk_bdos_multiply_done
                sla c
                rl b
                jr c,disk_bdos_multiply_overflow
                jr disk_bdos_multiply_loop
disk_bdos_multiply_done:
                or a
                ret
disk_bdos_multiply_overflow:
                scf
                ret

; HL / DE -> HL quotient, DE remainder. The staged-file limit bounds this
; straightforward subtraction loop to fewer than 10,000 iterations.
disk_bdos_divide16:
                ld bc,0
disk_bdos_divide_loop:
                or a
                sbc hl,de
                jr c,disk_bdos_divide_done
                inc bc
                jr disk_bdos_divide_loop
disk_bdos_divide_done:
                add hl,de
                ex de,hl
                ld h,b
                ld l,c
                or a
                ret

disk_bdos_set_random_record:
                push de
                ld hl,FCB_CURRENT_BLOCK
                add hl,de
                ld e,(hl)
                inc hl
                ld d,(hl)
                ld hl,7
disk_bdos_set_random_shift:
                sla e
                rl d
                dec l
                jr nz,disk_bdos_set_random_shift
                pop hl
                push hl
                ld bc,FCB_CURRENT_RECORD
                add hl,bc
                ld c,(hl)
                ld b,0
                ex de,hl
                add hl,bc
                ex de,hl
                pop hl
                push hl
                ld bc,FCB_RANDOM_RECORD
                add hl,bc
                ld (hl),e
                inc hl
                ld (hl),d
                inc hl
                ld (hl),0
                pop de
                xor a
                ret

; Map the BIOS-discovered RAM slot into page 0 once, clear the CP/M zero page,
; and publish CALL 5.  ENASLT's page-0 trampoline returns to this page-1 ROM
; after the BIOS vectors disappear.  This path is identical on MSX1 and MSX2.
disk_bdos_prepare_page0:
                ld a,(DOS_PAGE0_RAM)
                or a
                ret nz
                in a,(PPI_SLOT)
                and #03
                ld (DOS_BIOS_PRIMARY),a
                ld a,(RAMAD0)
                ld h,0
                call BIOS_ENASLT
                xor a
                ld hl,0
                ld (hl),a
                ld de,1
                ld bc,#00ff
                ldir
                ld hl,#0005
                ld (hl),#c3
                inc hl
                ld (hl),#7d
                inc hl
                ld (hl),#f3
                ld hl,#0038
                ld (hl),#c3
                inc hl
                ld de,DOS_IRQ_GATE
                ld (hl),e
                inc hl
                ld (hl),d
                ld a,1
                ld (DOS_PAGE0_RAM),a
                ei
                ret

disk_bdos_find_first:
                ld a,#ff
                ret
disk_bdos_find_next:
                ld a,#ff
                ret
