# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_cursor_move_probe import EXPECTED, validate_report


class CursorMoveProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_rightc_must_advance_one_column(self) -> None:
        with self.assertRaisesRegex(ValueError, "RIGHTC"):
            validate_report(
                self.make_report().replace("RIGHTC=05,06", "RIGHTC=05,07")
            )

    def test_rightc_must_stop_at_the_line_end(self) -> None:
        with self.assertRaisesRegex(ValueError, "RIGHTEDGE"):
            validate_report(
                self.make_report().replace("RIGHTEDGE=05,28", "RIGHTEDGE=05,29")
            )

    def test_leftc_must_stop_at_column_one(self) -> None:
        with self.assertRaisesRegex(ValueError, "LEFTEDGE"):
            validate_report(
                self.make_report().replace("LEFTEDGE=05,01", "LEFTEDGE=05,00")
            )

    def test_upc_must_stop_at_the_top_row(self) -> None:
        with self.assertRaisesRegex(ValueError, "UPEDGE"):
            validate_report(
                self.make_report().replace("UPEDGE=01,05", "UPEDGE=00,05")
            )

    def test_downc_must_stop_at_the_bottom_row(self) -> None:
        with self.assertRaisesRegex(ValueError, "DOWNEDGE"):
            validate_report(
                self.make_report().replace("DOWNEDGE=18,05", "DOWNEDGE=19,05")
            )

    def test_tupc_must_scroll_the_text_down(self) -> None:
        with self.assertRaisesRegex(ValueError, "TUPC"):
            validate_report(
                self.make_report().replace("TUPC=01,01,20,58",
                                           "TUPC=01,01,20,20")
            )

    def test_tdownc_must_scroll_the_text_up(self) -> None:
        with self.assertRaisesRegex(ValueError, "TDOWNC"):
            validate_report(
                self.make_report().replace("TDOWNC=18,01,59,20",
                                           "TDOWNC=18,01,20,20")
            )


if __name__ == "__main__":
    unittest.main()
