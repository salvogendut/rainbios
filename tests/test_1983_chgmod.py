# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_chgmod_probe import check_markers, parse_ram_dump


GOOD_DUMP = "F381: 00 01 02 03 01 03 01 01 5A\n"


class ChgmodProbeTests(unittest.TestCase):
    def test_complete_markers_are_accepted(self) -> None:
        self.assertEqual(check_markers(parse_ram_dump(GOOD_DUMP)), [])

    def test_modes_must_dispatch_to_scr(self) -> None:
        bad = GOOD_DUMP.replace("00 01 02", "00 00 02")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("SCRMOD 1" in f for f in failures))

    def test_unsupported_modes_must_set_carry(self) -> None:
        bad = GOOD_DUMP.replace("01 03 01", "00 03 01")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("CHGMOD(4) carry" in f for f in failures))

    def test_unsupported_mode_keeps_scr(self) -> None:
        bad = GOOD_DUMP.replace("01 03 01", "01 00 01")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("leaves SCRMOD" in f for f in failures))

    def test_pass_marker_is_required(self) -> None:
        bad = GOOD_DUMP.replace("01 5A\n", "01 00\n")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("pass marker" in f for f in failures))


if __name__ == "__main__":
    unittest.main()
