# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_screen3_probe import EXPECTED, validate_report


class Screen3ProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_rdvdp_must_mirror_the_status(self) -> None:
        with self.assertRaisesRegex(ValueError, "RDVDP"):
            validate_report(
                self.make_report().replace("RDVDP=00,00", "RDVDP=00,FF")
            )

    def test_inimlt_must_select_screen_three(self) -> None:
        with self.assertRaisesRegex(ValueError, "INIMLT"):
            validate_report(
                self.make_report().replace(
                    "INIMLT=03,20,00,E8,02,00,00,00,00,0800,0000,3800,1B00,D0,11",
                    "INIMLT=02,20,00,E8,02,00,00,00,00,0800,0000,3800,1B00,D0,11",
                )
            )

    def test_inimlt_must_program_the_multicolor_registers(self) -> None:
        with self.assertRaisesRegex(ValueError, "INIMLT"):
            validate_report(
                self.make_report().replace(
                    "INIMLT=03,20,00,E8,02,00,00,00,00,0800,0000,3800,1B00,D0,11",
                    "INIMLT=03,20,00,E8,06,00,00,00,00,0800,0000,3800,1B00,D0,11",
                )
            )

    def test_inimlt_must_hide_sprites(self) -> None:
        with self.assertRaisesRegex(ValueError, "INIMLT"):
            validate_report(
                self.make_report().replace(
                    "INIMLT=03,20,00,E8,02,00,00,00,00,0800,0000,3800,1B00,D0,11",
                    "INIMLT=03,20,00,E8,02,00,00,00,00,0800,0000,3800,1B00,00,11",
                )
            )

    def test_setmlt_must_match_inimlt_registers(self) -> None:
        with self.assertRaisesRegex(ValueError, "SETMLT"):
            validate_report(
                self.make_report().replace(
                    "SETMLT=00,E8,02,00,00,00,00",
                    "SETMLT=00,E8,06,00,00,00,00",
                )
            )


if __name__ == "__main__":
    unittest.main()
