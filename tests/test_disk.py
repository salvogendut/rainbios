# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.make_test_disk import (
    DISK_SIZE,
    PROBE_MARKER,
    PROBE_MIDDLE,
    PROBE_SECTOR,
    PROBE_SUFFIX,
    SECTOR_SIZE,
    make_image,
    make_probe_sector,
)


class DiskFixtureTests(unittest.TestCase):
    def test_image_contains_one_deterministic_probe_sector(self) -> None:
        image = make_image()
        start = PROBE_SECTOR * SECTOR_SIZE

        self.assertEqual(len(image), DISK_SIZE)
        self.assertEqual(image[:start], bytes(start))
        self.assertEqual(image[start : start + SECTOR_SIZE], make_probe_sector())
        self.assertEqual(image[start + SECTOR_SIZE :], bytes(DISK_SIZE - start - SECTOR_SIZE))

    def test_probe_sector_has_independent_markers(self) -> None:
        sector = make_probe_sector()

        self.assertEqual(sector[: len(PROBE_MARKER)], PROBE_MARKER)
        self.assertEqual(sector[SECTOR_SIZE // 2], PROBE_MIDDLE)
        self.assertEqual(sector[-len(PROBE_SUFFIX) :], PROBE_SUFFIX)


if __name__ == "__main__":
    unittest.main()
