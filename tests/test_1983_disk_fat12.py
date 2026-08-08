# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_disk_fat12 import check_markers, parse_markers


GOOD_FAT12 = (
    "state frame=301 pc=C08C sp=E000 slot=FC subslot=AC "
    "mapper=03,02,01,00 cycles=0 instructions=0 vram_nonzero=7271 "
    "vdp_r0=02 vdp_r1=60\n"
    "F3D0: 00 00 00 0C 5A 5A\n"
)


class DiskFat12MarkerTests(unittest.TestCase):
    def test_success_markers_accepted(self) -> None:
        check_markers(GOOD_FAT12)

    def test_missing_pass_is_rejected(self) -> None:
        bad = GOOD_FAT12.replace("5A 5A\n", "00 00\n")
        with self.assertRaisesRegex(ValueError, "pass label"):
            check_markers(bad)

    def test_carry_set_is_rejected(self) -> None:
        bad = GOOD_FAT12.replace("00 00 00", "01 00 00", 1)
        with self.assertRaisesRegex(ValueError, "carry"):
            check_markers(bad)

    def test_error_code_is_rejected(self) -> None:
        bad = "F3D0: 00 12 00 0C 5A 5A\n"
        with self.assertRaisesRegex(ValueError, "error"):
            check_markers(bad)

    def test_wrong_size_is_rejected(self) -> None:
        bad = GOOD_FAT12.replace("00 0C", "00 00")
        with self.assertRaisesRegex(ValueError, "file size"):
            check_markers(bad)

    def test_compare_fail_is_rejected(self) -> None:
        bad = GOOD_FAT12.replace("5A 5A", "00 5A")
        with self.assertRaisesRegex(ValueError, "compare"):
            check_markers(bad)

    def test_parse_markers(self) -> None:
        markers = parse_markers("F3D0: 00 00 00 0C 5A 5A\n")
        self.assertEqual(markers[0xF3D0], 0x00)
        self.assertEqual(markers[0xF3D5], 0x5A)


if __name__ == "__main__":
    unittest.main()
