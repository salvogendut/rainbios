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

    def test_unrestored_read_map_is_rejected(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "RDSLT3"):
            validate_report(report.replace("RDSLT3=44,D234,F0,0", "RDSLT3=44,D234,30,0"))

    def test_expanded_write_must_not_mutate_ram(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "WRSLTEXP"):
            validate_report(
                report.replace(
                    "WRSLTEXP=55,1234,99,F0,1",
                    "WRSLTEXP=99,1234,99,F0,1",
                )
            )

    def test_nested_call_must_restore_outer_map(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "CALSLTNEST"):
            validate_report(
                report.replace(
                    "CALSLTNEST=5A,1234,5678,9ABC,5100,0300,F0,1",
                    "CALSLTNEST=5A,1234,5678,9ABC,5100,0300,FC,1",
                )
            )

    def test_page0_call_must_restore_map(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "CALSLT0"):
            validate_report(
                report.replace("CALSLT0=5A,1234,5678,9ABC,F0,0",
                               "CALSLT0=5A,1234,5678,9ABC,30,0")
            )

    def test_page3_call_must_preserve_carry(self) -> None:
        report = "\n".join(f"{key}={value}" for key, value in EXPECTED.items())
        with self.assertRaisesRegex(ValueError, "CALSLT3"):
            validate_report(
                report.replace("CALSLT3=A5,4321,6587,A9CB,F0,1",
                               "CALSLT3=A5,4321,6587,A9CB,F0,0")
            )


if __name__ == "__main__":
    unittest.main()
