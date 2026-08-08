#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Create the deterministic FAT12 720 KiB F9 DSK used by the FS.LOAD probe.

The image carries a single root-directory file (RAIN.BIN) over a three-cluster
FAT chain whose byte pattern is a closed-form function of the file offset, so
the 1983 cartridge can verify the loaded destination without a checksum block.
"""

from __future__ import annotations

import argparse
import pathlib

SECTOR_SIZE = 512
SPC = 2
DISK_SIZE = 720 * 1024
SECTORS = DISK_SIZE // SECTOR_SIZE
SECTORS_PER_TRACK = 9
SIDES = 2
FAT_COUNT = 2
RESERVED = 1
ROOT_ENTRIES = 112
FAT_SIZE = 3
MEDIA = 0xF9

FIRST_FAT = RESERVED
FIRST_DIR = FIRST_FAT + FAT_COUNT * FAT_SIZE
DIR_SECTORS = (ROOT_ENTRIES * 32 + SECTOR_SIZE - 1) // SECTOR_SIZE
FIRST_DATA = FIRST_DIR + DIR_SECTORS

# File: 8.3 name in the root directory, three clusters = 3 KiB.
FILE_NAME = b"RAIN    BIN"
FILE_CLUSTERS = 3
FILE_SIZE = FILE_CLUSTERS * SPC * SECTOR_SIZE
FIRST_CLUSTER = 2

# Runs of the file pattern never collide on the 512-byte cluster boundary.
EXPECTED = {
    0: 0x52,  # 'R'
    1: 0x42,  # 'B'
    2: 0x4F,  # 'O'
    3: 0x31,  # '1'
    1023: (1023 * 7 + 1) & 0xFF,
    1024: 0x01,
    2047: (2047 * 7 + 1) & 0xFF,
    2048: 0x01,
    3071: (3071 * 7 + 1) & 0xFF,
}


def fat12_pack(values: list[int]) -> bytes:
    packed = bytearray()
    index = 0
    while index + 1 < len(values):
        even, odd = values[index], values[index + 1]
        packed.append(even & 0xFF)
        packed.append(((even >> 8) & 0x0F) | ((odd & 0x0F) << 4))
        packed.append((odd >> 4) & 0xFF)
        index += 2
    if index < len(values):
        packed.append(values[index] & 0xFF)
        packed.append((values[index] >> 8) & 0x0F)
    return bytes(packed)


def make_boot_sector() -> bytes:
    sector = bytearray(SECTOR_SIZE)
    sector[0:3] = b"\xEB\x3C\x90"
    sector[3:11] = b"RBFAT12 "
    sector[11:13] = SECTOR_SIZE.to_bytes(2, "little")
    sector[13] = SPC
    sector[14:16] = RESERVED.to_bytes(2, "little")
    sector[16] = 2
    sector[17:19] = ROOT_ENTRIES.to_bytes(2, "little")
    sector[19:21] = SECTORS.to_bytes(2, "little")
    sector[21] = MEDIA
    sector[22:24] = FAT_SIZE.to_bytes(2, "little")
    sector[24:26] = SECTORS_PER_TRACK.to_bytes(2, "little")
    sector[26:28] = SIDES.to_bytes(2, "little")
    sector[28:30] = (0).to_bytes(2, "little")
    sector[30:32] = (0).to_bytes(2, "little")
    sector[510:512] = b"\x55\xAA"
    return bytes(sector)


def make_fats() -> bytes:
    # FAT[0] = 0xFF9 (media), FAT[1] = 0xFFF, data chain 2 -> 3 -> 4 -> 0xFFF.
    values = [0xFF0 | MEDIA, 0xFFF]
    for start in range(FIRST_CLUSTER, FIRST_CLUSTER + FILE_CLUSTERS - 1):
        values.append(start + 1)
    values.append(0xFFF)
    fat = fat12_pack(values)
    fat += bytes(FAT_SIZE * SECTOR_SIZE - len(fat))
    return fat


def make_root_directory() -> bytes:
    image = bytearray(DIR_SECTORS * SECTOR_SIZE)
    entry = bytearray(32)
    entry[0:11] = FILE_NAME
    entry[11] = 0
    entry[26:28] = FIRST_CLUSTER.to_bytes(2, "little")
    entry[28:32] = FILE_SIZE.to_bytes(4, "little")
    image[0:32] = entry
    return bytes(image)


def make_data() -> bytes:
    content = bytearray(
        (offset * 7 + 1) & 0xFF for offset in range(FILE_SIZE)
    )
    content[0:4] = b"RBO1"
    image = bytearray(bytes((0xE5,)) * (SECTORS - FIRST_DATA) * SECTOR_SIZE)
    image[0 : SPC * SECTOR_SIZE * FILE_CLUSTERS] = content
    return bytes(image)


def make_image(boot_sector: bytes | None = None) -> bytes:
    if boot_sector is None:
        boot = make_boot_sector()
    else:
        boot = bytearray(SECTOR_SIZE)
        src_len = len(boot_sector)
        if src_len > SECTOR_SIZE:
            src_len = SECTOR_SIZE
        boot[:src_len] = boot_sector[:src_len]
        boot = bytes(boot)
    fats = make_fats()
    directory = make_root_directory()
    data = make_data()
    if len(boot) != SECTOR_SIZE:
        raise ValueError("boot sector is not exactly one 512-byte sector")
    if len(fats) != FAT_SIZE * SECTOR_SIZE:
        raise ValueError("FAT is not exactly the BPB FAT-size x sector size")
    return boot + fats + fats + directory + data


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--boot-sector", type=pathlib.Path, default=None)
    parser.add_argument("output", type=pathlib.Path)
    arguments = parser.parse_args()
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    boot_arg = None
    if arguments.boot_sector is not None:
        boot_arg = arguments.boot_sector.read_bytes()
    image = make_image(boot_arg)
    assert len(image) == DISK_SIZE, len(image)
    arguments.output.write_bytes(image)
    print(f"wrote FAT12 disk image: {arguments.output} ({len(image)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())