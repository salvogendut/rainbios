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


if __name__ == "__main__":
    unittest.main()
