# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_cartridge_probe import validate_report


VALID_REPORT = """\
PC=402B
SP=F376
SLOT=F4
SIGNATURE=52,41,49,4E,5E
"""


class CartridgeProbeTests(unittest.TestCase):
    def test_running_primary_cartridge_is_accepted(self) -> None:
        values = validate_report(VALID_REPORT)
        self.assertEqual(values["SLOT"], "F4")

    def test_bios_pc_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "outside cartridge"):
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
