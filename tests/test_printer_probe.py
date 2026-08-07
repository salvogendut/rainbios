# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_printer_probe import validate_log, validate_report


VALID_REPORT = """\
NOPRINTER=00,1
READY=FF,0
WRITE1=0
WRITE2=0
LPTPOS=00
"""


class PrinterProbeTests(unittest.TestCase):
    def test_complete_report_is_accepted(self) -> None:
        validate_report(VALID_REPORT)

    def test_no_printer_must_report_busy(self) -> None:
        with self.assertRaisesRegex(ValueError, "NOPRINTER"):
            validate_report(
                VALID_REPORT.replace("NOPRINTER=00,1", "NOPRINTER=FF,0")
            )

    def test_attached_printer_must_report_ready(self) -> None:
        with self.assertRaisesRegex(ValueError, "READY"):
            validate_report(
                VALID_REPORT.replace("READY=FF,0", "READY=00,1")
            )

    def test_lptout_must_clear_carry(self) -> None:
        with self.assertRaisesRegex(ValueError, "WRITE1"):
            validate_report(
                VALID_REPORT.replace("WRITE1=0", "WRITE1=1")
            )

    def test_log_must_contain_both_written_bytes(self) -> None:
        with self.assertRaisesRegex(ValueError, "printer log"):
            validate_log("A")
        validate_log("AB")

    def test_no_break_must_leave_position_untouched(self) -> None:
        with self.assertRaisesRegex(ValueError, "LPTPOS"):
            validate_report(
                VALID_REPORT.replace("LPTPOS=00", "LPTPOS=05")
            )


if __name__ == "__main__":
    unittest.main()
