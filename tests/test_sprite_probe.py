# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_sprite_probe import EXPECTED, validate_report


class SpriteProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_gspsiz_small_must_return_eight_bytes(self) -> None:
        with self.assertRaisesRegex(ValueError, "GSPSIZ0"):
            validate_report(
                self.make_report().replace("GSPSIZ0=08,0,E0", "GSPSIZ0=08,1,E0")
            )

    def test_gspsiz_big_must_report_carry_without_changing_r1(self) -> None:
        with self.assertRaisesRegex(ValueError, "GSPSIZ1"):
            validate_report(
                self.make_report().replace("GSPSIZ1=20,1,E2", "GSPSIZ1=20,0,E2")
            )

    def test_calpat_8x8_must_scale_by_eight(self) -> None:
        with self.assertRaisesRegex(ValueError, "CALPAT8"):
            validate_report(
                self.make_report().replace("CALPAT8=3828", "CALPAT8=382D")
            )

    def test_calpat_16x16_must_scale_by_thirty_two(self) -> None:
        with self.assertRaisesRegex(ValueError, "CALPAT16"):
            validate_report(
                self.make_report().replace("CALPAT16=38A0", "CALPAT16=3820")
            )

    def test_calatr_must_scale_by_four(self) -> None:
        with self.assertRaisesRegex(ValueError, "CALATR7"):
            validate_report(
                self.make_report().replace("CALATR7=1B1C", "CALATR7=1B20")
            )

    def test_clrspr_must_set_plane_and_color(self) -> None:
        with self.assertRaisesRegex(ValueError, "ATR0"):
            validate_report(
                self.make_report().replace("ATR0=D1,00,00,0F,D1,00,7C,0F",
                                           "ATR0=D1,00,00,00,D1,00,7C,0F")
            )

    def test_clrspr_must_clear_the_pattern_table(self) -> None:
        with self.assertRaisesRegex(ValueError, "PAT"):
            validate_report(
                self.make_report().replace("PAT=00,00", "PAT=00,55")
            )


if __name__ == "__main__":
    unittest.main()
