# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_iscntc_probe import check_markers, parse_ram_dump


GOOD_DUMP = "F381: 01 00 01 00 01 00 00 5A\n"


class IscntcProbeTests(unittest.TestCase):
    def test_complete_markers_are_accepted(self) -> None:
        self.assertEqual(check_markers(parse_ram_dump(GOOD_DUMP)), [])

    def test_break_must_set_carry(self) -> None:
        bad = GOOD_DUMP.replace("01 00 01", "00 00 01")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("ISCNTC break carry" in f for f in failures))

    def test_break_must_clear_the_buffer(self) -> None:
        bad = GOOD_DUMP.replace("00 01 00", "00 00 00")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("key buffer" in f for f in failures))

    def test_second_call_must_not_see_a_break(self) -> None:
        bad = GOOD_DUMP.replace("01 00 01", "01 00 01")
        bad = GOOD_DUMP.replace("00 01 00 01", "00 01 00 01")
        failures = check_markers(parse_ram_dump(bad.replace("01 00 01", "01 00 01")))
        self.assertEqual(failures, [])

    def test_no_break_must_clear_carry(self) -> None:
        bad = GOOD_DUMP.replace("00 5A\n", "01 5A\n")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("no-break carry" in f for f in failures))

    def test_pass_marker_is_required(self) -> None:
        bad = GOOD_DUMP.replace("00 5A\n", "00 00\n")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("pass marker" in f for f in failures))


if __name__ == "__main__":
    unittest.main()
