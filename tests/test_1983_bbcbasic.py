# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.run_1983_bbcbasic import validate_state


VALID_STATE = (
    "state frame=241 pc=07DB sp=F2F6 slot=F4 subslot=00 "
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
        with self.assertRaisesRegex(ValueError, "outside RainBIOS"):
            validate_state(VALID_STATE.replace("pc=07DB", "pc=4400"))


if __name__ == "__main__":
    unittest.main()
