# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_slot_calls_probe import EXPECTED, validate_report


class SlotCallsProbeTests(unittest.TestCase):
    def test_complete_report_is_accepted(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        validate_report(report)

    def test_unsafe_page3_return_is_rejected(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "ENASLT3"):
            validate_report(report.replace("ENASLT3=64,0", "ENASLT3=64,1"))


if __name__ == "__main__":
    unittest.main()
