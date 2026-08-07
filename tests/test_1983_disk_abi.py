# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_disk_abi_probe import check_markers, parse_ram_dump


GOOD_DUMP = "F380: 00 01 01 01 00 43 FB 01 46 FB 42 5A\n"


class DiskAbiProbeTests(unittest.TestCase):
    def test_complete_markers_are_accepted(self) -> None:
        self.assertEqual(check_markers(parse_ram_dump(GOOD_DUMP)), [])

    def test_phydio_carry_must_be_set(self) -> None:
        bad = GOOD_DUMP.replace("00 01 01 01", "00 01 01 00")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("OUTDLP carry set" in f for f in failures))

    def test_getvcp_must_point_into_vcba(self) -> None:
        bad = GOOD_DUMP.replace("43 FB", "46 FB", 1)
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("GETVCP low byte" in f for f in failures))

    def test_format_must_dispatch_to_the_hook(self) -> None:
        bad = GOOD_DUMP.replace("42 5A", "00 5A")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("FORMAT dispatches" in f for f in failures))

    def test_pass_marker_is_required(self) -> None:
        bad = GOOD_DUMP.replace("42 5A", "42 00")
        failures = check_markers(parse_ram_dump(bad))
        self.assertTrue(any("pass marker" in f for f in failures))


if __name__ == "__main__":
    unittest.main()
