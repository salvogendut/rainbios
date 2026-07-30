# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_keyboard_probe import EXPECTED, validate_report


class KeyboardProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_empty_buffer_must_set_zero(self) -> None:
        with self.assertRaisesRegex(ValueError, "EMPTY"):
            validate_report(
                self.make_report().replace(
                    "EMPTY=1,FBF0,FBF0",
                    "EMPTY=0,FBF0,FBF0",
                )
            )

    def test_chget_must_preserve_non_af_registers(self) -> None:
        with self.assertRaisesRegex(ValueError, "CHAR"):
            validate_report(
                self.make_report().replace(
                    "CHAR=61,1234,5678,9ABC",
                    "CHAR=61,0000,5678,9ABC",
                )
            )

    def test_kilbuf_must_reset_both_pointers(self) -> None:
        with self.assertRaisesRegex(ValueError, "KILLED"):
            validate_report(
                self.make_report().replace(
                    "KILLED=1,FBF0,FBF0",
                    "KILLED=0,FBF2,FBF1",
                )
            )

    def test_blocking_chget_must_wait_for_return(self) -> None:
        with self.assertRaisesRegex(ValueError, "BLOCKING"):
            validate_report(
                self.make_report().replace("BLOCKING=0D", "BLOCKING=00")
            )


if __name__ == "__main__":
    unittest.main()
