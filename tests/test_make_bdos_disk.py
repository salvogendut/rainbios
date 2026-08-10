# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.make_bdos_disk import FIRST_DATA, SECTOR_SIZE, make_image


class MakeBdosDiskTests(unittest.TestCase):
    def test_places_source_built_system_file_in_fat12_image(self) -> None:
        boot = b"\xeb\x1c\x90" + bytes(SECTOR_SIZE - 3)
        system = bytes((index * 13 + 7) & 0xFF for index in range(1300))
        image = make_image(boot, system)
        self.assertEqual(len(image), 720 * 1024)
        self.assertEqual(image[:3], b"\xeb\x1c\x90")
        self.assertEqual(image[7 * SECTOR_SIZE : 7 * SECTOR_SIZE + 11], b"MSXDOS  SYS")
        self.assertEqual(
            image[FIRST_DATA * SECTOR_SIZE : FIRST_DATA * SECTOR_SIZE + len(system)],
            system,
        )


if __name__ == "__main__":
    unittest.main()
