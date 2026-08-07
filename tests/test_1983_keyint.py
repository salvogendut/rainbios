# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_keyint_probe import check_markers, parse_ram_dump


GOOD_DUMP = "F381: 00 01 80 5A\n"
GOOD_DUMP_OFFSET = "F381: 07 08 80 5A\n"


class KeyintProbeTests(unittest.TestCase):
    def test_complete_markers_are_accepted(self) -> None:
        self.assertEqual(check_markers(parse_ram_dump(GOOD_DUMP)), [])
        self.assertEqual(check_markers(parse_ram_dump(GOOD_DUMP_OFFSET)), [])

    def test_jiffy_must_increment_by_one(self) -> None:
        for bad in ("F381: 00 03 80 5A\n", "F381: 05 05 80 5A\n"):
            failures = check_markers(parse_ram_dump(bad))
            self.assertTrue(any("JIFFY grew" in f for f in failures))

    def test_statfl_holds_vdp_status(self) -> None:
        bad = GOOD_DUMP.replace("80 5A\n", "00 5A\n")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("STATFL" in f for f in failures))

    def test_pass_marker_is_required(self) -> None:
        bad = GOOD_DUMP.replace("80 5A\n", "80 00\n")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("pass marker" in f for f in failures))

    def test_missing_markers_are_reported(self) -> None:
        failures = check_markers(parse_ram_dump("F381: 00 01\n"))
        self.assertTrue(any("not present" in f for f in failures))


if __name__ == "__main__":
    unittest.main()
