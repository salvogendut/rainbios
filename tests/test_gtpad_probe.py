# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_gtpad_probe import validate_report


VALID_REPORT = """\
NODEVICE=00
FETCH=00
PADX=00
PADY=00
"""


class GtpadProbeTests(unittest.TestCase):
    def test_complete_report_is_accepted(self) -> None:
        validate_report(VALID_REPORT)

    def test_no_device_must_return_zero(self) -> None:
        with self.assertRaisesRegex(ValueError, "NODEVICE"):
            validate_report(
                VALID_REPORT.replace("NODEVICE=00", "NODEVICE=FF")
            )

    def test_not_touched_must_report_no_sense(self) -> None:
        with self.assertRaisesRegex(ValueError, "FETCH"):
            validate_report(
                VALID_REPORT.replace("FETCH=00", "FETCH=FF")
            )


if __name__ == "__main__":
    unittest.main()
