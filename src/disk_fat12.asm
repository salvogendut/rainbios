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
FS_MEDIA            equ 21
FS_FAT_SIZE         equ 22

FS_ATTR             equ 11
FS_ATTR_VOLUME      equ #08
FS_ATTR_DIR         equ #10
FS_ATTR_LFN         equ #0f

FS_FIRST_CLUSTER    equ 26
FS_FILE_SIZE        equ 28

FS_DIR_ENTRY        equ 32

; Work-area layout (relative to the caller-provided base IX). All locals are
; 8-bit indexed. The 32-byte local block, 512-byte sector scratch, and
; three-sector resident FAT exactly fill the caller's 2080-byte work area.
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
FS_L_LIMIT          equ FS_LOCAL+22   ; word: bounded-load capacity
FS_L_LEFT           equ FS_LOCAL+24   ; word: bytes still to transfer
FS_L_FATCNT         equ FS_LOCAL+26   ; byte
FS_L_FIRSTNEW       equ FS_LOCAL+27   ; word: first new write cluster
FS_L_OLD            equ FS_LOCAL+29   ; word: replaced file's first cluster
FS_L_FLAGS          equ FS_LOCAL+31   ; byte
FS_DIR              equ FS_LOCAL+32   ; 512-byte sector scratch
FS_FAT              equ FS_LOCAL+544  ; 1536-byte resident FAT (3 sectors)

disk_fs_load:
                ld iy,0
                jr disk_fs_load_setup

; Private bounded variant advertised by the RBFS descriptor at 4037h.
; Inputs match FS.LOAD, with the maximum destination byte count pre-loaded at
; work-area offsets 0-1. Error 23 means that the file does not fit.
disk_fs_load_bounded:
                ld iy,1
disk_fs_load_setup:
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
                push iy
                pop bc
                ld a,c
                or a
                jr z,disk_fs_load_unbounded
                ld e,(ix+0)
                ld d,(ix+1)
                ld (ix+FS_L_LIMIT),e
                ld (ix+FS_L_LIMIT+1),d
                jr disk_fs_load_limit_ready
disk_fs_load_unbounded:
                ld a,#ff
                ld (ix+FS_L_LIMIT),a
                ld (ix+FS_L_LIMIT+1),a
disk_fs_load_limit_ready:

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
                inc hl
                ld a,(hl)
                inc hl
                or (hl)
                jp nz,disk_fs_error_23

                ; Reject the file before any destination write if its exact
                ; directory size exceeds the caller's bounded capacity.
                ld l,(ix+FS_L_SIZE)
                ld h,(ix+FS_L_SIZE+1)
                ld e,(ix+FS_L_LIMIT)
                ld d,(ix+FS_L_LIMIT+1)
                or a
                sbc hl,de
                jp nc,disk_fs_load_limit_equal
                jr disk_fs_load_limit_ok
disk_fs_load_limit_equal:
                jp nz,disk_fs_error_23
disk_fs_load_limit_ok:

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
                ld l,(ix+FS_L_SIZE)
                ld h,(ix+FS_L_SIZE+1)
                ld (ix+FS_L_LEFT),l
                ld (ix+FS_L_LEFT+1),h
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
                jp nc,disk_fs_error_19

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
                ld (ix+FS_L_CURDIR),l
                ld (ix+FS_L_CURDIR+1),h          ; current cluster LBA
                ld a,(ix+FS_L_SPC)
                ld (ix+FS_L_REMAIN),a

disk_fs_read_sector:
                ld a,(ix+FS_L_LEFT)
                ld l,a
                ld a,(ix+FS_L_LEFT+1)
                or l
                jp z,disk_fs_read_file_done

                ; Full sectors go directly to the destination. The final
                ; partial sector is staged in FS_DIR and copied exactly, so a
                ; bounded load never writes beyond the advertised file size.
                ld a,(ix+FS_L_LEFT+1)
                cp 2
                jr c,disk_fs_read_partial
                ld l,(ix+FS_L_DEST)
                ld h,(ix+FS_L_DEST+1)
                ld e,(ix+FS_L_CURDIR)
                ld d,(ix+FS_L_CURDIR+1)
                ld b,1
                ld c,DISK_MEDIA
                xor a
                call disk_phydio
                ret c
                ld l,(ix+FS_L_DEST)
                ld h,(ix+FS_L_DEST+1)
                inc h
                inc h
                ld (ix+FS_L_DEST),l
                ld (ix+FS_L_DEST+1),h
                ld a,(ix+FS_L_LEFT+1)
                sub 2
                ld (ix+FS_L_LEFT+1),a
                jr disk_fs_read_sector_advance

disk_fs_read_partial:
                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                ld e,(ix+FS_L_CURDIR)
                ld d,(ix+FS_L_CURDIR+1)
                ld b,1
                ld c,DISK_MEDIA
                xor a
                call disk_phydio
                ret c
                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                ld e,(ix+FS_L_DEST)
                ld d,(ix+FS_L_DEST+1)
                ld c,(ix+FS_L_LEFT)
                ld b,(ix+FS_L_LEFT+1)
                ldir
                xor a
                ld (ix+FS_L_LEFT),a
                ld (ix+FS_L_LEFT+1),a

disk_fs_read_sector_advance:
                ld l,(ix+FS_L_CURDIR)
                ld h,(ix+FS_L_CURDIR+1)
                inc hl
                ld (ix+FS_L_CURDIR),l
                ld (ix+FS_L_CURDIR+1),h
                dec (ix+FS_L_REMAIN)
                jp nz,disk_fs_read_sector
                ld a,(ix+FS_L_LEFT)
                ld l,a
                ld a,(ix+FS_L_LEFT+1)
                or l
                jp z,disk_fs_read_file_done

                ; The directory size requires another cluster. Follow and
                ; validate the FAT12 chain with a bounded hop count.
                call disk_fat12_next
                ld l,(ix+FS_L_CLUSTER)
                ld h,(ix+FS_L_CLUSTER+1)
                ld a,h
                cp #0f
                jr c,disk_fs_read_next_low
                jp nz,disk_fs_error_19
                ld a,l
                cp #f8
                jp nc,disk_fs_error_19
disk_fs_read_next_low:
                ld a,h
                or a
                jr nz,disk_fs_read_next_ok
                ld a,l
                cp 2
                jp c,disk_fs_error_19
disk_fs_read_next_ok:
                ld l,(ix+FS_L_COUNT)
                ld h,(ix+FS_L_COUNT+1)
                inc hl
                ld (ix+FS_L_COUNT),l
                ld (ix+FS_L_COUNT+1),h
                ld a,h
                cp 2
                jp c,disk_fs_read_loop
                jp nz,disk_fs_error_20
                ld a,l
                cp #ca                         ; DISK_CLUSTERS + 1
                jp c,disk_fs_read_loop
                jp disk_fs_error_20

disk_fs_read_file_done:
                ; The FAT must end where the exact directory size ends.
                call disk_fat12_next
                ld l,(ix+FS_L_CLUSTER)
                ld h,(ix+FS_L_CLUSTER+1)
                ld a,h
                cp #0f
                jp c,disk_fs_error_19
                jp nz,disk_fs_error_19
                ld a,l
                cp #f8
                jp c,disk_fs_error_19

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
                ld d,h                           ; DE = complete cluster number
                srl h
                rr l                             ; HL = cluster / 2
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
                rr l                             ; value = word >> 4
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
disk_fs_error_23:
                ld a,23
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
; FS.DIR owns the shared FS_L_REMAIN byte while it runs. Do not place this at
; FS_L_CURDIR (18): doing so aliases the root-sector LBA and turns the first
; read into a FAT-sector read when the remaining-sector count is decremented.
FS_D_SECTOR     equ FS_L_REMAIN

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
                ld (ix+FS_L_FLAGS), 0        ; raw-directory mode

dfd_boot:

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

                ld a,(ix+FS_L_FLAGS)
                or a
                jr z,dfd_geometry
                ld hl,dfd_catalog_header
                call dfd_print_text

                ; Root-directory sectors = ceil(root-entries * 32 / 512).
dfd_geometry:
                ld l, (ix+FS_DIR+FS_ROOT_ENTRIES)
                ld h, (ix+FS_DIR+FS_ROOT_ENTRIES+1)
                add hl, hl
                add hl, hl
                add hl, hl
                add hl, hl
                add hl, hl
                ld de, 511
                add hl, de
                ld b, 9
dfd_dirsz:
                srl h
                rr l
                djnz dfd_dirsz
                ld a, l
                ld (ix+FS_D_SECTOR), a

                ; First directory sector = reserved + FATCNT * FATSZ.
                ld e, (ix+FS_DIR+FS_FAT_SIZE)
                ld d, (ix+FS_DIR+FS_FAT_SIZE+1)
                ld l, (ix+FS_DIR+FS_RESERVED)
                ld h, (ix+FS_DIR+FS_RESERVED+1)
                ld b, (ix+FS_DIR+FS_FAT_COUNT)
dfd_first:
                add hl, de
                djnz dfd_first
                ld (ix+FS_L_CURDIR), l
                ld (ix+FS_L_CURDIR+1), h

                ; The text catalogue also reports allocation-unit space.
                ; Keep the first FAT resident while the directory sectors use
                ; the separate FS_DIR scratch buffer.  Raw FS.DIR callers do
                ; not need the FAT and retain their existing read sequence.
                ld a,(ix+FS_L_FLAGS)
                or a
                jr z,dfd_sector
                ld e,(ix+FS_DIR+FS_RESERVED)
                ld d,(ix+FS_DIR+FS_RESERVED+1)
                ld (ix+FS_L_FIRSTFAT),e
                ld (ix+FS_L_FIRSTFAT+1),d
                ld l,(ix+FS_DIR+FS_FAT_SIZE)
                ld h,(ix+FS_DIR+FS_FAT_SIZE+1)
                ld a,h
                or a
                jp nz,disk_fs_error_12
                ld a,l
                or a
                jp z,disk_fs_error_12
                cp DISK_FAT_SIZE+1
                jp nc,disk_fs_error_12
                ld (ix+FS_L_FATSIZ),a
                push ix
                pop hl
                ld de,FS_FAT
                add hl,de
                ld b,(ix+FS_L_FATSIZ)
                ld e,(ix+FS_L_FIRSTFAT)
                ld d,(ix+FS_L_FIRSTFAT+1)
                ld c,DISK_MEDIA
                xor a
                call disk_phydio
                ret c

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

                ld a,(ix+FS_L_FLAGS)
                or a
                jr z,dfd_buffer_entry
                push hl
                ld de,11
                add hl,de
                ld a,(hl)
                pop hl
                bit 3,a                  ; volume labels and LFN entries
                jr nz,dfd_next
                push hl
                call dfd_print_name
                jr dfd_counted

                ; Check buffer space: FS_L_SIZE >= 32?
dfd_buffer_entry:
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
dfd_counted:
                ld l, (ix+FS_L_CLUSTER)
                ld h, (ix+FS_L_CLUSTER+1)
                inc hl
                ld (ix+FS_L_CLUSTER), l
                ld (ix+FS_L_CLUSTER+1), h

                pop hl                   ; HL = entry addr (pre-copy)
dfd_next:
                ld de, 32
                add hl, de               ; advance copied, deleted, or skipped entry
                dec b
                jr nz, dfd_entry
                jp dfd_sector              ; next directory sector

dfd_ret:
                ld a,(ix+FS_L_FLAGS)
                or a
                jr z,dfd_raw_ret
                ld a,(ix+FS_L_CLUSTER)
                or (ix+FS_L_CLUSTER+1)
                jr nz,dfd_catalog_ret
                ld hl,dfd_catalog_empty
                call dfd_print_text
dfd_catalog_ret:
                call dfd_print_free
                xor a
                ret

dfd_raw_ret:
                ld l, (ix+FS_L_CLUSTER)
                ld h, (ix+FS_L_CLUSTER+1) ; HL = entries written
                ld b, h
                ld c, l                    ; BC = entries written
                ; Multiply BC by 32.
                sla c
                rl b
                sla c
                rl b
                sla c
                rl b
                sla c
                rl b
                sla c
                rl b                       ; BC = bytes written
                xor a
                ret

disk_fs_dir_nop:
                ld bc, 0
                xor a
                ret

; Private FS.CATALOGUE service advertised by RBFS capability bit 3.
; A=0 selects drive A and DE points to the standard 2080-byte work area.
; Output is sent through the published main-BIOS CHPUT entry.
disk_fs_catalog:
                or a
                jp nz,disk_fs_error_12
                ld a,d
                cp #80
                jp c,disk_fs_error_12
                push de
                pop ix
                xor a
                ld (ix+FS_L_CLUSTER),a
                ld (ix+FS_L_CLUSTER+1),a
                inc a
                ld (ix+FS_L_FLAGS),a
                jp dfd_boot

dfd_print_name:
                push bc
                ld b,8
                call dfd_print_field
                ld a,(hl)
                cp ' '
                jr z,dfd_print_name_end
                ld a,'.'
                call #00a2
                ld b,3
                call dfd_print_field
dfd_print_name_end:
                ld a,#0d
                call #00a2
                ld a,#0a
                call #00a2
                pop bc
                ret

dfd_print_field:
                ld a,(hl)
                inc hl
                cp ' '
                call nz,#00a2
                djnz dfd_print_field
                ret

dfd_print_text:
                ld a,(hl)
                or a
                ret z
                call #00a2
                inc hl
                jr dfd_print_text

; Count the zero FAT12 entries belonging to the supported 720 KiB data area.
; DISK_CLUSTERS is derived from the shared disk geometry, and each cluster is
; exactly one KiB (two 512-byte sectors), so the free-cluster count is also
; the free-space count in KiB.
dfd_print_free:
                xor a
                ld (ix+FS_L_COUNT),a
                ld (ix+FS_L_COUNT+1),a
                ld de,2
dfd_free_loop:
                ld a,d
                cp (DISK_CLUSTERS+2) >> 8
                jr c,dfd_free_read
                jr nz,dfd_free_done
                ld a,e
                cp (DISK_CLUSTERS+2) & #ff
                jr nc,dfd_free_done
dfd_free_read:
                call disk_fat12_read
                ld a,b
                or c
                jr nz,dfd_free_next
                ld l,(ix+FS_L_COUNT)
                ld h,(ix+FS_L_COUNT+1)
                inc hl
                ld (ix+FS_L_COUNT),l
                ld (ix+FS_L_COUNT+1),h
dfd_free_next:
                inc de
                jr dfd_free_loop
dfd_free_done:
                ld hl,dfd_catalog_free
                call dfd_print_text
                ld l,(ix+FS_L_COUNT)
                ld h,(ix+FS_L_COUNT+1)
                call dfd_print_u16_3
                ld hl,dfd_catalog_kib
                jp dfd_print_text

; Print an unsigned value in the catalogue's 0..713 range without leading
; zeroes.  Keeping this deliberately three-digit avoids pulling a general
; formatting library into the 16 KiB disk ROM.
dfd_print_u16_3:
                ld b,'0'
                ld de,100
dfd_print_hundreds:
                or a
                sbc hl,de
                jr c,dfd_print_hundreds_done
                inc b
                jr dfd_print_hundreds
dfd_print_hundreds_done:
                add hl,de
                ld c,'0'
                ld de,10
dfd_print_tens:
                or a
                sbc hl,de
                jr c,dfd_print_tens_done
                inc c
                jr dfd_print_tens
dfd_print_tens_done:
                add hl,de
                ld a,b
                cp '0'
                jr z,dfd_print_maybe_tens
                call dfd_print_digit
                ld a,c
                call dfd_print_digit
                jr dfd_print_ones
dfd_print_maybe_tens:
                ld a,c
                cp '0'
                call nz,dfd_print_digit
dfd_print_ones:
                ld a,l
                add a,'0'
                jp #00a2

dfd_print_digit:
                push bc
                push hl
                call #00a2
                pop hl
                pop bc
                ret

dfd_catalog_header:
                db "Drive A:",#0d,#0a,0
dfd_catalog_empty:
                db "(empty)",#0d,#0a,0
dfd_catalog_free:
                db "Free: ",0
dfd_catalog_kib:
                db " KiB",#0d,#0a,0


; FAT12 entry-write helper: store the 12-bit value in BC at cluster DE in
; the resident FAT buffer (IX + FS_FAT).  Used by FS.WRITE during cluster
; allocation to build the chain.
;
;   IX  work-area base
;   DE  cluster number
;   BC  value to write (B = bits 11-8, C = bits 7-0)
;   Clobbers AF, DE, HL
disk_fat12_store:
                push de
                ld l, e
                ld h, d
                srl h
                rr l
                add hl, de
                push hl
                push ix
                pop hl
                ld de, FS_FAT
                add hl, de
                pop de
                add hl, de
                ld a, (hl)
                inc hl
                ld h, (hl)
                ld l, a
                pop de
                bit 0, e
                jr nz, fat12_store_odd
                ld a, h
                and #f0
                ld h, a
                ld a, b
                and #0f
                or h
                ld h, a
                ld l, c
                jr fat12_store_write
fat12_store_odd:
                push de
                ld a, c
                and #0f
                ld e, a
                srl b
                rr c
                srl b
                rr c
                srl b
                rr c
                srl b
                rr c
                ld a, e
                rlca
                rlca
                rlca
                rlca
                ld e, a
                ld a, l
                and #0f
                or e
                ld l, a
                ld h, c
                pop de
fat12_store_write:
                ex de, hl
                push de
                ld e, l
                ld d, h
                srl h
                rr l
                add hl, de
                push ix
                pop de
                ld bc, FS_FAT
                ex de, hl
                add hl, bc
                add hl, de
                pop de
                ld (hl), e
                inc hl
                ld (hl), d
                ret

; FAT12 entry-read helper: read the 12-bit value at cluster DE from the
; resident FAT buffer (IX + FS_FAT).  Returns the value in BC.  Clobbers
; AF, HL.
;
;   IX  work-area base
;   DE  cluster number
;   Returns BC = 12-bit value, carry clear
disk_fat12_read:
                push de
                ld l, e
                ld h, d
                srl h
                rr l
                add hl, de
                push hl
                push ix
                pop hl
                ld de, FS_FAT
                add hl, de
                pop de
                add hl, de
                ld a, (hl)
                inc hl
                ld h, (hl)
                ld l, a
                pop de
                bit 0, e
                jr nz, fat12_read_odd
                ld a, h
                and #0f
                ld h, a
                jr fat12_read_done
fat12_read_odd:
                srl h
                rr l
                srl h
                rr l
                srl h
                rr l
                srl h
                rr l
fat12_read_done:
                ld b, h
                ld c, l
                or a
                ret
