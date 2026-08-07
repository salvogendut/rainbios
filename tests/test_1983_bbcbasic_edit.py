# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_bbcbasic_edit import parse_markers, validate_state


GOOD = (
    "state frame=6001 pc=5124 sp=F300 slot=F4 subslot=00 "
    "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=9170 "
    "vdp_r0=00 vdp_r1=F0\n"
    "F3C8: 5A 5A\n"
)


class BbcbasicEditTests(unittest.TestCase):
    def test_edit_state_is_accepted(self) -> None:
        self.assertEqual(validate_state(GOOD)["slot"], "F4")

    def test_corrected_markers_are_required(self) -> None:
        for bad in ("F3C8: FA 5A\n", "F3C8: 5A FA\n", "F3C8: FA FA\n"):
            with self.assertRaises(ValueError):
                validate_state(GOOD.replace("F3C8: 5A 5A\n", bad))

    def test_missing_markers_are_rejected(self) -> None:
        with self.assertRaises(ValueError):
            validate_state(GOOD.replace("F3C8: 5A 5A\n", "F3C0: 5A 5A\n"))

    def test_blank_vram_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            validate_state(GOOD.replace("vram_nonzero=9170", "vram_nonzero=0"))

    def test_slot_must_be_the_external_cartridge(self) -> None:
        with self.assertRaises(ValueError):
            validate_state(GOOD.replace("slot=F4", "slot=FC"))

    def test_parse_markers(self) -> None:
        self.assertEqual(parse_markers("F3C8: 5A 5A\n"), {0xF3C8: 0x5A, 0xF3C9: 0x5A})
        self.assertEqual(parse_markers("F3C8: 5A\n"), {0xF3C8: 0x5A})


if __name__ == "__main__":
    unittest.main()
