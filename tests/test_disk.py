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

    def _dpb_file_offset(self) -> int:
        expected = bytes(
            (
                0xF9,  # MEDIA
                0x00, 0x02,  # SECBIZ 512
                0x0F,  # DIRMSK
                0x04,  # DIRSHFT
                0x01,  # CLUSMSK
                0x02,  # CLUSSHFT
                0x01, 0x00,  # FIRFAT 1
                0x02,  # FATCNT
                0x70,  # MAXENT 112
                0x0E, 0x00,  # FIRREC 14
                0xCA, 0x02,  # MAXCLUS 714
                0x03,  # FATSIZ
                0x07, 0x00,  # FIRDIR 7
            )
        )
        occurrences = [
            index
            for index in range(len(self.rom) - len(expected) + 1)
            if self.rom[index : index + len(expected)] == expected
        ]
        self.assertEqual(len(occurrences), 1)
        return occurrences[0]

    def test_rom_is_a_16_kib_extension(self) -> None:
        self.assertEqual(len(self.rom), 0x4000)
        self.assertEqual(self.rom[:2], b"AB")
        init = int.from_bytes(self.rom[2:4], "little")
        self.assertGreaterEqual(init, 0x4030)
        self.assertLess(init, 0x8000)

    def test_standard_dskio_entry_is_a_jump(self) -> None:
        self.assertEqual(self.rom[0x10], 0xC3)

    def test_dskchg_and_getdpb_entries_are_jumps(self) -> None:
        for offset in (0x13, 0x16):
            self.assertEqual(self.rom[offset], 0xC3)
        for target in (
            int.from_bytes(self.rom[0x14:0x16], "little"),
            int.from_bytes(self.rom[0x17:0x19], "little"),
        ):
            self.assertGreaterEqual(target, 0x4000)
            self.assertLess(target, 0x8000)

    def test_getdpb_publishes_the_f9_dpb(self) -> None:
        self._dpb_file_offset()

    def test_getdpb_copies_the_dpb_block_with_ldir(self) -> None:
        self.assertEqual(self.rom[0x16], 0xC3)
        target = int.from_bytes(self.rom[0x17:0x19], "little") - 0x4000
        code = self.rom[target : target + 32]
        # LDIR copies from (HL) to (DE); GETDPB publishes at HL+1 so it must
        # place the DPB block in HL and DE at the DPB base before incrementing.
        self.assertIn(bytes((0xEB, 0x13)), code)  # EX DE,HL ; INC DE
        self.assertIn(bytes((0x01, 0x12, 0x00, 0xED, 0xB0)), code)  # LD BC,18 ; LDIR
        dpb_address = 0x4000 + self._dpb_file_offset()
        self.assertIn(
            bytes((0x21, dpb_address & 0xFF, dpb_address >> 8)),
            code,  # LD HL,disk_dpb
        )

    def test_choice_reports_no_format_options(self) -> None:
        self.assertEqual(self.rom[0x19], 0xC3)
        target = int.from_bytes(self.rom[0x1A:0x1C], "little") - 0x4000
        self.assertEqual(self.rom[target : target + 4], bytes((0x21, 0, 0, 0xC9)))

    def test_unused_tail_is_erased(self) -> None:
        self.assertEqual(self.rom[-256:], bytes((0xFF,)) * 256)


if __name__ == "__main__":
    unittest.main()
