# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_embedded_basic_tape import validate_state


class EmbeddedBasicTapeTests(unittest.TestCase):
    def test_tape_success_state_is_accepted(self) -> None:
        state = (
            "state frame=3001 pc=4400 sp=F2D6 slot=F8 subslot=00 "
            "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=9170 "
            "vdp_r0=00 vdp_r1=F0\n"
        )
        self.assertEqual(validate_state(state)["slot"], "F8")

    def test_success_pc_must_be_4400(self) -> None:
        state = (
            "state frame=3001 pc=43FE sp=F2D6 slot=F8 subslot=00 "
            "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=9170 "
            "vdp_r0=00 vdp_r1=F0\n"
        )
        with self.assertRaises(ValueError):
            validate_state(state)

    def test_blank_vram_is_rejected(self) -> None:
        state = (
            "state frame=3001 pc=4400 sp=F2D6 slot=F8 subslot=00 "
            "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=0 "
            "vdp_r0=00 vdp_r1=F0\n"
        )
        with self.assertRaises(ValueError):
            validate_state(state)

    def test_slot_must_match_the_external_path(self) -> None:
        state = (
            "state frame=3001 pc=4400 sp=F2D6 slot=FC subslot=00 "
            "mapper=00,00,00,00 cycles=0 instructions=0 vram_nonzero=9170 "
            "vdp_r0=00 vdp_r1=F0\n"
        )
        with self.assertRaises(ValueError):
            validate_state(state)


if __name__ == "__main__":
    unittest.main()
