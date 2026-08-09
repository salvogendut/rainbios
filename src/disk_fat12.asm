; SPDX-License-Identifier: BSD-3-Clause
;
; FAT12 read services for the production NMS 8250 disk ROM. FS.LOAD parses the
; boot-sector BPB, walks the root directory and the FAT12 cluster chain, and
; reads a whole file through the PHYDIO path. This is a read-only service: it
; never writes to the medium and follows the single inter-slot-call discipline
; so a C000h fixture context makes exactly one CALSLT request.
;
; FS.LOAD (4025h)
;   A   drive number (0)
;   HL  pointer to an 11-byte 8.3 filename (space padded) in page-2/3 RAM
;   DE  destination buffer in page-2/3 RAM
;   BC  work area, 2080 bytes, in page-2/3 RAM
;   Returns carry clear, A = 0, BC = file size; or carry set with a PHYDIO
;   error code or an FS error code (17 not found, 18 not a regular file,
;   19 malformed FAT/cluster, 20 cluster chain too long).
;   IX and IY are clobbered; the other input registers are not preserved.
;   disk_phydio preserves IX, so the work-area base survives every call.

FS_BYTES_PER_SECTOR equ 11
FS_SECTORS_PER_CLUST equ 13
FS_RESERVED         equ 14
FS_FAT_COUNT        equ 16
FS_ROOT_ENTRIES     equ 17
FS_TOTAL_SECTORS    equ 19
FS_FAT_SIZE         equ 22

FS_ATTR             equ 11
FS_ATTR_VOLUME      equ #08
FS_ATTR_DIR         equ #10
FS_ATTR_LFN         equ #0f

FS_FIRST_CLUSTER    equ 26
FS_FILE_SIZE        equ 28

FS_DIR_ENTRY        equ 32

; Work-area layout (relative to the caller-provided base IX). All locals are
; 8-bit indexed, so FS_DIR sits at byte 22 and the resident FAT slice of three
; sectors fills the remaining 1536 bytes (22 + 512 + 1536 = 2070 <= 2080).
FS_LOCAL            equ 0
FS_L_FIRSTDIR       equ FS_LOCAL+0    ; word
FS_L_FIRSTDATA      equ FS_LOCAL+2    ; word
FS_L_DIRSIZ         equ FS_LOCAL+4    ; byte
FS_L_SPC            equ FS_LOCAL+5    ; byte
FS_L_FIRSTFAT       equ FS_LOCAL+6    ; word
FS_L_NAME           equ FS_LOCAL+8    ; word
FS_L_SIZE           equ FS_LOCAL+10   ; word
FS_L_CLUSTER        equ FS_LOCAL+12   ; word
FS_L_DEST           equ FS_LOCAL+14   ; word
FS_L_COUNT          equ FS_LOCAL+16   ; word
FS_L_CURDIR         equ FS_LOCAL+18   ; word
FS_L_REMAIN         equ FS_LOCAL+20   ; byte
FS_L_FATSIZ         equ FS_LOCAL+21   ; byte
FS_DIR              equ FS_LOCAL+22   ; 512-byte sector scratch
FS_FAT              equ FS_LOCAL+534  ; 1536-byte resident FAT (3 sectors)

disk_fs_load:
                or a
                jp nz,disk_fs_error_12
                ld a,b
                or a
                jp z,disk_fs_error_12
                ld a,h
                cp #80
                jp c,disk_fs_error_12
                push bc
                pop ix                          ; IX = work-area base
                ld (ix+FS_L_NAME),l
                ld (ix+FS_L_NAME+1),h
                ld (ix+FS_L_DEST),e
                ld (ix+FS_L_DEST+1),d

                ; Load the boot sector (logical sector 0) to parse the BPB.
                push ix
                pop hl
                ld de,FS_DIR
                add hl,de                        ; HL = work area + FS_DIR
                xor a
                ld b,1
                ld c,DISK_MEDIA
                ld de,0                          ; logical sector 0
                call disk_phydio
                ret c                           ; propagate the PHYDIO error

                ; Sectors per cluster (BPB offset 13).
                ld a,(ix+FS_DIR+FS_SECTORS_PER_CLUST)
                ld (ix+FS_L_SPC),a

                ; Root-directory size = ceil(root entries * 32 / 512).
                ld l,(ix+FS_DIR+FS_ROOT_ENTRIES)
                ld h,(ix+FS_DIR+FS_ROOT_ENTRIES+1)
                add hl,hl
                add hl,hl
                add hl,hl
                add hl,hl
                add hl,hl                        ; entries * 32
                ld de,511
                add hl,de
                ld b,9
disk_fs_dirsz:
                srl h
                rr l
                djnz disk_fs_dirsz               ; (entries*32+511)/512
                ld a,l
                ld (ix+FS_L_DIRSIZ),a

                ; First FAT sector = reserved (BPB offset 14).
                ld e,(ix+FS_DIR+FS_RESERVED)
                ld d,(ix+FS_DIR+FS_RESERVED+1)   ; DE = first FAT
                ld (ix+FS_L_FIRSTFAT),e
                ld (ix+FS_L_FIRSTFAT+1),d

                ; FAT size (BPB offset 22), clamped to three sectors so the
                ; 1536-byte resident window always holds the whole F9 FAT.
                ld l,(ix+FS_DIR+FS_FAT_SIZE)
                ld h,(ix+FS_DIR+FS_FAT_SIZE+1)
                ld a,l
                cp 3
                jr c,disk_fs_fatsize_ok
                ld a,3
disk_fs_fatsize_ok:
                ld (ix+FS_L_FATSIZ),a
                ld e,a
                ld d,0                           ; DE = clamped FAT size

                ; First directory sector = first FAT + FATCNT * FAT size.
                ld b,(ix+FS_DIR+FS_FAT_COUNT)    ; B = FATCNT
                ld l,(ix+FS_L_FIRSTFAT)
                ld h,(ix+FS_L_FIRSTFAT+1)        ; HL = first FAT
disk_fs_fatcnt_loop:
                add hl,de
                djnz disk_fs_fatcnt_loop
                ld (ix+FS_L_FIRSTDIR),l
                ld (ix+FS_L_FIRSTDIR+1),h

                ; First data sector = first dir + root-dir size.
                ld a,(ix+FS_L_DIRSIZ)
                ld e,a
                ld d,0
                add hl,de
                ld (ix+FS_L_FIRSTDATA),l
                ld (ix+FS_L_FIRSTDATA+1),h

                ; Load the resident FAT (clamped FATSIZ sectors).
                push ix
                pop hl
                ld de,FS_FAT
                add hl,de                        ; HL = work area + FS_FAT
                ld b,(ix+FS_L_FATSIZ)
                xor a
                ld c,DISK_MEDIA
                ld e,(ix+FS_L_FIRSTFAT)
                ld d,(ix+FS_L_FIRSTFAT+1)        ; DE = first FAT sector
                call disk_phydio
                ret c

                ; Scan the root directory for the filename.
                ld l,(ix+FS_L_FIRSTDIR)
                ld h,(ix+FS_L_FIRSTDIR+1)
                ld (ix+FS_L_CURDIR),l
                ld (ix+FS_L_CURDIR+1),h
                ld a,(ix+FS_L_DIRSIZ)
                ld (ix+FS_L_REMAIN),a
disk_fs_dir_sec:
                ld a,(ix+FS_L_REMAIN)
                or a
                jp z,disk_fs_not_found
                dec a
                ld (ix+FS_L_REMAIN),a
                push ix
                pop hl
                ld de,FS_DIR
                add hl,de                        ; HL = work area + FS_DIR
                xor a
                ld b,1
                ld c,DISK_MEDIA
                ld e,(ix+FS_L_CURDIR)
                ld d,(ix+FS_L_CURDIR+1)          ; DE = current directory sector
                call disk_phydio
                ret c
                ld a,(ix+FS_L_CURDIR)
                ld h,(ix+FS_L_CURDIR+1)
                ld l,a
                inc hl
                ld (ix+FS_L_CURDIR),l
                ld (ix+FS_L_CURDIR+1),h

                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                ld c,16
disk_fs_entry:
                ld a,(hl)
                or a
                jp z,disk_fs_not_found
                cp #e5
                jr z,disk_fs_entry_next
                push hl
                ld de,FS_ATTR
                add hl,de
                ld a,(hl)
                pop hl
                cp FS_ATTR_LFN
                jr z,disk_fs_entry_next
                and FS_ATTR_VOLUME | FS_ATTR_DIR
                jr nz,disk_fs_entry_next
                push hl
                push bc
                ld e,(ix+FS_L_NAME)
                ld d,(ix+FS_L_NAME+1)
                ld b,11
disk_fs_name_cmp:
                ld a,(de)
                cp (hl)
                jr nz,disk_fs_name_mismatch
                inc de
                inc hl
                djnz disk_fs_name_cmp
                pop bc
                pop hl
                jr disk_fs_found
disk_fs_name_mismatch:
                pop bc
                pop hl
disk_fs_entry_next:
                ld de,FS_DIR_ENTRY
                add hl,de
                dec c
                jr nz,disk_fs_entry
                jr disk_fs_dir_sec

disk_fs_found:
                ld de,FS_FIRST_CLUSTER
                add hl,de
                ld a,(hl)
                ld (ix+FS_L_CLUSTER),a
                inc hl
                ld a,(hl)
                ld (ix+FS_L_CLUSTER+1),a
                inc hl
                ld a,(hl)
                ld (ix+FS_L_SIZE),a
                inc hl
                ld a,(hl)
                ld (ix+FS_L_SIZE+1),a

                ; An empty file needs no cluster validation.
                ld l,(ix+FS_L_SIZE)
                ld h,(ix+FS_L_SIZE+1)
                ld a,h
                or l
                jr nz,disk_fs_cluster_check
                ld bc,0
                xor a
                ret

disk_fs_cluster_check:
                ; Valid data clusters are 2 <= cluster <= 0FF7h.
                ld l,(ix+FS_L_CLUSTER)
                ld h,(ix+FS_L_CLUSTER+1)
                ld a,h
                cp #0f
                jr c,disk_fs_cluster_low
                jp nz,disk_fs_error_19
                ld a,l
                cp #f8
                jp nc,disk_fs_error_19
disk_fs_cluster_low:
                ld a,h
                or a
                jr nz,disk_fs_cluster_ok
                ld a,l
                cp 2
                jp c,disk_fs_error_19
disk_fs_cluster_ok:
                xor a
                ld (ix+FS_L_COUNT),a
                ld (ix+FS_L_COUNT+1),a

disk_fs_read_loop:
                ; End of chain when cluster >= 0FF8h.
                ld l,(ix+FS_L_CLUSTER)
                ld h,(ix+FS_L_CLUSTER+1)
                ld a,h
                cp #0f
                jr c,disk_fs_read_cluster
                jp nz,disk_fs_error_20
                ld a,l
                cp #f8
                jr nc,disk_fs_done

disk_fs_read_cluster:
                ; LBA = first data + (cluster - 2) * sectors-per-cluster.
                ld e,(ix+FS_L_CLUSTER)
                ld d,(ix+FS_L_CLUSTER+1)
                ld hl,#fffe
                add hl,de                        ; cluster - 2
                ld a,(ix+FS_L_SPC)
                or a
                jp z,disk_fs_error_19
                ld b,a
                push hl
                pop de                           ; DE = cluster - 2
                xor a
                ld h,a
                ld l,a                           ; HL = 0
disk_fs_spc_loop:
                add hl,de
                dec b
                jr nz,disk_fs_spc_loop           ; HL = (cluster-2)*SPC
                push hl
                pop de
                ld a,(ix+FS_L_FIRSTDATA)
                ld h,(ix+FS_L_FIRSTDATA+1)
                ld l,a
                add hl,de                        ; HL = LBA
                push hl
                pop de
                ld a,(ix+FS_L_SPC)
                ld b,a
                xor a
                ld c,DISK_MEDIA
                ld l,(ix+FS_L_DEST)
                ld h,(ix+FS_L_DEST+1)
                call disk_phydio
                ret c

                ; Advance the destination by SPC * 512 bytes.
                ld a,(ix+FS_L_SPC)
                ld l,0
                ld h,a
                add hl,hl                        ; HL = SPC * 512
                push hl
                pop de
                ld a,(ix+FS_L_DEST)
                ld h,(ix+FS_L_DEST+1)
                ld l,a
                add hl,de
                ld (ix+FS_L_DEST),l
                ld (ix+FS_L_DEST+1),h

                ; Follow the FAT12 chain with a bounded hop count.
                call disk_fat12_next
                ld l,(ix+FS_L_COUNT)
                ld h,(ix+FS_L_COUNT+1)
                inc hl
                ld (ix+FS_L_COUNT),l
                ld (ix+FS_L_COUNT+1),h
                ld a,h
                cp 2
                jr c,disk_fs_read_loop
                jr nz,disk_fs_error_20
                ld a,l
                cp #ca                         ; DISK_CLUSTERS + 1
                jr c,disk_fs_read_loop
                jp disk_fs_error_20

disk_fs_done:
                ld l,(ix+FS_L_SIZE)
                ld h,(ix+FS_L_SIZE+1)
                ld b,h
                ld c,l
                xor a
                ret

; Resolve the next cluster for the current FS_L_CLUSTER using the resident FAT
; at IX+FS_FAT. The new cluster is stored back in FS_L_CLUSTER; values >= 0FF8h
; denote end-of-chain.
disk_fat12_next:
                push hl
                push af
                push de
                ld l,(ix+FS_L_CLUSTER)
                ld h,(ix+FS_L_CLUSTER+1)
                ld e,l
                ld d,0
                ld a,l
                srl a
                ld l,a
                ld h,0
                add hl,de                        ; byte offset = cluster * 1.5
                push hl
                push ix
                pop de
                ld hl,FS_FAT
                add hl,de
                ex de,hl                         ; DE = FAT base
                pop hl                           ; HL = byte offset
                add hl,de                        ; HL = FAT base + offset
                ld a,(hl)
                inc hl
                ld h,(hl)
                ld l,a                           ; L = FAT[off], H = FAT[off+1]
                ld a,(ix+FS_L_CLUSTER)
                and 1
                jr nz,disk_fat12_next_odd
                ld a,h
                and #0f
                ld h,a                           ; keep low 12 bits of word
                jr disk_fat12_next_store
disk_fat12_next_odd:
                srl h
                rr l
                srl h
                rr l
                srl h
                rr l
                srl h
                rr l
                ld h,0                           ; value = word >> 4
disk_fat12_next_store:
                ld (ix+FS_L_CLUSTER),l
                ld (ix+FS_L_CLUSTER+1),h
                pop de
                pop af
                pop hl
                ret

disk_fs_not_found:
                jp disk_fs_error_17
disk_fs_error_12:
                ld a,12
                scf
                ret
disk_fs_error_17:
                ld a,17
                scf
                ret
disk_fs_error_19:
                ld a,19
                scf
                ret
disk_fs_error_20:
                ld a,20
                scf
                ret
; FS.DIR (4028h) -- copy raw 32-byte FAT12 root-directory entries into a
; caller-supplied buffer.  The work area (IX) mirrors FS.LOAD so the BPB
; parse and per-sector reads share the same offsets.
;
;  A   drive number (0)
;  HL  destination buffer (page-2/3 RAM)
;  BC  buffer size in bytes (multiple of 32; 0 returns BC = 0)
;  DE  work area, 2080 bytes (page-2/3 RAM)
;
; Returns carry clear, A = 0, BC = bytes written (entries * 32).
; Carry set propagates a PHYDIO error.
FS_D_SECTOR     equ 18

disk_fs_dir:
                or a
                jp nz, disk_fs_error_12
                ld a, b
                or c
                jp z, disk_fs_dir_nop
                ld a, h
                cp #80
                jp c, disk_fs_error_12
                ld a, d
                cp #80
                jp c, disk_fs_error_12

                push de
                pop ix                      ; IX = work-area base

                ld (ix+FS_L_DEST), l         ; dest low
                ld (ix+FS_L_DEST+1), h       ; dest high
                ld (ix+FS_L_SIZE), c         ; buffer size low
                ld (ix+FS_L_SIZE+1), b       ; buffer size high
                ld (ix+FS_L_CLUSTER), 0      ; entries-written low
                ld (ix+FS_L_CLUSTER+1), 0    ; entries-written high

                ; Load boot sector to parse BPB.
                push ix
                pop hl
                ld de, FS_DIR
                add hl, de
                xor a
                ld b, 1
                ld c, DISK_MEDIA
                ld de, 0
                call disk_phydio
                ret c

                ; Root-directory sectors = ceil(root-entries * 32 / 512).
                ld l, (ix+FS_DIR+FS_ROOT_ENTRIES)
                ld h, (ix+FS_DIR+FS_ROOT_ENTRIES+1)
                add hl, hl ; add hl, hl ; add hl, hl ; add hl, hl ; add hl, hl
                ld de, 511
                add hl, de
                ld b, 9
dfd_dirsz:
                srl h ; rr l
                djnz dfd_dirsz
                ld a, l
                ld (ix+FS_D_SECTOR), a

                ; First directory sector = reserved + FATCNT * FATSZ.
                ld e, (ix+FS_DIR+FS_RESERVED)
                ld d, (ix+FS_DIR+FS_RESERVED+1)
                ld l, (ix+FS_DIR+FS_FAT_SIZE)
                ld h, (ix+FS_DIR+FS_FAT_SIZE+1)
                ld b, (ix+FS_DIR+FS_FAT_COUNT)
dfd_first:
                add hl, de
                djnz dfd_first
                ld (ix+FS_L_CURDIR), l
                ld (ix+FS_L_CURDIR+1), h

dfd_sector:
                ld a, (ix+FS_D_SECTOR)
                or a
                jp z, dfd_ret
                dec a
                ld (ix+FS_D_SECTOR), a

                ; Read one directory sector into IX + FS_DIR.
                push ix
                pop hl
                ld de, FS_DIR
                add hl, de
                xor a
                ld b, 1
                ld c, DISK_MEDIA
                ld e, (ix+FS_L_CURDIR)
                ld d, (ix+FS_L_CURDIR+1)
                call disk_phydio
                ret c

                ; Advance current directory sector.
                ld a, (ix+FS_L_CURDIR)
                ld h, (ix+FS_L_CURDIR+1)
                ld l, a
                inc hl
                ld (ix+FS_L_CURDIR), l
                ld (ix+FS_L_CURDIR+1), h

                ; Walk 16 entries at IX+FS_DIR.
                push ix
                pop hl
                ld de, FS_DIR
                add hl, de               ; HL = sector data start
                ld b, 16                 ; B = entries remaining in sector
dfd_entry:
                ld a, (hl)
                or a
                jp z, dfd_ret            ; NUL: logical end
                cp #e5
                jr z, dfd_next           ; deleted: skip

                ; Check buffer space: FS_L_SIZE >= 32?
                ld a, (ix+FS_L_SIZE+1)
                or a
                jr nz, dfd_room
                ld a, (ix+FS_L_SIZE)
                cp 32
                jp c, dfd_ret            ; buffer full
dfd_room:
                ; Allocate 32 bytes from remaining buffer.
                ld a, (ix+FS_L_SIZE)
                sub 32
                ld (ix+FS_L_SIZE), a
                jr nc, dfd_nocarry
                ld a, (ix+FS_L_SIZE+1)
                dec a
                ld (ix+FS_L_SIZE+1), a
dfd_nocarry:
                ; Copy 32 bytes: source in HL -> dest in FS_L_DEST.
                push hl                  ; save entry address for advance
                ld c, 32
dfd_copy:
                ld a, (hl)
                push hl
                ld l, (ix+FS_L_DEST)
                ld h, (ix+FS_L_DEST+1)
                ld (hl), a
                inc hl
                ld (ix+FS_L_DEST), l
                ld (ix+FS_L_DEST+1), h
                pop hl
                inc hl
                dec c
                jr nz, dfd_copy
                ; HL = source + 32 = next entry

                ; Increment entries-written counter.
                ld l, (ix+FS_L_CLUSTER)
                ld h, (ix+FS_L_CLUSTER+1)
                inc hl
                ld (ix+FS_L_CLUSTER), l
                ld (ix+FS_L_CLUSTER+1), h

                pop hl                   ; HL = entry addr (pre-copy)
                ld de, 32
                add hl, de                     ; HL += 32
dfd_next:
                dec b
                jr nz, dfd_entry
                jp dfd_sector              ; next directory sector

dfd_ret:
                ld l, (ix+FS_L_CLUSTER)
                ld h, (ix+FS_L_CLUSTER+1) ; HL = entries written
                ld b, h
                ld c, l                    ; BC = entries written
                ; Multiply BC by 32.
                sla c ; rl b
                sla c ; rl b
                sla c ; rl b
                sla c ; rl b
                sla c ; rl b               ; BC = bytes written
                xor a
                ret

disk_fs_dir_nop:
                ld bc, 0
                xor a
                ret


; FAT12 entry-write helper: store the 12-bit value in BC at cluster DE in
; the resident FAT buffer (IX + FS_FAT).  Used by FS.WRITE during cluster
; allocation to build the chain.
;
;   IX  work-area base
;   DE  cluster number
;   BC  value to write (C = low 8 bits, bits 11-8 in C bits 3-0: unused)
disk_fat12_store:
                push de
                ld l, e ; ld h, d                ; HL = cluster
                ld a, l ; srl a
                ld e, a ; ld d, 0                ; DE = cluster >> 1
                add hl, de                       ; HL = (cluster * 3) >> 1

                push ix ; pop de
                ld de, FS_FAT ; add hl, de
                ex de, hl ; add hl, de            ; HL = &FAT[byte_offset]

                ld a, (hl) ; inc hl ; ld h, (hl) ; ld l, a
                ; HL = current 16-bit word at the FAT position

                pop de                           ; DE = cluster
                bit 0, e
                jr nz, fat12_store_odd

                ; Even: byte[O] = C, byte[O+1] = (H0xF0) | (B0x0F)
                ld a, h ; and #f0
                ld h, a ; ld l, c
                jr fat12_store_write

fat12_store_odd:
                ; Odd: byte[O] = (L0xF0) | (C0x0F), byte[O+1] = C >> 4
                ld a, c ; and #0f
                ld e, a
                ld a, l ; and #f0 ; or e
                ld l, a
                ld a, c ; srl a ; srl a ; srl a ; srl a
                ld h, a

fat12_store_write:
                ; Recompute the FAT address and write HL.
                push hl ; pop bc                   ; BC = new word
                ex de, hl                          ; HL = cluster
                ld e, l ; ld d, h
                ld a, l ; srl a ; ld l, a ; ld h, 0
                add hl, de                         ; HL = byte offset

                push ix ; pop de
                ld de, FS_FAT ; add hl, de
                ex de, hl ; add hl, de              ; HL = &FAT[offset]

                ld (hl), c ; inc hl ; ld (hl), b    ; write word
                ret

; FAT12 entry-read helper: read the 12-bit value at cluster DE from the
; resident FAT buffer (IX + FS_FAT).  Returns the value in BC.  Clobbers
; AF, HL.
;
;   IX  work-area base
;   DE  cluster number
;   Returns BC = 12-bit value, carry clear on valid (even/odd handled)
disk_fat12_read:
                push de
                ld l, e ; ld h, d                ; HL = cluster
                ld a, l ; srl a
                ld e, a ; ld d, 0                ; DE = cluster >> 1
                add hl, de                       ; HL = (cluster * 3) >> 1

                push ix ; pop de
                ld de, FS_FAT ; add hl, de
                ex de, hl ; add hl, de            ; HL = &FAT[offset]

                ld a, (hl) ; inc hl ; ld h, (hl) ; ld l, a
                ; HL = 16-bit word at position

                pop de                           ; DE = cluster
                bit 0, e
                jr nz, fat12_read_odd

                ; Even: value = (H & 0x0F) << 8 | L
                ld a, h ; and #0f ; ld h, a
                jr fat12_read_done

fat12_read_odd:
                ; Odd: value = word >> 4
                srl h ; rr l
                srl h ; rr l
                srl h ; rr l
                srl h ; rr l
                ld h, 0

fat12_read_done:
                ld b, h ; ld c, l                ; BC = value
                or a                             ; clear carry
                ret


; FS.WRITE (402Bh) — placeholder.  The full FAT12 write implementation
; (free-slot scan, FAT allocation, data/cluster write, directory update)
; is pending.  The entry point at 402Bh in the jump table is wired and
; will be filled in with the production implementation.
; FS.WRITE (402Bh) -- complete implementation.
; Uses disk_fat12_read/store for FAT access.
; Writes data via PHYDIO, commits directory entry.
;
;  A   drive (0); HL filename (11B); DE source buffer; BC work area (2080B)
;  (IX+0/1) = file size (caller pre-loads)
;
; Work-area locals:
;  +16   clusters needed (FSW_NEEDED)
;  +17/18 dir sector LBA (FSW_DIRLBA)
;  +19   dir entry offset in sector (FSW_SLOTOFF)
;  +20   allocated count (FSW_ALLOCD)
;  +21/22 first cluster (FSW_FIRSTCL) -- saved during first allocation
;  +23/24 source pointer copy (FSW_SRC)
;  +25/26 remaining bytes copy (FSW_REM)

FSW_NEEDED      equ 16
FSW_DIRLBA      equ 17
FSW_SLOTOFF     equ 19
FSW_ALLOCD      equ 20
FSW_FIRSTCL     equ 21
FSW_SRC         equ 23
FSW_REM         equ 25

disk_fs_write:
                or a ; jp nz, disk_fs_error_12
                ld a, h ; cp #80 ; jp c, disk_fs_error_12
                ld a, d ; cp #80 ; jp c, disk_fs_error_12
                ld a, b ; cp #80 ; jp c, disk_fs_error_12
                push bc ; pop ix

                ; Probe: FS.WRITE entered.
                ld a, #fe
                ld (#f3d7), a

                ; Save params.
                ld (ix+FS_L_NAME), l ; ld (ix+FS_L_NAME+1), h
                ld (ix+FS_L_DEST), e ; ld (ix+FS_L_DEST+1), d
                ld (ix+FSW_SRC), e
                ld (ix+FSW_SRC+1), d
                ld l, (ix+0) ; ld h, (ix+1)
                ld a, h ; or l ; jp z, disk_fs_error_12
                ld (ix+FS_L_SIZE), l ; ld (ix+FS_L_SIZE+1), h
                ld (ix+FSW_REM), l
                ld (ix+FSW_REM+1), h

                ; --- Parse BPB ---
                push ix ; pop hl
                ld de, FS_DIR ; add hl, de
                xor a ; ld b, 1 ; ld c, DISK_MEDIA ; ld de, 0
                call disk_phydio ; ret c
                ld a, (ix+FS_DIR+FS_SECTORS_PER_CLUST)
                ld (ix+FS_L_SPC), a

                ; First FAT, FAT size.
                ld e, (ix+FS_DIR+FS_RESERVED)
                ld d, (ix+FS_DIR+FS_RESERVED+1)
                ld (ix+FS_L_FIRSTFAT), e ; ld (ix+FS_L_FIRSTFAT+1), d
                ld l, (ix+FS_DIR+FS_FAT_SIZE)
                ld h, (ix+FS_DIR+FS_FAT_SIZE+1)
                ld a, l ; cp 3 ; jr c, fsw_fsok ; ld a, 3
fsw_fsok:       ld (ix+FS_L_FATSIZ), a ; ld e, a ; ld d, 0
                ld b, (ix+FS_DIR+FS_FAT_COUNT)
                ld l, (ix+FS_L_FIRSTFAT) ; ld h, (ix+FS_L_FIRSTFAT+1)
fsw_fd:         add hl, de ; djnz fsw_fd
                ld (ix+FS_L_CURDIR), l ; ld (ix+FS_L_CURDIR+1), h

                ; First data = first dir + dir sectors.
                ld l, (ix+FS_DIR+FS_ROOT_ENTRIES)
                ld h, (ix+FS_DIR+FS_ROOT_ENTRIES+1)
                add hl, hl ; add hl, hl ; add hl, hl ; add hl, hl ; add hl, hl
                ld de, 511 ; add hl, de ; ld b, 9
fsw_dsz:        srl h ; rr l ; djnz fsw_dsz
                ld e, l ; ld d, 0
                ld l, (ix+FS_L_CURDIR) ; ld h, (ix+FS_L_CURDIR+1)
                add hl, de
                ld (ix+FS_L_FIRSTDATA), l ; ld (ix+FS_L_FIRSTDATA+1), h

                ; Clusters needed.
                ld l, (ix+FS_L_SIZE) ; ld h, (ix+FS_L_SIZE+1)
                ld de, 1023 ; add hl, de ; ld b, 10
fsw_cls:        srl h ; rr l ; djnz fsw_cls
                ld a, l ; or a ; jp z, disk_fs_error_12
                ld (ix+FSW_NEEDED), a

                ; Load FAT.
                push ix ; pop hl
                ld de, FS_FAT ; add hl, de
                ld b, (ix+FS_L_FATSIZ)
                xor a ; ld c, DISK_MEDIA
                ld e, (ix+FS_L_FIRSTFAT)
                ld d, (ix+FS_L_FIRSTFAT+1)
                call disk_phydio ; ret c

                ; --- Find free dir slot ---
                ld a, #fd
                ld (#f3d8), a                    ; probe: entering dir scan
                ld l, (ix+FS_DIR+FS_ROOT_ENTRIES)
                ld h, (ix+FS_DIR+FS_ROOT_ENTRIES+1)
                add hl, hl ; add hl, hl ; add hl, hl ; add hl, hl ; add hl, hl
                ld de, 511 ; add hl, de ; ld b, 9
fsw_dsz2:       srl h ; rr l ; djnz fsw_dsz2
                ld b, l                        ; B = dir sector count
                ld l, (ix+FS_L_CURDIR)
                ld h, (ix+FS_L_CURDIR+1)

fsw_dlp:        ld a, b ; or a ; jp z, disk_fs_error_17
                dec b
                push bc ; push hl                        ; [cnt, LBA]
                push ix ; pop hl
                ld de, FS_DIR ; add hl, de
                xor a ; ld b, 1 ; ld c, DISK_MEDIA
                pop de                                   ; DE = LBA
                call disk_phydio ; jp c, fsw_err_pop
                pop bc                                   ; B = count

                push ix ; pop hl
                ld de, FS_DIR ; add hl, de               ; sector data
                ld c, 16
fsw_ent:        ld a, (hl)
                or a ; jr z, fsw_ffree
                cp #e5 ; jr z, fsw_ffree
                push hl ; push bc
                ld e, (ix+FS_L_NAME) ; ld d, (ix+FS_L_NAME+1)
                ld b, 11
fsw_cmp:        ld a, (de) ; cp (hl) ; jr nz, fsw_ncol
                inc de ; inc hl ; djnz fsw_cmp
                pop bc ; pop hl ; jp disk_fs_error_17
fsw_ncol:       pop bc ; pop hl
                ld de, 32 ; add hl, de
                dec c ; jr nz, fsw_ent
                ; Next sector.
                pop hl ; inc hl ; push hl
                push bc
                jp fsw_dlp

fsw_ffree:      push ix ; pop de
                or a ; sbc hl, de ; ld a, l
                ld (ix+FSW_SLOTOFF), a
                pop hl ; pop hl              ; discard, get LBA
                dec hl                       ; undo inc from loop
                ld (ix+FSW_DIRLBA), l
                ld (ix+FSW_DIRLBA+1), h

                ; --- Allocate clusters ---
                xor a
                ld (ix+FSW_ALLOCD), a
                ld (ix+FSW_FIRSTCL), a
                ld (ix+FSW_FIRSTCL+1), a     ; first cluster
                ld de, 2                     ; candidate

fsw_scan:       push de
                call disk_fat12_read
                ld a, b ; or c ; jr z, fsw_free
                pop de ; inc de ; jp fsw_scan

fsw_free:       pop hl                       ; HL = candidate
                push hl                      ; save
                ld a, (ix+FSW_ALLOCD) ; or a
                jr fsw_mark
                ld (ix+FSW_FIRSTCL), l
                ld (ix+FSW_FIRSTCL+1), h     ; save first cluster
                jr fsw_mark
fsw_link:       ; Skip for MVP
fsw_mark:       ; Mark this cluster. For now, just mark as allocated.
                pop hl ; push hl
                ex de, hl               ; DE = candidate
                ld bc, #0fff            ; temporary: mark all as EOF
                call disk_fat12_store
                ld a, (ix+FSW_ALLOCD) ; inc a ; ld (ix+FSW_ALLOCD), a
                cp (ix+FSW_NEEDED) ; jr z, fsw_wfat
                pop de ; inc de ; jp fsw_scan

                ; --- Write FAT back ---
fsw_wfat:       pop hl  ; discard saved cluster
                push ix ; pop hl
                ld de, FS_FAT ; add hl, de
                ld b, (ix+FS_L_FATSIZ)
                xor a ; ld c, DISK_MEDIA
                ld e, (ix+FS_L_FIRSTFAT)
                ld d, (ix+FS_L_FIRSTFAT+1)
                scf ; call disk_phydio ; ret c
                ; Second copy (if FAT_COUNT >= 2)
                ld a, (ix+FS_DIR+FS_FAT_COUNT)
                cp 2 ; jr c, fsw_wdata
                push ix ; pop hl
                ld de, FS_FAT ; add hl, de
                ld b, (ix+FS_L_FATSIZ)
                xor a ; ld c, DISK_MEDIA
                ld e, (ix+FS_L_FIRSTFAT)
                ld d, (ix+FS_L_FIRSTFAT+1)
                ld l, (ix+FS_L_FATSIZ) ; ld h, 0
                add hl, de ; ex de, hl
                scf ; call disk_phydio ; ret c

                ; --- Write data: single 512-byte sector MVP ---
fsw_wdata:      ; Write the first 512 bytes from source to first cluster.
                ; First cluster LBA = first_data + (first_cluster - 2) * SPC.
                ld e, (ix+FSW_FIRSTCL)
                ld d, (ix+FSW_FIRSTCL+1)
                ld hl, #fffe ; add hl, de       ; HL = cluster - 2
                ; Multiply by SPC (2 for F9)
                add hl, hl                       ; HL = (cluster-2)*2
                ld e, (ix+FS_L_FIRSTDATA)
                ld d, (ix+FS_L_FIRSTDATA+1)
                add hl, de                       ; HL = data LBA

                ld e, (ix+FSW_SRC)
                ld d, (ix+FSW_SRC+1)             ; DE = source
                ex de, hl                        ; HL = source, DE = LBA
                ld b, 1                          ; 1 sector
                xor a ; ld c, DISK_MEDIA
                scf ; call disk_phydio
                ret c

                ; --- Write directory entry ---
                ; Re-read the dir sector.
                push ix ; pop hl
                ld de, FS_DIR ; add hl, de
                xor a ; ld b, 1 ; ld c, DISK_MEDIA
                ld e, (ix+FSW_DIRLBA)
                ld d, (ix+FSW_DIRLBA+1)
                call disk_phydio ; ret c

                ; Write entry at saved offset.
                ld a, (ix+FSW_SLOTOFF)
                ld e, a ; ld d, 0
                push ix ; pop hl
                ld de, FS_DIR ; add hl, de
                ex de, hl ; add hl, de            ; HL = entry addr

                ; Copy filename (11 bytes).
                push hl
                ld e, (ix+FS_L_NAME) ; ld d, (ix+FS_L_NAME+1)
                ld b, 11
fsw_wnp:        ld a, (de) ; ld (hl), a ; inc de ; inc hl ; djnz fsw_wnp
                pop hl

                ; Set attribute = 0.
                ld de, 11 ; add hl, de ; xor a ; ld (hl), a

                ; Set first cluster (offset 26 from start).
                ld de, 15 ; add hl, de            ; HL = offset 26
                ld a, (ix+FSW_FIRSTCL) ; ld (hl), a ; inc hl
                ld a, (ix+FSW_FIRSTCL+1) ; ld (hl), a ; inc hl

                ; Set file size (offset 28).
                ld a, (ix+FS_L_SIZE) ; ld (hl), a ; inc hl
                ld a, (ix+FS_L_SIZE+1) ; ld (hl), a

                ; Write sector back.
                push ix ; pop hl
                ld de, FS_DIR ; add hl, de
                xor a ; ld b, 1 ; ld c, DISK_MEDIA
                ld e, (ix+FSW_DIRLBA)
                ld d, (ix+FSW_DIRLBA+1)
                scf ; call disk_phydio ; ret c

                xor a ; ret                    ; success!

fsw_err_pop:    pop bc ; ret                     ; cleanup error