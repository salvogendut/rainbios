# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_bbcbasic import validate_state
from tools.run_1983_bbcbasic_graphics import (
    validate_state as validate_graphics_state,
)
from tools.run_1983_bbcbasic_tape import (
    validate_state as validate_tape_state,
)


VALID_STATE = (
    "state frame=241 pc=13F5 sp=F2F6 slot=F4 subslot=00 "
    "mapper=00,00,00,00 vram_nonzero=9885 vdp_r0=00 vdp_r1=F0\n"
)


class Emulator1983BbcBasicTests(unittest.TestCase):
    def test_waiting_basic_state_is_accepted(self) -> None:
        fields = validate_state(VALID_STATE)
        self.assertEqual(fields["slot"], "F4")

    def test_unmapped_payload_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "slot"):
            validate_state(VALID_STATE.replace("slot=F4", "slot=F0"))

    def test_wrong_video_mode_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "vdp_r1"):
            validate_state(VALID_STATE.replace("vdp_r1=F0", "vdp_r1=E0"))

    def test_payload_pc_is_not_a_blocking_bios_wait(self) -> None:
        with self.assertRaisesRegex(ValueError, "PC"):
            validate_state(VALID_STATE.replace("pc=13F5", "pc=4400"))

    def test_graphics_program_state_is_accepted(self) -> None:
        state = (
            "state frame=7201 pc=5114 sp=F2E0 slot=F4 subslot=00 "
            "mapper=00,00,00,00 vram_nonzero=7000 vdp_r0=02 vdp_r1=E0\n"
        )
        fields = validate_graphics_state(state)
        self.assertEqual(fields["vdp_r0"], "02")

    def test_graphics_program_must_remain_in_graphics_mode(self) -> None:
        state = (
            "state frame=7201 pc=5114 sp=F2E0 slot=F4 subslot=00 "
            "mapper=00,00,00,00 vram_nonzero=7000 vdp_r0=00 vdp_r1=F0\n"
        )
        with self.assertRaisesRegex(ValueError, "vdp_r0"):
            validate_graphics_state(state)

    def test_tape_program_success_state_is_accepted(self) -> None:
        state = (
            "state frame=1801 pc=4400 sp=F200 slot=F8 subslot=00 "
            "mapper=00,00,00,00 vram_nonzero=9553 vdp_r0=00 vdp_r1=F0\n"
        )
        self.assertEqual(validate_tape_state(state)["slot"], "F8")
        with self.assertRaisesRegex(ValueError, "expected success"):
            validate_tape_state(state.replace("pc=4400", "pc=4300"))


if __name__ == "__main__":
    unittest.main()
