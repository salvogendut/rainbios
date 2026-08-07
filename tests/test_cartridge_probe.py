# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_cartridge_probe import validate_report


VALID_REPORT = """\
ENTRYPC=4010
ENTRYSP=F088
ENTRYAF=01,33
ENTRYBC=0100
ENTRYDE=4010
ENTRYHL=4003
ENTRYIX=4010
ENTRYIY=0100
PC=402B
SP=F088
SLOT=F4
SIGNATURE=52,41,49,4E,5E
INITAF=01,33
INITBC=01,00
INITDE=40,10
INITHL=40,03
INITIX=40,10
INITIY=01,00
INITSP=F0,88
"""


class CartridgeProbeTests(unittest.TestCase):
    def test_running_primary_cartridge_is_accepted(self) -> None:
        values = validate_report(VALID_REPORT)
        self.assertEqual(values["SLOT"], "F4")

    def test_bios_pc_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "outside the cartridge"):
            validate_report(VALID_REPORT.replace("PC=402B", "PC=0600"))

    def test_missing_signature_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "SIGNATURE"):
            validate_report(
                VALID_REPORT.replace(
                    "SIGNATURE=52,41,49,4E,5E",
                    "SIGNATURE=00,00,00,00,00",
                )
            )

    def test_wrong_slot_map_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "SLOT"):
            validate_report(VALID_REPORT.replace("SLOT=F4", "SLOT=F0"))

    def test_a_and_b_must_carry_the_same_slot_id(self) -> None:
        with self.assertRaisesRegex(ValueError, "A .* and B"):
            validate_report(
                VALID_REPORT.replace("ENTRYAF=01,33", "ENTRYAF=02,33")
            )

    def test_c_must_be_zero_at_init(self) -> None:
        with self.assertRaisesRegex(ValueError, "C must be zero"):
            validate_report(
                VALID_REPORT.replace("ENTRYBC=0100", "ENTRYBC=0105")
            )

    def test_de_and_ix_must_be_the_init_pointer(self) -> None:
        with self.assertRaisesRegex(ValueError, "DE .* and IX"):
            validate_report(
                VALID_REPORT.replace("ENTRYDE=4010", "ENTRYDE=4020")
            )

    def test_iy_must_hold_the_slot_in_its_high_byte(self) -> None:
        with self.assertRaisesRegex(ValueError, "IY .* high byte"):
            validate_report(
                VALID_REPORT.replace("ENTRYIY=0100", "ENTRYIY=0101")
            )

    def test_sp_must_be_on_a_page3_stack(self) -> None:
        with self.assertRaisesRegex(ValueError, "SP .* page-3"):
            validate_report(
                VALID_REPORT.replace("ENTRYSP=F088", "ENTRYSP=F000")
            )

    def test_fixture_snapshot_must_match_breakpoint_capture(self) -> None:
        with self.assertRaisesRegex(ValueError, "INITAF"):
            validate_report(
                VALID_REPORT.replace("INITAF=01,33", "INITAF=10,33")
            )

    def test_entry_pc_must_match_the_configured_entry(self) -> None:
        with self.assertRaisesRegex(ValueError, "ENTRYPC"):
            validate_report(VALID_REPORT.replace("ENTRYPC=4010", "ENTRYPC=4020"))

    def test_page2_init_entry_is_accepted(self) -> None:
        # A page-2 cartridge INIT (mapper-style arrangement): entry and the
        # sampled loop PC live in page 2, and the slot map keeps page 2 on the
        # cartridge slot.
        report = VALID_REPORT.replace("PC=402B", "PC=805F")
        report = report.replace("ENTRYPC=4010", "ENTRYPC=8000")
        report = report.replace("ENTRYDE=4010", "ENTRYDE=8000")
        report = report.replace("ENTRYIX=4010", "ENTRYIX=8000")
        report = report.replace("INITDE=40,10", "INITDE=80,00")
        report = report.replace("INITIX=40,10", "INITIX=80,00")
        report = report.replace("SLOT=F4", "SLOT=D0")
        values = validate_report(report, expected_slot="D0", expected_entry=0x8000)
        self.assertEqual(values["SLOT"], "D0")

    def test_running_expanded_cartridge_is_accepted(self) -> None:
        report = VALID_REPORT.replace("SLOT=F4", "SLOT=F8")
        report += "EXPTBL=00,00,80,00\nSLTTBL=00,00,08,00\n"
        values = validate_report(
            report,
            expected_slot="F8",
            expected_exptbl="00,00,80,00",
            expected_slttbl="00,00,08,00",
        )
        self.assertEqual(values["SLTTBL"], "00,00,08,00")


if __name__ == "__main__":
    unittest.main()
