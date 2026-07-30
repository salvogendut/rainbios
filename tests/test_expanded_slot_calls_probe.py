# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_expanded_slot_calls_probe import EXPECTED, validate_report


class ExpandedSlotCallsProbeTests(unittest.TestCase):
    def test_complete_report_is_accepted(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        validate_report(report)

    def test_page3_must_restore_both_selectors(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "RDSLT3"):
            validate_report(
                report.replace(
                    "RDSLT3=44,D234,A4,50/00/0",
                    "RDSLT3=44,D234,A4,50/40/0",
                )
            )

    def test_expansion_table_is_required(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "INIT"):
            validate_report(
                report.replace(
                    "INIT=00,00,80,00/00,00,00,00/50/00",
                    "INIT=00,00,00,00/00,00,00,00/50/00",
                )
            )

    def test_invalid_expanded_id_fails_closed(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "INVALID"):
            validate_report(report.replace("INVALID=50/00/1", "INVALID=E0/00/0"))


if __name__ == "__main__":
    unittest.main()
