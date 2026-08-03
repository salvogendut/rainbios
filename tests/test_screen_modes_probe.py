# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_screen_modes_probe import EXPECTED, validate_report


class ScreenModesProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_settxt_must_switch_to_screen_zero(self) -> None:
        with self.assertRaisesRegex(ValueError, "SETTXT"):
            validate_report(
                self.make_report().replace("SETTXT=00,F0,00,00,01,36,07,F1,00,28,55,01,01",
                                           "SETTXT=02,E0,06,FF,03,36,07,01,02,20,55,01,01")
            )

    def test_settxt_must_not_clear_the_tables(self) -> None:
        with self.assertRaisesRegex(ValueError, "SETTXT"):
            validate_report(
                self.make_report().replace("SETTXT=00,F0,00,00,01,36,07,F1,00,28,55,01,01",
                                           "SETTXT=00,F0,00,00,01,36,07,F1,00,28,20,01,01")
            )

    def test_settxt_must_home_the_cursor(self) -> None:
        with self.assertRaisesRegex(ValueError, "SETTXT"):
            validate_report(
                self.make_report().replace("SETTXT=00,F0,00,00,01,36,07,F1,00,28,55,01,01",
                                           "SETTXT=00,F0,00,00,01,36,07,F1,00,28,55,07,09")
            )

    def test_sett32_must_match_init32(self) -> None:
        with self.assertRaisesRegex(ValueError, "SETT32"):
            validate_report(
                self.make_report().replace("SETT32=00,E0,06,80,00,36,07,F1,01,20",
                                           "SETT32=00,F0,00,00,01,36,07,F1,00,28")
            )

    def test_setgrp_must_match_initgrp(self) -> None:
        with self.assertRaisesRegex(ValueError, "SETGRP"):
            validate_report(
                self.make_report().replace("SETGRP=02,E0,06,FF,03,36,07,01,02,20",
                                           "SETGRP=02,E0,06,FF,03,36,07,01,01,20")
            )


if __name__ == "__main__":
    unittest.main()
