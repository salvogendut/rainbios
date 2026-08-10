#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Build the redistributable 720 KiB FAT12 clean-room BDOS boot fixture."""

from __future__ import annotations

import argparse
import pathlib

SECTOR_SIZE = 512
SECTORS_PER_CLUSTER = 2
SECTORS = 1440
RESERVED = 1
FAT_COUNT = 2
FAT_SIZE = 3
ROOT_ENTRIES = 112
ROOT_SECTORS = ROOT_ENTRIES * 32 // SECTOR_SIZE
FIRST_DIRECTORY = RESERVED + FAT_COUNT * FAT_SIZE
FIRST_DATA = FIRST_DIRECTORY + ROOT_SECTORS
MEDIA = 0xF9
FILE_NAME = b"MSXDOS  SYS"


def set_fat12(fat: bytearray, cluster: int, value: int) -> None:
    offset = cluster + cluster // 2
    if cluster & 1:
        word = fat[offset] | (fat[offset + 1] << 8)
        word = (word & 0x000F) | ((value & 0x0FFF) << 4)
    else:
        word = fat[offset] | (fat[offset + 1] << 8)
        word = (word & 0xF000) | (value & 0x0FFF)
    fat[offset] = word & 0xFF
    fat[offset + 1] = word >> 8


def make_image(boot_sector: bytes, system_file: bytes) -> bytes:
    if len(boot_sector) < SECTOR_SIZE:
        raise ValueError("boot-sector binary is shorter than 512 bytes")
    clusters = max(
        1,
        (len(system_file) + SECTORS_PER_CLUSTER * SECTOR_SIZE - 1)
        // (SECTORS_PER_CLUSTER * SECTOR_SIZE),
    )
    image = bytearray(bytes((0xE5,)) * (SECTORS * SECTOR_SIZE))
    image[:SECTOR_SIZE] = boot_sector[:SECTOR_SIZE]

    fat = bytearray(FAT_SIZE * SECTOR_SIZE)
    fat[0:3] = bytes((MEDIA, 0xFF, 0xFF))
    for index in range(clusters):
        cluster = 2 + index
        set_fat12(fat, cluster, 0xFFF if index + 1 == clusters else cluster + 1)
    for copy in range(FAT_COUNT):
        start = (RESERVED + copy * FAT_SIZE) * SECTOR_SIZE
        image[start : start + len(fat)] = fat

    directory = FIRST_DIRECTORY * SECTOR_SIZE
    image[directory : directory + 11] = FILE_NAME
    image[directory + 11] = 0
    image[directory + 26 : directory + 28] = (2).to_bytes(2, "little")
    image[directory + 28 : directory + 32] = len(system_file).to_bytes(4, "little")

    data = FIRST_DATA * SECTOR_SIZE
    image[data : data + len(system_file)] = system_file
    return bytes(image)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--boot-sector", type=pathlib.Path, required=True)
    parser.add_argument("--system", type=pathlib.Path, required=True)
    parser.add_argument("output", type=pathlib.Path)
    arguments = parser.parse_args()
    image = make_image(
        arguments.boot_sector.read_bytes(), arguments.system.read_bytes()
    )
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_bytes(image)
    print(f"wrote clean-room BDOS boot disk: {arguments.output} ({len(image)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
