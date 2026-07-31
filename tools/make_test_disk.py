#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Create the deterministic raw DSK used by the PHYDIO read probe."""

from __future__ import annotations

import argparse
import pathlib


SECTOR_SIZE = 512
DISK_SIZE = 720 * 1024
PROBE_SECTOR = 1
PROBE_MARKER = b"RAINBIOS-PHYDIO"
PROBE_MIDDLE = 0x3C
PROBE_SUFFIX = bytes((0xA5, 0x5A))


def make_probe_sector() -> bytes:
    sector = bytearray((offset * 37 + 11) & 0xFF for offset in range(SECTOR_SIZE))
    sector[: len(PROBE_MARKER)] = PROBE_MARKER
    sector[SECTOR_SIZE // 2] = PROBE_MIDDLE
    sector[-len(PROBE_SUFFIX) :] = PROBE_SUFFIX
    return bytes(sector)


def make_image() -> bytes:
    image = bytearray(DISK_SIZE)
    start = PROBE_SECTOR * SECTOR_SIZE
    image[start : start + SECTOR_SIZE] = make_probe_sector()
    return bytes(image)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=pathlib.Path)
    arguments = parser.parse_args()
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    image = make_image()
    arguments.output.write_bytes(image)
    print(f"wrote disk probe image: {arguments.output} ({len(image)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
