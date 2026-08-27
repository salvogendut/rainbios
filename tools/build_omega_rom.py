#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Build the 512 KiB Omega MSX unified EEPROM image."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import tempfile


ROM_SIZE = 0x80000
BANK_SIZE = 0x40000
SLOT_SIZE = 0x10000


def read_exact(path: Path, size: int, description: str) -> bytes:
    data = path.read_bytes()
    if len(data) != size:
        raise SystemExit(
            f"{description} must be exactly {size // 1024} KiB: {path}"
        )
    return data


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--main-rom", type=Path, required=True)
    parser.add_argument("--sub-rom", type=Path, required=True)
    parser.add_argument("--disk-rom", type=Path, required=True)
    arguments = parser.parse_args()

    main_rom = read_exact(arguments.main_rom, 0x8000, "MSX2 main ROM")
    sub_rom = read_exact(arguments.sub_rom, 0x4000, "MSX2 Sub-ROM")
    disk_rom = read_exact(arguments.disk_rom, 0x4000, "disk ROM")
    image = bytearray([0xFF]) * ROM_SIZE

    # Each JP1-selectable 256 KiB bank contains four consecutive 64 KiB
    # physical slot images: primary slot 0, then expanded-slot subslots 0, 1,
    # and 3. Slot 3-2 is mapper RAM and therefore has no EEPROM region.
    for bank in (0, 1):
        base = bank * BANK_SIZE
        image[base : base + len(main_rom)] = main_rom
        image[base + SLOT_SIZE : base + SLOT_SIZE + len(sub_rom)] = sub_rom
        disk_offset = base + 3 * SLOT_SIZE + 0x4000
        image[disk_offset : disk_offset + len(disk_rom)] = disk_rom

    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=arguments.output.name + ".", dir=arguments.output.parent
    )
    try:
        with os.fdopen(descriptor, "wb") as temporary:
            temporary.write(image)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.chmod(temporary_name, 0o644)
        os.replace(temporary_name, arguments.output)
    except BaseException:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
