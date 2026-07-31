# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_external_cartridge_probe import validate_report


VALID_REPORT = """\
PC=468C
SP=F374
SLOT=D4
VDP_R0=00
VDP_R1=F0
"""


class ExternalCartridgeProbeTests(unittest.TestCase):
    def test_complete_report_is_accepted(self) -> None:
        values = validate_report(
            VALID_REPORT,
            expected_vdp_r0=0x00,
            expected_vdp_r1=0xF0,
        )
        self.assertEqual(values["PC"], "468C")

    def test_bios_execution_is_accepted(self) -> None:
        values = validate_report(
            VALID_REPORT.replace("PC=468C", "PC=0600"),
            expected_vdp_r0=0x00,
            expected_vdp_r1=0xF0,
        )
        self.assertEqual(values["PC"], "0600")

    def test_wrong_video_mode_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "VDP_R1"):
            validate_report(
                VALID_REPORT,
                expected_vdp_r0=0x00,
                expected_vdp_r1=0xE0,
            )


if __name__ == "__main__":
    unittest.main()
