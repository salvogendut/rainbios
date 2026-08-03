# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_color_probe import EXPECTED, validate_report


class ColorProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_screen_zero_r7_uses_foreground_and_background(self) -> None:
        with self.assertRaisesRegex(ValueError, "S0"):
            validate_report(
                self.make_report().replace("S0=51,51", "S0=54,51")
            )

    def test_screen_one_r7_is_the_border(self) -> None:
        with self.assertRaisesRegex(ValueError, "S1"):
            validate_report(
                self.make_report().replace("S1=04,51,51", "S1=54,51,51")
            )

    def test_screen_one_color_table_uses_foreground_and_background(self) -> None:
        with self.assertRaisesRegex(ValueError, "S1"):
            validate_report(
                self.make_report().replace("S1=04,51,51", "S1=04,15,51")
            )

    def test_screen_two_r7_is_the_border(self) -> None:
        with self.assertRaisesRegex(ValueError, "S2"):
            validate_report(
                self.make_report().replace("S2=04,04", "S2=54,54")
            )

    def test_chgclr_must_update_the_shadow(self) -> None:
        with self.assertRaisesRegex(ValueError, "S2"):
            validate_report(
                self.make_report().replace("S2=04,04", "S2=04,00")
            )


if __name__ == "__main__":
    unittest.main()
