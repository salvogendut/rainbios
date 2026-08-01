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
from tools.make_boot_disk import FILL, make_image as make_boot_image
from tools.make_ide_image import (
    FILL as IDE_FILL,
    IMAGE_SECTORS,
    make_image as make_ide_image,
)


ROOT = Path(__file__).resolve().parents[1]
DISK_ROM_PATH = Path(
    os.environ.get(
        "RAINBIOS_NMS8250_DISK_ROM",
        ROOT / "build" / "rainbios_nms8250_disk.rom",
    )
)
BOOT_SECTOR_PATH = Path(
    os.environ.get(
        "RAINBIOS_DISK_BOOT_SECTOR",
        ROOT / "build" / "disk_boot_sector.bin",
    )
)
IDE_BOOT_SECTOR_PATH = Path(
    os.environ.get(
        "RAINBIOS_IDE_BOOT_SECTOR",
        ROOT / "build" / "ide_boot_sector.bin",
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


class BootDiskImageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.boot_sector = BOOT_SECTOR_PATH.read_bytes()

    def test_boot_image_is_a_full_720_kib_f9_image(self) -> None:
        image = make_boot_image(self.boot_sector)

        self.assertEqual(len(image), DISK_SIZE)
        self.assertEqual(image[0], 0xEB)
        self.assertEqual(image[0x15], 0xF9)
        self.assertEqual(
            image[SECTOR_SIZE : 2 * SECTOR_SIZE],
            self.boot_sector[SECTOR_SIZE : 2 * SECTOR_SIZE],
        )

    def test_boot_image_fills_unused_sectors_with_erased_media(self) -> None:
        image = make_boot_image(self.boot_sector)

        self.assertEqual(image[2 * SECTOR_SIZE :], bytes((FILL,)) * (DISK_SIZE - 2 * SECTOR_SIZE))


class BootSectorLayoutTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.boot_sector = BOOT_SECTOR_PATH.read_bytes()

    def test_boot_sector_is_two_sectors_loaded_to_c000(self) -> None:
        self.assertGreaterEqual(len(self.boot_sector), 2 * SECTOR_SIZE)

    def test_boot_sector_carries_the_msxdos_signature(self) -> None:
        self.assertIn(self.boot_sector[0], (0xEB, 0xE9))
        self.assertEqual(self.boot_sector[2], 0x90)

    def test_boot_sector_advertises_the_f9_geometry(self) -> None:
        self.assertEqual(int.from_bytes(self.boot_sector[11:13], "little"), 512)
        self.assertEqual(self.boot_sector[13], 2)
        self.assertEqual(self.boot_sector[0x15], 0xF9)
        self.assertEqual(int.from_bytes(self.boot_sector[19:21], "little"), 1440)
        self.assertEqual(int.from_bytes(self.boot_sector[24:26], "little"), 9)
        self.assertEqual(int.from_bytes(self.boot_sector[26:28], "little"), 2)

    def test_boot_sector_entry_is_at_the_kernel_c01e_contract(self) -> None:
        self.assertEqual(self.boot_sector[0x1D], 0)
        self.assertEqual(self.boot_sector[0x1E], 0x3A)  # LD A,(FFA8h): disk slot

    def test_sector_one_holds_the_verified_marker(self) -> None:
        self.assertEqual(self.boot_sector[SECTOR_SIZE : SECTOR_SIZE + 4], b"RB01")


class IdeBootImageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.boot_sector = IDE_BOOT_SECTOR_PATH.read_bytes()

    def test_image_contains_the_boot_loader_and_marker(self) -> None:
        image = make_ide_image(self.boot_sector)

        self.assertEqual(len(image), IMAGE_SECTORS * SECTOR_SIZE)
        self.assertEqual(image[: 2 * SECTOR_SIZE], self.boot_sector)
        self.assertEqual(image[0], 0xEB)
        self.assertEqual(image[SECTOR_SIZE : SECTOR_SIZE + 4], b"RB01")

    def test_image_fills_unused_sectors(self) -> None:
        image = make_ide_image(self.boot_sector)

        self.assertEqual(
            image[2 * SECTOR_SIZE :],
            bytes((IDE_FILL,)) * ((IMAGE_SECTORS - 2) * SECTOR_SIZE),
        )

    def test_short_loader_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "need at least 1024"):
            make_ide_image(bytes(2 * SECTOR_SIZE - 1))


class IdeBootSectorLayoutTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.boot_sector = IDE_BOOT_SECTOR_PATH.read_bytes()

    def test_boot_sector_uses_the_c01e_loader_contract(self) -> None:
        self.assertEqual(len(self.boot_sector), 2 * SECTOR_SIZE)
        self.assertEqual(self.boot_sector[0], 0xEB)
        self.assertEqual(self.boot_sector[2], 0x90)
        self.assertEqual(self.boot_sector[0x1D], 0)
        self.assertEqual(self.boot_sector[0x1E], 0xCD)  # CALL sector-1 read

    def test_sector_one_holds_the_verified_marker(self) -> None:
        self.assertEqual(self.boot_sector[SECTOR_SIZE : SECTOR_SIZE + 4], b"RB01")


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
