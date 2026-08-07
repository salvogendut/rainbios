# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_embedded_basic_graphics import validate_state


class EmbeddedBasicGraphicsTests(unittest.TestCase):
    def test_graphics_state_is_accepted(self) -> None:
        state = (
            "state frame=7201 pc=68A4 sp=F2FE slot=FC subslot=00 "
            "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=7106 "
            "vdp_r0=02 vdp_r1=E0\n"
        )
        self.assertEqual(validate_state(state)["slot"], "FC")

    def test_slot_must_be_the_payload_ram(self) -> None:
        state = (
            "state frame=7201 pc=68A4 sp=F2FE slot=F4 subslot=00 "
            "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=7106 "
            "vdp_r0=02 vdp_r1=E0\n"
        )
        with self.assertRaises(ValueError):
            validate_state(state)

    def test_blank_vram_is_rejected(self) -> None:
        state = (
            "state frame=7201 pc=68A4 sp=F2FE slot=FC subslot=00 "
            "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=0 "
            "vdp_r0=02 vdp_r1=E0\n"
        )
        with self.assertRaises(ValueError):
            validate_state(state)

    def test_basic_must_reach_graphics_ii(self) -> None:
        state = (
            "state frame=7201 pc=68A4 sp=F2FE slot=FC subslot=00 "
            "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=7106 "
            "vdp_r0=00 vdp_r1=F0\n"
        )
        with self.assertRaises(ValueError):
            validate_state(state)


if __name__ == "__main__":
    unittest.main()
