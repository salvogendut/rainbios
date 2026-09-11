# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.make_fat12_disk import (
    DIR_SECTORS,
    DISK_SIZE,
    EXPECTED,
    FILE_CHAIN,
    FILE_SIZE,
    FAT_SIZE,
    FIRST_DATA,
    FIRST_DIR,
    MEDIA,
    SECTOR_SIZE,
    SPC,
    make_blank_image,
    make_image,
)
from tools.run_1983_disk_fswrite import fat12_entry


class BlankFat12DiskTests(unittest.TestCase):
    def test_blank_image_is_formatted_and_non_bootable(self) -> None:
        image = make_blank_image()
        self.assertEqual(len(image), DISK_SIZE)
        self.assertEqual(image[:3], bytes(3))
        self.assertEqual(image[3:11], b"RBFAT12 ")
        self.assertEqual(int.from_bytes(image[11:13], "little"), SECTOR_SIZE)
        self.assertEqual(image[13], 2)
        self.assertEqual(image[21], MEDIA)
        self.assertEqual(image[510:512], b"\x55\xAA")

    def test_blank_image_has_mirrored_empty_fats_and_root(self) -> None:
        image = make_blank_image()
        fat_start = SECTOR_SIZE
        fat_size = FAT_SIZE * SECTOR_SIZE
        first = image[fat_start : fat_start + fat_size]
        second = image[fat_start + fat_size : fat_start + 2 * fat_size]
        self.assertEqual(first, second)
        self.assertEqual(fat12_entry(first, 0), 0xFF9)
        self.assertEqual(fat12_entry(first, 1), 0xFFF)
        self.assertEqual(fat12_entry(first, 2), 0)
        root = image[
            FIRST_DIR * SECTOR_SIZE : (FIRST_DIR + DIR_SECTORS) * SECTOR_SIZE
        ]
        self.assertEqual(root, bytes(len(root)))


class Fat12LoadFixtureTests(unittest.TestCase):
    def test_file_chain_crosses_8_bit_boundary_and_ends_odd(self) -> None:
        image = make_image()
        fat_start = SECTOR_SIZE
        fat_size = FAT_SIZE * SECTOR_SIZE
        fat = image[fat_start : fat_start + fat_size]
        self.assertEqual(
            fat,
            image[fat_start + fat_size : fat_start + 2 * fat_size],
        )
        self.assertEqual(FILE_CHAIN, (2, 0x100, 0x101))
        for current, following in zip(FILE_CHAIN, FILE_CHAIN[1:]):
            self.assertEqual(fat12_entry(fat, current), following)
        self.assertEqual(fat12_entry(fat, FILE_CHAIN[-1]), 0xFFF)

    def test_file_content_follows_sparse_chain(self) -> None:
        image = make_image()
        cluster_size = SPC * SECTOR_SIZE
        content = bytearray()
        for cluster in FILE_CHAIN:
            start = (FIRST_DATA + (cluster - 2) * SPC) * SECTOR_SIZE
            content.extend(image[start : start + cluster_size])
        self.assertEqual(len(content), FILE_SIZE)
        for offset, expected in EXPECTED.items():
            self.assertEqual(content[offset], expected)


if __name__ == "__main__":
    unittest.main()
