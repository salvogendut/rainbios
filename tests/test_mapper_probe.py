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
                report.replace("MAPPER_SEGMENTS=00", "MAPPER_SEGMENTS=80")
            )

    def test_expected_segment_count_can_model_unpopulated_banks(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        report = report.replace("MAPPER_SEGMENTS=00", "MAPPER_SEGMENTS=20")
        validate_report(report, "20")

    def test_segment255_must_be_distinct(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "SEG255"):
            validate_report(
                report.replace("SEG255=7A\nSEG0=5A", "SEG255=5A\nSEG0=5A")
            )

    def test_baseline_map_must_be_preserved(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "BASELINE_MAP"):
            validate_report(report.replace("BASELINE_MAP=F0", "BASELINE_MAP=00"))


if __name__ == "__main__":
    unittest.main()
