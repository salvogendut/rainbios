# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_bbcbasic_scroll import parse_marker, validate_state


GOOD = (
    "state frame=6001 pc=68AA sp=F2FE slot=F4 subslot=00 "
    "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=9170 "
    "vdp_r0=00 vdp_r1=F0\n"
    "F3C8: A5\n"
)


class BbcbasicScrollTests(unittest.TestCase):
    def test_scroll_state_is_accepted(self) -> None:
        self.assertEqual(validate_state(GOOD)["slot"], "F4")

    def test_completion_marker_is_required(self) -> None:
        bad = GOOD.replace("F3C8: A5\n", "F3C8: 00\n")
        with self.assertRaises(ValueError):
            validate_state(bad)

    def test_blank_vram_is_rejected(self) -> None:
        bad = GOOD.replace("vram_nonzero=9170", "vram_nonzero=0")
        with self.assertRaises(ValueError):
            validate_state(bad)

    def test_slot_must_be_the_external_cartridge(self) -> None:
        bad = GOOD.replace("slot=F4", "slot=FC")
        with self.assertRaises(ValueError):
            validate_state(bad)

    def test_parse_marker(self) -> None:
        self.assertEqual(parse_marker("F3C8: A5\n"), 0xA5)
        self.assertIsNone(parse_marker("F3C0: A5\n"))


if __name__ == "__main__":
    unittest.main()
