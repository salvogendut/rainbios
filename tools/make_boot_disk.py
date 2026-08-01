#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Create the deterministic bootable 720 KiB F9 DSK for the boot probe."""

from __future__ import annotations

import argparse
import pathlib

SECTOR_SIZE = 512
DISK_SIZE = 720 * 1024
SECTORS_PER_TRACK = 9
SIDES = 2
TRACKS = 80
FILL = 0xE5
BOOT_SECTORS = 2


def make_image(boot_sector: bytes) -> bytes:
    if len(boot_sector) < BOOT_SECTORS * SECTOR_SIZE:
        raise ValueError(
            f"boot sector image is {len(boot_sector)} bytes, need at least "
            f"{BOOT_SECTORS * SECTOR_SIZE}"
        )
    image = bytearray(bytes((FILL,)) * DISK_SIZE)
    image[: SECTOR_SIZE] = boot_sector[:SECTOR_SIZE]
    image[SECTOR_SIZE : BOOT_SECTORS * SECTOR_SIZE] = boot_sector[
        SECTOR_SIZE : BOOT_SECTORS * SECTOR_SIZE
    ]
    return bytes(image)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--boot-sector", type=pathlib.Path, required=True)
    parser.add_argument("output", type=pathlib.Path)
    arguments = parser.parse_args()
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    boot_sector = arguments.boot_sector.read_bytes()
    image = make_image(boot_sector)
    arguments.output.write_bytes(image)
    print(
        f"wrote boot disk image: {arguments.output} "
        f"({len(image)} bytes, {len(image) // SECTOR_SIZE} sectors)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
