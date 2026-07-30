# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_bbcbasic_smoke import validate_report


REPORT = """\
ROM_WRITES=0
BBC BASIC (Z80) Version 3.00+1
>PRINT 2+2
         4
1.41421356
RAINBIOS
>RUN
         1         2         3>*CAT
Storage unsupported
>PRINT TIME>=1000
        -1
>PRINT INKEY(1)
        -1
"""


class BbcBasicSmokeTests(unittest.TestCase):
    def test_complete_report_is_accepted(self) -> None:
        validate_report(REPORT)

    def test_rom_writes_are_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "ROM_WRITES"):
            validate_report(REPORT.replace("ROM_WRITES=0", "ROM_WRITES=1"))

    def test_wrong_edited_result_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "edited integer"):
            validate_report(REPORT.replace("         4", "         5"))

    def test_missing_timeout_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "INKEY timeout"):
            validate_report(REPORT.replace("        -1", "         0", 1))


if __name__ == "__main__":
    unittest.main()
