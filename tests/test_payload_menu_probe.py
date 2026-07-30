# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_payload_menu_probe import EXPECTED, validate_report


class PayloadMenuProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_payload_must_not_autoboot(self) -> None:
        with self.assertRaisesRegex(ValueError, "DISCOVERY"):
            validate_report(
                self.make_report().replace(
                    "DISCOVERY=01,4010,0",
                    "DISCOVERY=01,4010,1",
                )
            )

    def test_menu_must_report_ready(self) -> None:
        with self.assertRaisesRegex(ValueError, "MENU"):
            validate_report(
                self.make_report().replace("MENU=1,1", "MENU=1,0")
            )

    def test_launch_contract_is_checked(self) -> None:
        with self.assertRaisesRegex(ValueError, "LAUNCH"):
            validate_report(
                self.make_report().replace(
                    "LAUNCH=F4,F380,00",
                    "LAUNCH=F4,F37E,01",
                )
            )

    def test_expanded_payload_launch_is_accepted(self) -> None:
        report = self.make_report()
        report = report.replace("DISCOVERY=01,4010,0", "DISCOVERY=8A,4010,0")
        report = report.replace("LAUNCH=F4,F380", "LAUNCH=F8,F380")
        values = validate_report(report, payload_slot="8A", launch_slot="F8")
        self.assertEqual(values["DISCOVERY"], "8A,4010,0")


if __name__ == "__main__":
    unittest.main()
