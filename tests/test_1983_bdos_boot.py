# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_bdos_boot import parse_ram, validate


class BdosBootValidationTests(unittest.TestCase):
    def test_accepts_complete_machine_state(self) -> None:
        text = (
            "F3CC: 23 F3 68 F3 22 00 01 00 00 5A 04 02 4F 4B 0D 00\n"
            "state pc=0132 sp=E000 slot=FF vram_nonzero=1\n"
        )
        self.assertEqual(parse_ram(text)[0xF3D5], 0x5A)
        fields = validate(
            text,
            symbols={"disk_bdos_system_pass": 0x0132},
            expected_slot="FF",
        )
        self.assertEqual(fields["pc"], "0132")

    def test_rejects_zero_kernel_entry(self) -> None:
        text = (
            "F3CC: 23 F3 00 00 22 00 01 00 00 5A 04 02 4F 4B 0D 00\n"
            "state pc=0132 sp=E000 slot=FF vram_nonzero=1\n"
        )
        with self.assertRaisesRegex(ValueError, "ENAKRN"):
            validate(
                text,
                symbols={"disk_bdos_system_pass": 0x0132},
                expected_slot="FF",
            )


if __name__ == "__main__":
    unittest.main()
