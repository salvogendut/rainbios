# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_grpprt_probe import EXPECTED, validate_report


class GrpprtProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_grpprt_must_render_the_glyph(self) -> None:
        with self.assertRaisesRegex(ValueError, "GLYPH"):
            validate_report(
                self.make_report().replace("GLYPH=38,44,44,7C,44,44,44,00",
                                           "GLYPH=00,44,44,7C,44,44,44,00")
            )

    def test_grpprt_must_color_with_foreground(self) -> None:
        with self.assertRaisesRegex(ValueError, "COLOR"):
            validate_report(
                self.make_report().replace("COLOR=F1", "COLOR=11")
            )

    def test_grpprt_must_advance_the_cursor(self) -> None:
        with self.assertRaisesRegex(ValueError, "ADVANCE"):
            validate_report(
                self.make_report().replace("ADVANCE=03,03", "ADVANCE=03,02")
            )

    def test_grpprt_carriage_return_must_home_the_column(self) -> None:
        with self.assertRaisesRegex(ValueError, "CR"):
            validate_report(
                self.make_report().replace("CR=03,01", "CR=03,03")
            )

    def test_grpprt_line_feed_must_advance_the_row(self) -> None:
        with self.assertRaisesRegex(ValueError, "LF"):
            validate_report(
                self.make_report().replace("LF=04,01", "LF=03,01")
            )


if __name__ == "__main__":
    unittest.main()
