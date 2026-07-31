# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
from pathlib import Path
import unittest

from tools.make_test_disk import (
    DISK_SIZE,
    SECTORS_PER_TRACK,
    SIDES,
    TRACKS,
    SECTOR_SIZE,
    logical_to_chs,
    make_image,
    make_one_side_image,
    make_probe_sector,
)


ROOT = Path(__file__).resolve().parents[1]
DISK_ROM_PATH = Path(
    os.environ.get(
        "RAINBIOS_NMS8250_DISK_ROM",
        ROOT / "build" / "rainbios_nms8250_disk.rom",
    )
)


class DiskFixtureTests(unittest.TestCase):
    def test_image_contains_deterministic_markers_in_every_sector(self) -> None:
        image = make_image()

        self.assertEqual(len(image), DISK_SIZE)
        for logical in (0, 8, 9, 17, 18, 731, 1438, 1439):
            start = logical * SECTOR_SIZE
            self.assertEqual(
                image[start : start + SECTOR_SIZE],
                make_probe_sector(logical),
            )

    def test_logical_sector_geometry_is_complete_and_reversible(self) -> None:
        for logical in range(TRACKS * SIDES * SECTORS_PER_TRACK):
            track, side, sector = logical_to_chs(logical)
            self.assertLess(track, TRACKS)
            self.assertLess(side, SIDES)
            self.assertGreaterEqual(sector, 1)
            self.assertLessEqual(sector, SECTORS_PER_TRACK)
            self.assertEqual(
                ((track * SIDES) + side) * SECTORS_PER_TRACK + sector - 1,
                logical,
            )

    def test_one_side_fixture_advertises_runtime_fault_geometry(self) -> None:
        image = make_one_side_image()

        self.assertEqual(len(image), DISK_SIZE)
        self.assertEqual(int.from_bytes(image[11:13], "little"), SECTOR_SIZE)
        self.assertEqual(int.from_bytes(image[19:21], "little"), 1440)
        self.assertEqual(int.from_bytes(image[24:26], "little"), 9)
        self.assertEqual(int.from_bytes(image[26:28], "little"), 1)
        start = 8 * SECTOR_SIZE
        self.assertEqual(
            image[start : start + SECTOR_SIZE],
            make_probe_sector(8),
        )


class DiskRomLayoutTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.rom = DISK_ROM_PATH.read_bytes()

    def test_rom_is_a_16_kib_extension(self) -> None:
        self.assertEqual(len(self.rom), 0x4000)
        self.assertEqual(self.rom[:2], b"AB")
        init = int.from_bytes(self.rom[2:4], "little")
        self.assertGreaterEqual(init, 0x4030)
        self.assertLess(init, 0x8000)

    def test_standard_dskio_entry_is_a_jump(self) -> None:
        self.assertEqual(self.rom[0x10], 0xC3)

    def test_choice_reports_no_format_options(self) -> None:
        self.assertEqual(self.rom[0x19], 0xC3)
        target = int.from_bytes(self.rom[0x1A:0x1C], "little") - 0x4000
        self.assertEqual(self.rom[target : target + 4], bytes((0x21, 0, 0, 0xC9)))

    def test_unused_tail_is_erased(self) -> None:
        self.assertEqual(self.rom[-256:], bytes((0xFF,)) * 256)


if __name__ == "__main__":
    unittest.main()
