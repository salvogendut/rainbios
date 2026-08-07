# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_disk_boot import (
    check_loader_inputs,
    parse_loader_inputs,
)


class DiskBootLoaderInputsTests(unittest.TestCase):
    def test_expected_loader_inputs_are_accepted(self) -> None:
        text = "F3CC: 23 F3 00 00\n"
        self.assertEqual(parse_loader_inputs(text), {0xF3CC: 0x23, 0xF3CD: 0xF3, 0xF3CE: 0, 0xF3CF: 0})
        check_loader_inputs(text)

    def test_wrong_hl_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "DISKVE"):
            check_loader_inputs("F3CC: 00 C2 00 00\n")

    def test_nonzero_de_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "ENAKRN"):
            check_loader_inputs("F3CC: 23 F3 34 12\n")

    def test_missing_markers_are_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "not present"):
            check_loader_inputs("F3C0: 23 F3 00 00\n")
        with self.assertRaisesRegex(ValueError, "not present"):
            check_loader_inputs("F3CC: 23\n")


if __name__ == "__main__":
    unittest.main()
