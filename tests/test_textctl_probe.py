# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_textctl_probe import EXPECTED, validate_report


class TextctlProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_tab_must_advance_to_the_tab_stop(self) -> None:
        with self.assertRaisesRegex(ValueError, "TAB1"):
            validate_report(
                self.make_report().replace("TAB1=02,09", "TAB1=02,01")
            )

    def test_tab_at_line_end_must_wrap(self) -> None:
        with self.assertRaisesRegex(ValueError, "TAB2"):
            validate_report(
                self.make_report().replace("TAB2=03,01", "TAB2=02,01")
            )

    def test_cursor_up_must_move_one_row(self) -> None:
        with self.assertRaisesRegex(ValueError, "UP1"):
            validate_report(
                self.make_report().replace("UP1=04,03", "UP1=05,03")
            )

    def test_cursor_up_at_top_must_stay(self) -> None:
        with self.assertRaisesRegex(ValueError, "UP2"):
            validate_report(
                self.make_report().replace("UP2=01,03", "UP2=00,03")
            )

    def test_form_feed_must_clear_and_home(self) -> None:
        with self.assertRaisesRegex(ValueError, "FF"):
            validate_report(
                self.make_report().replace("FF=01,01,20", "FF=01,01,41")
            )


if __name__ == "__main__":
    unittest.main()
