# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_m1_probe import validate_report
from tools.run_1983_m1 import validate_state


class M1ProbeTests(unittest.TestCase):
    def test_valid_primary_slot_state(self) -> None:
        report = """\
SP=F380
SLOTS=0/0/2/2
BOTTOM=8000
HIMEM=F380
BIOSSLT=00
EXPTBL=00000000
SLTTBL=00000000
HOOKS=C9,C9,C9
"""
        validate_report(report, 2)

    def test_wrong_page_mapping_is_rejected(self) -> None:
        report = """\
SP=F380
SLOTS=0/0/2/3
BOTTOM=8000
HIMEM=F380
BIOSSLT=00
EXPTBL=00000000
SLTTBL=00000000
HOOKS=C9,C9,C9
"""
        with self.assertRaisesRegex(ValueError, "SLOTS"):
            validate_report(report, 2)

    def test_expanded_bios_and_ram_state(self) -> None:
        report = """\
SP=F380
SLOTS=0/0/3/3
BOTTOM=8000
HIMEM=F380
BIOSSLT=80
EXPTBL=80000080
SLTTBL=A0000000
HOOKS=C9,C9,C9
"""
        validate_report(report, 3, [0, 3], 0xA0, 0x80)

    def test_1983_state_requires_stack_and_ram_pages(self) -> None:
        state = (
            "state frame=121 pc=037A sp=F380 slot=F0 subslot=00 "
            "vram_nonzero=9553 vdp_r0=02 vdp_r1=C0\n"
        )
        self.assertEqual(validate_state(state)["sp"], "F380")
        with self.assertRaisesRegex(ValueError, "slot"):
            validate_state(state.replace("slot=F0", "slot=00"))
        self.assertEqual(
            validate_state(state, expected_subslot="00")["subslot"], "00"
        )
        with self.assertRaisesRegex(ValueError, "subslot"):
            validate_state(state, expected_subslot="A0")


if __name__ == "__main__":
    unittest.main()
