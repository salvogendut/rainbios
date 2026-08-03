# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_embedded_basic_probe import validate_report
from tools.run_1983_embedded_basic import validate_state


OPENMSX_REPORT = """\
ROM_WRITES=0
SLOT=FC
HEADER=41,42
DESCRIPTOR=52,42,50,31
BBC BASIC (Z80) Version 3.00+1
>PRINT 2+2
         4
"""

EMULATOR_1983_STATE = (
    "state frame=421 pc=14DA sp=F2F6 slot=FC subslot=00 "
    "mapper=00,00,00,00 vram_nonzero=9885 vdp_r0=00 vdp_r1=F0\n"
)


class EmbeddedBasicProbeTests(unittest.TestCase):
    def test_complete_openmsx_report_is_accepted(self) -> None:
        validate_report(OPENMSX_REPORT)

    def test_openmsx_rom_write_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "ROM_WRITES"):
            validate_report(OPENMSX_REPORT.replace("ROM_WRITES=0", "ROM_WRITES=1"))

    def test_1983_internal_slot_state_is_accepted(self) -> None:
        self.assertEqual(validate_state(EMULATOR_1983_STATE)["slot"], "FC")

    def test_1983_external_slot_state_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "slot"):
            validate_state(EMULATOR_1983_STATE.replace("slot=FC", "slot=F4"))


if __name__ == "__main__":
    unittest.main()
