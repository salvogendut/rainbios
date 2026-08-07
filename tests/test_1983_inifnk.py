# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_inifnk_probe import check_markers, parse_ram_dump


GOOD_DUMP = "F381: 4C 49 53 54 0D 20 53 45 4E 5A 5A\n"


class InifnkProbeTests(unittest.TestCase):
    def test_complete_markers_are_accepted(self) -> None:
        self.assertEqual(check_markers(parse_ram_dump(GOOD_DUMP)), [])

    def test_first_default_string_is_list(self) -> None:
        bad = GOOD_DUMP.replace("4C 49 53 54", "00 49 53 54")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("FNKSTR[0]" in f for f in failures))

    def test_last_default_string_is_screen_zero(self) -> None:
        bad = GOOD_DUMP.replace("53 45 4E", "00 45 4E")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("SCREEN" in f for f in failures))

    def test_fnkflg_is_not_touched(self) -> None:
        bad = GOOD_DUMP.replace("4E 5A 5A", "4E 00 5A")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("FNKFLG" in f for f in failures))

    def test_pass_marker_is_required(self) -> None:
        bad = GOOD_DUMP.replace("5A 5A\n", "5A 00\n")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("pass marker" in f for f in failures))


if __name__ == "__main__":
    unittest.main()
