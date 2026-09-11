# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.make_fat12_disk import (
    DIR_SECTORS,
    DISK_SIZE,
    FAT_SIZE,
    FIRST_DIR,
    MEDIA,
    SECTOR_SIZE,
    make_blank_image,
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


if __name__ == "__main__":
    unittest.main()
