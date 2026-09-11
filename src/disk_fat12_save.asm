; SPDX-License-Identifier: BSD-3-Clause
;
; Transaction-oriented FAT12 file replacement for the RainBIOS FS.WRITE
; vector. New data and its cluster chain are committed before an existing
; directory entry is redirected; the old chain is released afterwards. A
; failure before the directory write therefore leaves the previous file
; reachable, while a failure during final reclamation can only leak clusters.

; FS.WRITE (402Bh)
;   A   drive (0)
;   HL  filename (11-byte, space-padded 8.3)
;   DE  source buffer in page-2/3 RAM
;   BC  2080-byte work area in page-2/3 RAM
;   (BC+0/1) file size
; Returns carry clear/A=0, or carry set with the shared PHYDIO/FS error code.
; Files span as many FAT12 clusters as required. An existing regular file is
; replaced; error 21 means no free clusters and 22 means no directory slot.

disk_fs_save:
                or a
                jp nz,disk_fs_error_12
                ld a,h
                cp #80
                jp c,disk_fs_error_12
                ld a,d
                cp #80
                jp c,disk_fs_error_12
                ld a,b
                cp #80
                jp c,disk_fs_error_12
                push bc
                pop ix

                ld (ix+FS_L_NAME),l
                ld (ix+FS_L_NAME+1),h
                ld (ix+FS_L_DEST),e
                ld (ix+FS_L_DEST+1),d
                ld e,(ix+0)
                ld d,(ix+1)
                ld (ix+FS_L_SIZE),e
                ld (ix+FS_L_SIZE+1),d

                ; Parse the F9 BPB.
                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                xor a
                ld b,1
                ld c,DISK_MEDIA
                ld de,0
                call disk_phydio
                ret c

                ; Writes deliberately support only the exact 720 KiB F9
                ; geometry used by RainBIOS. Fail closed before deriving an
                ; LBA from a malformed or incompatible BPB.
                ld a,(ix+FS_DIR+FS_BYTES_PER_SECTOR)
                or a
                jp nz,disk_fs_error_12
                ld a,(ix+FS_DIR+FS_BYTES_PER_SECTOR+1)
                cp 2
                jp nz,disk_fs_error_12
                ld a,(ix+FS_DIR+FS_SECTORS_PER_CLUST)
                cp DISK_CLUSTER_SIZE
                jp nz,disk_fs_error_12
                ld (ix+FS_L_SPC),a
                ld a,(ix+FS_DIR+FS_RESERVED)
                cp 1
                jp nz,disk_fs_error_12
                ld a,(ix+FS_DIR+FS_RESERVED+1)
                or a
                jp nz,disk_fs_error_12
                ld a,(ix+FS_DIR+FS_FAT_COUNT)
                cp 2
                jp nz,disk_fs_error_12
                ld (ix+FS_L_FATCNT),a
                ld a,(ix+FS_DIR+FS_ROOT_ENTRIES)
                cp 112
                jp nz,disk_fs_error_12
                ld a,(ix+FS_DIR+FS_ROOT_ENTRIES+1)
                or a
                jp nz,disk_fs_error_12
                ld a,(ix+FS_DIR+FS_TOTAL_SECTORS)
                cp #a0
                jp nz,disk_fs_error_12
                ld a,(ix+FS_DIR+FS_TOTAL_SECTORS+1)
                cp #05
                jp nz,disk_fs_error_12
                ld a,(ix+FS_DIR+FS_MEDIA)
                cp DISK_MEDIA
                jp nz,disk_fs_error_12
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
                cp 3
                jp nz,disk_fs_error_12
                ld (ix+FS_L_FATSIZ),a
                ld e,a
                ld d,0

                ; Directory and data LBAs from the BPB.
                ld b,(ix+FS_L_FATCNT)
                ld l,(ix+FS_L_FIRSTFAT)
                ld h,(ix+FS_L_FIRSTFAT+1)
fss_first_dir:
                add hl,de
                djnz fss_first_dir
                ld (ix+FS_L_CURDIR),l
                ld (ix+FS_L_CURDIR+1),h

                ld l,(ix+FS_DIR+FS_ROOT_ENTRIES)
                ld h,(ix+FS_DIR+FS_ROOT_ENTRIES+1)
                add hl,hl
                add hl,hl
                add hl,hl
                add hl,hl
                add hl,hl
                ld de,511
                add hl,de
                ld b,9
fss_dir_size:
                srl h
                rr l
                djnz fss_dir_size
                ld a,l
                or a
                jp z,disk_fs_error_12
                ld (ix+FS_L_REMAIN),a
                ld e,a
                ld d,0
                ld l,(ix+FS_L_CURDIR)
                ld h,(ix+FS_L_CURDIR+1)
                add hl,de
                ld (ix+FS_L_FIRSTDATA),l
                ld (ix+FS_L_FIRSTDATA+1),h

                ; Keep the complete F9 FAT resident while allocating.
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

                xor a
                ld (ix+FS_L_FLAGS),a            ; 0 none, 1 deleted, 2 replace
                ld (ix+FS_L_OLD),a
                ld (ix+FS_L_OLD+1),a

                ; Scan all live entries even after remembering a deleted slot,
                ; so a later matching file is replaced instead of duplicated.
fss_dir_sector:
                ld a,(ix+FS_L_REMAIN)
                or a
                jr nz,fss_dir_sector_read
                ld a,(ix+FS_L_FLAGS)
                cp 1
                jp nz,disk_fs_error_22
                jp fss_slot_selected
fss_dir_sector_read:
                dec a
                ld (ix+FS_L_REMAIN),a
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
                ld l,(ix+FS_L_CURDIR)
                ld h,(ix+FS_L_CURDIR+1)
                inc hl
                ld (ix+FS_L_CURDIR),l
                ld (ix+FS_L_CURDIR+1),h

                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                ld c,16
fss_dir_entry:
                ld a,(hl)
                or a
                jr z,fss_unused_slot
                cp #e5
                jr z,fss_deleted_slot

                push hl
                ld de,FS_ATTR
                add hl,de
                ld a,(hl)
                pop hl
                and FS_ATTR_VOLUME | FS_ATTR_DIR
                jr nz,fss_next_entry

                push hl
                push bc
                ld e,(ix+FS_L_NAME)
                ld d,(ix+FS_L_NAME+1)
                ld b,11
fss_compare_name:
                ld a,(de)
                cp (hl)
                jr nz,fss_name_mismatch
                inc de
                inc hl
                djnz fss_compare_name
                pop bc
                pop hl
                call fss_record_slot
                push hl
                ld de,FS_FIRST_CLUSTER
                add hl,de
                ld a,(hl)
                ld (ix+FS_L_OLD),a
                inc hl
                ld a,(hl)
                ld (ix+FS_L_OLD+1),a
                pop hl
                ld (ix+FS_L_FLAGS),2
                jr fss_slot_selected
fss_name_mismatch:
                pop bc
                pop hl
                jr fss_next_entry

fss_deleted_slot:
                ld a,(ix+FS_L_FLAGS)
                or a
                jr nz,fss_next_entry
                call fss_record_slot
                ld (ix+FS_L_FLAGS),1
                jr fss_next_entry

fss_unused_slot:
                call fss_record_slot
                jr fss_slot_selected

fss_next_entry:
                ld de,FS_DIR_ENTRY
                add hl,de
                dec c
                jr nz,fss_dir_entry
                jp fss_dir_sector

; C is the number of entries including the current one; CURDIR has already
; advanced, so the selected entry belongs to CURDIR-1.
fss_record_slot:
                push hl
                ld a,16
                sub c
                add a,a
                add a,a
                add a,a
                add a,a
                add a,a
                ld (ix+FS_L_DIRSIZ),a
                ld l,(ix+FS_L_CURDIR)
                ld h,(ix+FS_L_CURDIR+1)
                dec hl
                ld (ix+FS_L_FIRSTDIR),l
                ld (ix+FS_L_FIRSTDIR+1),h
                pop hl
                ret

fss_slot_selected:
                ; Required clusters = ceil(size / 1024) for 720 KiB F9 media.
                ld l,(ix+FS_L_SIZE)
                ld h,(ix+FS_L_SIZE+1)
                ld a,h
                and 3
                or l
                ld e,a                          ; non-zero remainder
                ld a,h
                srl a
                srl a
                ld l,a
                ld a,e
                or a
                jr z,fss_cluster_count_ready
                inc l
fss_cluster_count_ready:
                ld h,0
                ld (ix+FS_L_COUNT),l
                ld (ix+FS_L_COUNT+1),h
                xor a
                ld (ix+FS_L_FIRSTNEW),a
                ld (ix+FS_L_FIRSTNEW+1),a
                ld (ix+FS_L_CLUSTER),a
                ld (ix+FS_L_CLUSTER+1),a
                ld a,l
                or a
                jp z,fss_directory_commit

                ld de,2
fss_allocate_scan:
                ld a,d
                cp (DISK_CLUSTERS+2) >> 8
                jr c,fss_allocate_candidate
                jp nz,disk_fs_error_21
                ld a,e
                cp (DISK_CLUSTERS+2) & #ff
                jp nc,disk_fs_error_21
fss_allocate_candidate:
                call disk_fat12_read
                ld a,b
                or c
                jr z,fss_allocate_found
                inc de
                jr fss_allocate_scan

fss_allocate_found:
                ld a,(ix+FS_L_FIRSTNEW)
                ld l,a
                ld a,(ix+FS_L_FIRSTNEW+1)
                or l
                jr nz,fss_allocate_link
                ld (ix+FS_L_FIRSTNEW),e
                ld (ix+FS_L_FIRSTNEW+1),d
                jr fss_allocate_remember
fss_allocate_link:
                push de
                ld b,d
                ld c,e
                ld e,(ix+FS_L_CLUSTER)
                ld d,(ix+FS_L_CLUSTER+1)
                call disk_fat12_store
                pop de
fss_allocate_remember:
                ld (ix+FS_L_CLUSTER),e
                ld (ix+FS_L_CLUSTER+1),d
                ld l,(ix+FS_L_COUNT)
                ld h,(ix+FS_L_COUNT+1)
                dec hl
                ld (ix+FS_L_COUNT),l
                ld (ix+FS_L_COUNT+1),h
                ld a,h
                or l
                jr z,fss_allocate_finish
                inc de
                jr fss_allocate_scan
fss_allocate_finish:
                ld e,(ix+FS_L_CLUSTER)
                ld d,(ix+FS_L_CLUSTER+1)
                ld bc,#0fff
                call disk_fat12_store

                ; Write the new data before making its in-memory FAT chain
                ; visible on disk.
                ld l,(ix+FS_L_SIZE)
                ld h,(ix+FS_L_SIZE+1)
                ld (ix+FS_L_LEFT),l
                ld (ix+FS_L_LEFT+1),h
                ld l,(ix+FS_L_FIRSTNEW)
                ld h,(ix+FS_L_FIRSTNEW+1)
                ld (ix+FS_L_CLUSTER),l
                ld (ix+FS_L_CLUSTER+1),h

fss_data_cluster:
                ld e,(ix+FS_L_CLUSTER)
                ld d,(ix+FS_L_CLUSTER+1)
                ld hl,#fffe
                add hl,de
                ld b,(ix+FS_L_SPC)
                push hl
                pop de
                ld hl,0
fss_data_lba:
                add hl,de
                djnz fss_data_lba
                ld e,(ix+FS_L_FIRSTDATA)
                ld d,(ix+FS_L_FIRSTDATA+1)
                add hl,de
                ld (ix+FS_L_CURDIR),l
                ld (ix+FS_L_CURDIR+1),h
                ld a,(ix+FS_L_SPC)
                ld (ix+FS_L_REMAIN),a

fss_data_sector:
                ld a,(ix+FS_L_LEFT)
                ld l,a
                ld a,(ix+FS_L_LEFT+1)
                or l
                jp z,fss_data_done
                ld a,(ix+FS_L_LEFT+1)
                cp 2
                jr c,fss_data_partial

                ld l,(ix+FS_L_DEST)
                ld h,(ix+FS_L_DEST+1)
                ld e,(ix+FS_L_CURDIR)
                ld d,(ix+FS_L_CURDIR+1)
                ld b,1
                ld c,DISK_MEDIA
                xor a
                scf
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
                jr fss_data_advance

fss_data_partial:
                ; Zero-pad one sector in scratch, then overlay the exact tail.
                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                push hl
                xor a
                ld (hl),a
                ld d,h
                ld e,l
                inc de
                ld bc,511
                ldir
                pop de                           ; scratch destination
                ld l,(ix+FS_L_DEST)
                ld h,(ix+FS_L_DEST+1)
                ld c,(ix+FS_L_LEFT)
                ld b,(ix+FS_L_LEFT+1)
                ldir
                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                ld e,(ix+FS_L_CURDIR)
                ld d,(ix+FS_L_CURDIR+1)
                ld b,1
                ld c,DISK_MEDIA
                xor a
                scf
                call disk_phydio
                ret c
                xor a
                ld (ix+FS_L_LEFT),a
                ld (ix+FS_L_LEFT+1),a
                jr fss_data_done

fss_data_advance:
                ld l,(ix+FS_L_CURDIR)
                ld h,(ix+FS_L_CURDIR+1)
                inc hl
                ld (ix+FS_L_CURDIR),l
                ld (ix+FS_L_CURDIR+1),h
                dec (ix+FS_L_REMAIN)
                jp nz,fss_data_sector
                call disk_fat12_next
                jp fss_data_cluster

fss_data_done:
                call fss_flush_fats
                ret c

fss_directory_commit:
                ; Re-read the selected sector, clear the 32-byte entry, and
                ; publish the new name/cluster/size in one sector write.
                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                ld e,(ix+FS_L_FIRSTDIR)
                ld d,(ix+FS_L_FIRSTDIR+1)
                ld b,1
                ld c,DISK_MEDIA
                xor a
                call disk_phydio
                ret c

                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                ld e,(ix+FS_L_DIRSIZ)
                ld d,0
                add hl,de
                push hl
                xor a
                ld b,FS_DIR_ENTRY
fss_clear_entry:
                ld (hl),a
                inc hl
                djnz fss_clear_entry
                pop hl
                ld e,(ix+FS_L_NAME)
                ld d,(ix+FS_L_NAME+1)
                ld b,11
fss_copy_name:
                ld a,(de)
                ld (hl),a
                inc de
                inc hl
                djnz fss_copy_name
                ld (hl),#20                     ; archive attribute
                ld de,15
                add hl,de                       ; first cluster at offset 26
                ld a,(ix+FS_L_FIRSTNEW)
                ld (hl),a
                inc hl
                ld a,(ix+FS_L_FIRSTNEW+1)
                ld (hl),a
                inc hl
                ld a,(ix+FS_L_SIZE)
                ld (hl),a
                inc hl
                ld a,(ix+FS_L_SIZE+1)
                ld (hl),a

                push ix
                pop hl
                ld de,FS_DIR
                add hl,de
                ld e,(ix+FS_L_FIRSTDIR)
                ld d,(ix+FS_L_FIRSTDIR+1)
                ld b,1
                ld c,DISK_MEDIA
                xor a
                scf
                call disk_phydio
                ret c

                ld a,(ix+FS_L_FLAGS)
                cp 2
                jr nz,fss_success

                ; The new directory entry is durable. Reclaim the old chain;
                ; if it was malformed, release the valid prefix and stop.
                ld e,(ix+FS_L_OLD)
                ld d,(ix+FS_L_OLD+1)
                xor a
                ld (ix+FS_L_COUNT),a
                ld (ix+FS_L_COUNT+1),a
fss_free_old:
                ld a,d
                or e
                jr z,fss_free_old_done
                ld a,d
                cp (DISK_CLUSTERS+2) >> 8
                jr c,fss_free_old_valid
                jr nz,fss_free_old_done
                ld a,e
                cp (DISK_CLUSTERS+2) & #ff
                jr nc,fss_free_old_done
fss_free_old_valid:
                call disk_fat12_read
                push bc
                ld bc,0
                call disk_fat12_store
                pop de
                ld a,d
                cp #0f
                jr c,fss_free_old_next
                jr nz,fss_free_old_done
                ld a,e
                cp #f8
                jr nc,fss_free_old_done
fss_free_old_next:
                ld l,(ix+FS_L_COUNT)
                ld h,(ix+FS_L_COUNT+1)
                inc hl
                ld (ix+FS_L_COUNT),l
                ld (ix+FS_L_COUNT+1),h
                ld a,h
                cp 2
                jr c,fss_free_old
                jr nz,fss_free_old_done
                ld a,l
                cp #ca
                jr c,fss_free_old
fss_free_old_done:
                call fss_flush_fats
                ret c

fss_success:
                xor a
                ret

; Persist the resident FAT to every advertised copy.
fss_flush_fats:
                push ix
                pop hl
                ld de,FS_FAT
                add hl,de
                ld e,(ix+FS_L_FIRSTFAT)
                ld d,(ix+FS_L_FIRSTFAT+1)
                ld b,(ix+FS_L_FATSIZ)
                ld c,DISK_MEDIA
                xor a
                scf
                call disk_phydio
                ret c
                ld a,(ix+FS_L_FATCNT)
                cp 2
                ret c
                push ix
                pop hl
                ld de,FS_FAT
                add hl,de
                ld e,(ix+FS_L_FIRSTFAT)
                ld d,(ix+FS_L_FIRSTFAT+1)
                push hl
                ld l,(ix+FS_L_FATSIZ)
                ld h,0
                add hl,de
                ex de,hl
                pop hl
                ld b,(ix+FS_L_FATSIZ)
                ld c,DISK_MEDIA
                xor a
                scf
                jp disk_phydio

disk_fs_error_21:
                ld a,21
                scf
                ret
disk_fs_error_22:
                ld a,22
                scf
                ret
