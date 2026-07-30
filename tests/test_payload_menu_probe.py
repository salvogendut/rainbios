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


if __name__ == "__main__":
    unittest.main()
