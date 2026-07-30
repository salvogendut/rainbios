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

    def test_bios_execution_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "outside cartridge"):
            validate_state(VALID_STATE.replace("pc=4029", "pc=0600"))

    def test_unmapped_cartridge_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "slot"):
            validate_state(VALID_STATE.replace("slot=F4", "slot=F0"))


if __name__ == "__main__":
    unittest.main()
