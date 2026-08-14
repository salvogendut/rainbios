# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_cartridge import validate_state


VALID_STATE = (
    "state frame=181 pc=4029 sp=F376 slot=F4 subslot=00 "
    "mapper=00,00,00,00 vram_nonzero=9553\n"
)


class Emulator1983CartridgeTests(unittest.TestCase):
    def test_cartridge_execution_state_is_accepted(self) -> None:
        fields = validate_state(VALID_STATE)
        self.assertEqual(fields["pc"], "4029")

    def test_bios_execution_is_accepted(self) -> None:
        fields = validate_state(VALID_STATE.replace("pc=4029", "pc=0600"))
        self.assertEqual(fields["pc"], "0600")

    def test_unmapped_cartridge_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "slot"):
            validate_state(VALID_STATE.replace("slot=F4", "slot=F0"))

    def test_32k_cartridge_mapping_is_configurable(self) -> None:
        fields = validate_state(
            VALID_STATE.replace("slot=F4", "slot=D4"),
            expected_slot="D4",
        )
        self.assertEqual(fields["slot"], "D4")

    def test_expected_video_mode_is_checked(self) -> None:
        state = VALID_STATE.rstrip() + " vdp_r0=02 vdp_r1=E0\n"
        fields = validate_state(
            state,
            expected_vdp_r0="02",
            expected_vdp_r1="E0",
        )
        self.assertEqual(fields["vdp_r1"], "E0")
        with self.assertRaisesRegex(ValueError, "vdp_r1"):
            validate_state(state, expected_vdp_r1="F0")

    def test_allocator_shifted_stack_floor_is_configurable(self) -> None:
        shifted = VALID_STATE.replace("sp=F376", "sp=F073")
        with self.assertRaisesRegex(ValueError, "SP"):
            validate_state(shifted)
        fields = validate_state(shifted, minimum_sp=0xF060)
        self.assertEqual(fields["sp"], "F073")


if __name__ == "__main__":
    unittest.main()
