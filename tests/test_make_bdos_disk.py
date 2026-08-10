# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.make_bdos_disk import (
    COMMAND_NAME,
    FILE_NAME,
    FIRST_DATA,
    FIRST_DIRECTORY,
    SECTOR_SIZE,
    VOLUME_NAME,
    make_image,
)


class MakeBdosDiskTests(unittest.TestCase):
    def test_places_source_built_system_file_in_fat12_image(self) -> None:
        boot = b"\xeb\x1c\x90" + bytes(SECTOR_SIZE - 3)
        system = bytes((index * 13 + 7) & 0xFF for index in range(1300))
        image = make_image(boot, system)
        self.assertEqual(len(image), 720 * 1024)
        self.assertEqual(image[:3], b"\xeb\x1c\x90")
        directory = FIRST_DIRECTORY * SECTOR_SIZE
        self.assertEqual(image[directory : directory + 11], VOLUME_NAME)
        self.assertEqual(image[directory + 11], 0x08)
        self.assertEqual(image[directory + 32], 0xE5)
        self.assertEqual(image[directory + 2 * 32 + 11], 0x0F)
        for index in range(3, 11):
            self.assertEqual(image[directory + index * 32 + 11], 0x08)
        self.assertEqual(
            image[directory + 11 * 32 : directory + 11 * 32 + 11], FILE_NAME
        )
        self.assertEqual(
            image[directory + 12 * 32 : directory + 12 * 32 + 11], COMMAND_NAME
        )
        self.assertEqual(
            image[FIRST_DATA * SECTOR_SIZE : FIRST_DATA * SECTOR_SIZE + len(system)],
            system,
        )


if __name__ == "__main__":
    unittest.main()
