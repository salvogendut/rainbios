# SPDX-License-Identifier: BSD-3-Clause
"""Validate the generated Omega 512 KiB unified EEPROM image."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
OMEGA_ROM = Path(
    os.environ.get("RAINBIOS_OMEGA_ROM", BUILD / "rainbios_omega.rom")
)
MAIN_ROM = Path(
    os.environ.get("RAINBIOS_MSX2_ROM", BUILD / "rainbios_msx2.rom")
)
SUB_ROM = Path(
    os.environ.get(
        "RAINBIOS_MSX2_SUB_ROM", BUILD / "rainbios_msx2_sub.rom"
    )
)
DISK_ROM = BUILD / "rainbios_disk.rom"


def expected_image() -> bytes:
    main_rom = MAIN_ROM.read_bytes()
    sub_rom = SUB_ROM.read_bytes()
    disk_rom = DISK_ROM.read_bytes()
    if len(main_rom) != 0x8000:
        raise AssertionError("MSX2 main ROM is not 32 KiB")
    if len(sub_rom) != 0x4000:
        raise AssertionError("MSX2 Sub-ROM is not 16 KiB")
    if len(disk_rom) != 0x4000:
        raise AssertionError("generic disk ROM is not 16 KiB")

    expected = bytearray([0xFF]) * 0x80000
    for base in (0x00000, 0x40000):
        expected[base : base + 0x8000] = main_rom
        expected[base + 0x10000 : base + 0x14000] = sub_rom
        expected[base + 0x34000 : base + 0x38000] = disk_rom
    return bytes(expected)


class OmegaRomTests(unittest.TestCase):
    def test_exact_layout_and_erased_space(self) -> None:
        image = OMEGA_ROM.read_bytes()
        self.assertEqual(len(image), 0x80000)
        self.assertEqual(image, expected_image())

    def test_jp1_banks_are_identical(self) -> None:
        image = OMEGA_ROM.read_bytes()
        self.assertEqual(image[:0x40000], image[0x40000:])

    def test_builder_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            rebuilt = Path(temporary) / "rainbios_omega.rom"
            subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "tools" / "build_omega_rom.py"),
                    "--output",
                    str(rebuilt),
                    "--main-rom",
                    str(MAIN_ROM),
                    "--sub-rom",
                    str(SUB_ROM),
                    "--disk-rom",
                    str(DISK_ROM),
                ],
                check=True,
            )
            self.assertEqual(rebuilt.read_bytes(), OMEGA_ROM.read_bytes())


if __name__ == "__main__":
    unittest.main()
