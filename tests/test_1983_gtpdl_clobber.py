# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_gtpdl_clobber_probe import check_markers, parse_ram_dump


GOOD_DUMP = "F381: 8F 00 34 12 78 56 BC 9A 8F 5A\n"


class GtpdlClobberProbeTests(unittest.TestCase):
    def test_complete_markers_are_accepted(self) -> None:
        self.assertEqual(check_markers(parse_ram_dump(GOOD_DUMP)), [])

    def test_no_paddle_result_is_zero(self) -> None:
        bad = GOOD_DUMP.replace("8F 00 34", "8F 05 34")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("GTPDL result" in f for f in failures))

    def test_hl_is_preserved(self) -> None:
        bad = GOOD_DUMP.replace("34 12", "00 00")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("HL" in f for f in failures))

    def test_r15_is_restored(self) -> None:
        bad = GOOD_DUMP.replace("8F 5A", "00 5A")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("R15" in f for f in failures))

    def test_pass_marker_is_required(self) -> None:
        bad = GOOD_DUMP.replace("8F 5A", "8F 00")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("pass marker" in f for f in failures))


if __name__ == "__main__":
    unittest.main()
