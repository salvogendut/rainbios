# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_mapper_probe import EXPECTED, validate_report


class MapperProbeTests(unittest.TestCase):
    def test_complete_report_is_accepted(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        validate_report(report)

    def test_segment_count_must_match_ram(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "MAPPER_SEGMENTS"):
            validate_report(
                report.replace("MAPPER_SEGMENTS=08", "MAPPER_SEGMENTS=04")
            )

    def test_segment7_must_be_distinct(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "SEG7"):
            validate_report(
                report.replace("SEG7=7A\nSEG0=5A", "SEG7=5A\nSEG0=5A")
            )

    def test_baseline_map_must_be_preserved(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "BASELINE_MAP"):
            validate_report(report.replace("BASELINE_MAP=F0", "BASELINE_MAP=00"))


if __name__ == "__main__":
    unittest.main()
