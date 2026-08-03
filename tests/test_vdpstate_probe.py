# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_vdpstate_probe import EXPECTED, validate_report


class VdpStateProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_boot_registers_must_match_shadows(self) -> None:
        with self.assertRaisesRegex(ValueError, "BOOT"):
            validate_report(
                self.make_report().replace(
                    "BOOT=02,E0,06,FF,03,36,07,01,02,E0,06,FF,03,36,07,01,1800,0000,3800,1B00,02,20",
                    "BOOT=02,E0,06,FF,03,36,07,01,02,A0,06,FF,03,36,07,01,1800,0000,3800,1B00,02,20",
                )
            )

    def test_disscr_must_clear_the_display_bit(self) -> None:
        with self.assertRaisesRegex(ValueError, "DISSCR"):
            validate_report(
                self.make_report().replace("DISSCR=A0,A0", "DISSCR=E0,E0")
            )

    def test_enascr_must_restore_the_display_bit(self) -> None:
        with self.assertRaisesRegex(ValueError, "ENASCR"):
            validate_report(
                self.make_report().replace("ENASCR=E0,E0", "ENASCR=A0,E0")
            )

    def test_wrtvdp_must_update_the_shadow(self) -> None:
        with self.assertRaisesRegex(ValueError, "WRTVDP"):
            validate_report(
                self.make_report().replace("WRTVDP=08,08", "WRTVDP=08,06")
            )

    def test_initxt_state(self) -> None:
        with self.assertRaisesRegex(ValueError, "INITXT"):
            validate_report(
                self.make_report().replace(
                    "INITXT=00,F0,00,00,01,36,07,F1,00,F0,00,00,01,36,07,F1,0000,0800,0000,0000,00,28",
                    "INITXT=00,F0,00,00,01,36,07,F1,00,F0,00,00,01,36,07,F1,0000,0800,0000,0000,02,28",
                )
            )

    def test_initgrp_state(self) -> None:
        with self.assertRaisesRegex(ValueError, "INITGRP"):
            validate_report(
                self.make_report().replace(
                    "INITGRP=02,E0,06,FF,03,36,07,01,02,E0,06,FF,03,36,07,01,1800,0000,3800,1B00,02,20",
                    "INITGRP=02,E0,06,FF,03,36,07,01,02,E0,06,FF,03,36,07,01,1800,0000,3800,1B00,01,20",
                )
            )


if __name__ == "__main__":
    unittest.main()
