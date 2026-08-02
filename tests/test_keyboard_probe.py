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
                    "CHAR=41,1234,5678,9ABC",
                    "CHAR=41,0000,5678,9ABC",
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

    def test_inifnk_must_seed_list_prefix(self) -> None:
        with self.assertRaisesRegex(ValueError, "FNK"):
            validate_report(
                self.make_report().replace("FNK=4C,49,53", "FNK=00,00,00")
            )

    def test_ctrl_stop_must_set_breakx_carry(self) -> None:
        with self.assertRaisesRegex(ValueError, "BREAKX1"):
            validate_report(
                self.make_report().replace("BREAKX1=1", "BREAKX1=0")
            )

    def test_iscntc_must_consume_the_break(self) -> None:
        with self.assertRaisesRegex(ValueError, "ISCNTC1"):
            validate_report(
                self.make_report().replace("ISCNTC1=1,00", "ISCNTC1=1,03")
            )

    def test_dspfnk_must_set_display_flag(self) -> None:
        with self.assertRaisesRegex(ValueError, "DSPFNK"):
            validate_report(
                self.make_report().replace("DSPFNK=FF", "DSPFNK=00")
            )

    def test_totext_must_stay_in_text_mode(self) -> None:
        with self.assertRaisesRegex(ValueError, "TOTEXT"):
            validate_report(
                self.make_report().replace("TOTEXT=01,FF", "TOTEXT=02,FF")
            )

    def test_auto_repeat_must_fill_the_buffer(self) -> None:
        with self.assertRaisesRegex(ValueError, "REPEAT"):
            validate_report(
                self.make_report().replace("REPEAT=61,61,61", "REPEAT=61,00,00")
            )

    def test_pinlin_must_return_buffer_and_count(self) -> None:
        with self.assertRaisesRegex(ValueError, "PINLIN"):
            validate_report(
                self.make_report().replace(
                    "PINLIN=03,0,61,62,63", "PINLIN=03,0,00,62,63"
                )
            )

    def test_pinlin_backspace_must_remove_a_char(self) -> None:
        with self.assertRaisesRegex(ValueError, "PINLINBS"):
            validate_report(
                self.make_report().replace("PINLINBS=02,61,63", "PINLINBS=03,61,62,63")
            )

    def test_qinlin_must_set_auto_flag(self) -> None:
        with self.assertRaisesRegex(ValueError, "QINLIN"):
            validate_report(
                self.make_report().replace("QINLIN=03,0,61,62,63,01",
                                           "QINLIN=03,0,61,62,63,00")
            )

    def test_pinlin_break_must_set_carry(self) -> None:
        with self.assertRaisesRegex(ValueError, "PINLINBRK"):
            validate_report(
                self.make_report().replace("PINLINBRK=00,1", "PINLINBRK=00,0")
            )


if __name__ == "__main__":
    unittest.main()
