# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_payload_state_probe import validate_report


class PayloadStateProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join([
            "PC=4010",
            "SP=F380",
            "AF=00,44",
            "BC=0000",
            "DE=0000",
            "HL=0000",
            "IX=0000",
            "IY=0000",
            "SLOT=FC",
            "BUF=FBF0,FBF0",
            "JIFFY=012E,1",
        ])

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_sp_must_be_f380(self) -> None:
        with self.assertRaisesRegex(ValueError, "SP"):
            validate_report(
                self.make_report().replace("SP=F380", "SP=F300")
            )

    def test_accumulator_must_be_zero(self) -> None:
        with self.assertRaisesRegex(ValueError, "AF"):
            validate_report(
                self.make_report().replace("AF=00,44", "AF=5A,44")
            )

    def test_bc_must_be_zero(self) -> None:
        with self.assertRaisesRegex(ValueError, "BC"):
            validate_report(
                self.make_report().replace("BC=0000", "BC=1234")
            )

    def test_hl_must_be_zero(self) -> None:
        with self.assertRaisesRegex(ValueError, "HL"):
            validate_report(
                self.make_report().replace("HL=0000", "HL=1234")
            )

    def test_page_one_must_be_ram_slot_three(self) -> None:
        with self.assertRaisesRegex(ValueError, "SLOT"):
            validate_report(
                self.make_report().replace("SLOT=FC", "SLOT=F0")
            )

    def test_keyboard_buffer_must_be_empty(self) -> None:
        with self.assertRaisesRegex(ValueError, "BUF"):
            validate_report(
                self.make_report().replace("BUF=FBF0,FBF0", "BUF=FBF0,FBF2")
            )

    def test_interrupts_must_be_live(self) -> None:
        with self.assertRaisesRegex(ValueError, "JIFFY"):
            validate_report(
                self.make_report().replace("JIFFY=012E,1", "JIFFY=012E,0")
            )


if __name__ == "__main__":
    unittest.main()
