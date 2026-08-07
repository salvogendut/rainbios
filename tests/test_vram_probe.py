# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_vram_probe import EXPECTED, validate_report


class VramProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_wrtvrm_must_match_rdvrm(self) -> None:
        with self.assertRaisesRegex(ValueError, "ROUNDTRIP"):
            validate_report(
                self.make_report().replace("ROUNDTRIP=5A,5A",
                                           "ROUNDTRIP=5A,00")
            )

    def test_read_low_boundary_must_return_the_seed(self) -> None:
        with self.assertRaisesRegex(ValueError, "READLOW"):
            validate_report(
                self.make_report().replace("READLOW=11", "READLOW=00")
            )

    def test_address_must_wrap_at_14_bits(self) -> None:
        with self.assertRaisesRegex(ValueError, "READWRAP"):
            validate_report(
                self.make_report().replace("READWRAP=11", "READWRAP=00")
            )

    def test_read_top_of_vram_must_return_the_seed(self) -> None:
        with self.assertRaisesRegex(ValueError, "READTOP"):
            validate_report(
                self.make_report().replace("READTOP=33", "READTOP=00")
            )

    def test_filvrm_must_fill_the_requested_block(self) -> None:
        with self.assertRaisesRegex(ValueError, "FILL"):
            validate_report(
                self.make_report().replace("FILL=5A,5A,00", "FILL=5A,00,00")
            )

    def test_ldirmv_must_copy_vram_to_ram(self) -> None:
        with self.assertRaisesRegex(ValueError, "LDIRMV"):
            validate_report(
                self.make_report().replace("LDIRMV=61,62,63,64",
                                           "LDIRMV=61,00,63,64")
            )

    def test_ldirvm_must_copy_ram_to_vram(self) -> None:
        with self.assertRaisesRegex(ValueError, "LDIRVM"):
            validate_report(
                self.make_report().replace("LDIRVM=41,42,43,44",
                                           "LDIRVM=41,00,43,44")
            )

    def test_write_at_top_of_window_must_wrap(self) -> None:
        with self.assertRaisesRegex(ValueError, "WRAPTOP"):
            validate_report(
                self.make_report().replace("WRAPTOP=88", "WRAPTOP=00")
            )

    def test_write_at_window_base_must_wrap(self) -> None:
        with self.assertRaisesRegex(ValueError, "WRAPBASE"):
            validate_report(
                self.make_report().replace("WRAPBASE=77", "WRAPBASE=00")
            )

    def test_fill_must_wrap_across_the_16k_boundary(self) -> None:
        with self.assertRaisesRegex(ValueError, "FILLX"):
            validate_report(
                self.make_report().replace("FILLX=5C,5C,5C,5C",
                                           "FILLX=5C,5C,5C,00")
            )

    def test_ldirmv_must_wrap_across_the_boundary(self) -> None:
        with self.assertRaisesRegex(ValueError, "LDIRMVX"):
            validate_report(
                self.make_report().replace("LDIRMVX=71,74,75,78",
                                           "LDIRMVX=71,00,75,78")
            )

    def test_register_pair_must_survive_interleaved_interrupts(self) -> None:
        with self.assertRaisesRegex(ValueError, "ORDER"):
            validate_report(
                self.make_report().replace("ORDER=5A", "ORDER=00")
            )

    def test_port_ordering_hook_must_fire(self) -> None:
        with self.assertRaisesRegex(ValueError, "HOOKFIRE"):
            validate_report(
                self.make_report().replace("HOOKFIRE=01", "HOOKFIRE=00")
            )


if __name__ == "__main__":
    unittest.main()
