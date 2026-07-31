#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Create the deterministic raw DSK used by the PHYDIO read probe."""

from __future__ import annotations

import argparse
import pathlib


SECTOR_SIZE = 512
DISK_SIZE = 720 * 1024
SECTORS_PER_TRACK = 9
SIDES = 2
TRACKS = 80


def logical_to_chs(logical: int) -> tuple[int, int, int]:
    track, within_track = divmod(logical, SECTORS_PER_TRACK * SIDES)
    side, sector_index = divmod(within_track, SECTORS_PER_TRACK)
    return track, side, sector_index + 1


def make_probe_sector(logical: int) -> bytes:
    sector = bytearray(
        (logical * 13 + offset * 37 + 11) & 0xFF
        for offset in range(SECTOR_SIZE)
    )
    sector[0:2] = b"RB"
    sector[2:4] = logical.to_bytes(2, "little")
    sector[SECTOR_SIZE // 2] = (logical & 0xFF) ^ 0x3C
    sector[-2] = (logical & 0xFF) ^ 0xA5
    sector[-1] = (logical >> 8) ^ 0x5A
    return bytes(sector)


def make_image() -> bytes:
    return b"".join(
        make_probe_sector(logical)
        for logical in range(DISK_SIZE // SECTOR_SIZE)
    )


def make_one_side_image() -> bytes:
    image = bytearray(make_image())
    image[11:13] = SECTOR_SIZE.to_bytes(2, "little")
    image[19:21] = (DISK_SIZE // SECTOR_SIZE).to_bytes(2, "little")
    image[24:26] = SECTORS_PER_TRACK.to_bytes(2, "little")
    image[26:28] = (1).to_bytes(2, "little")
    return bytes(image)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--one-side", action="store_true")
    parser.add_argument("output", type=pathlib.Path)
    arguments = parser.parse_args()
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    image = make_one_side_image() if arguments.one_side else make_image()
    arguments.output.write_bytes(image)
    print(f"wrote disk probe image: {arguments.output} ({len(image)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
