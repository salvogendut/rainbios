# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_invalid_payload_probe import EXPECTED, validate_report


class InvalidPayloadProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_invalid_init_must_not_run(self) -> None:
        with self.assertRaisesRegex(ValueError, "DISCOVERY"):
            validate_report(
                self.make_report().replace(
                    "DISCOVERY=FF,0000,04FF0000,0",
                    "DISCOVERY=FF,0000,42414421,1",
                )
            )

    def test_menu_must_report_missing(self) -> None:
        with self.assertRaisesRegex(ValueError, "MENU"):
            validate_report(
                self.make_report().replace("MENU=1,1", "MENU=1,0")
            )

    def test_selection_must_remain_guarded(self) -> None:
        with self.assertRaisesRegex(ValueError, "GUARDED"):
            validate_report(
                self.make_report().replace(
                    "GUARDED=0,04FF0000",
                    "GUARDED=1,42414421",
                )
            )


if __name__ == "__main__":
    unittest.main()
