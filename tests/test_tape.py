# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_tape_probe import validate_report
from tools.check_tape_save_probe import validate_report as validate_save_report
from tools.make_test_cassette import CAS_MARKER, PROBE_PAYLOAD, make_image
from tools.run_1983_tape import validate_state


VALID_OPENMSX_REPORT = (
    "MARKER=54,41,50,45\n"
    "PC=4400\n"
    "PERIOD=02\n"
    "POSITION=4.15\n"
    "LENGTH=4.16\n"
    "TRACE=52,41,49,4E,54,41,50,45\n"
)
VALID_1983_STATE = (
    "state frame=601 pc=4400 sp=F376 slot=F4 subslot=00 "
    "mapper=00,00,00,00 cycles=1 instructions=1 vram_nonzero=1\n"
)


class TapeFixtureTests(unittest.TestCase):
    def test_cassette_image_contains_one_raw_data_block(self) -> None:
        self.assertEqual(make_image(), CAS_MARKER + PROBE_PAYLOAD)

    def test_openmsx_success_report_is_accepted(self) -> None:
        values = validate_report(VALID_OPENMSX_REPORT)
        self.assertEqual(values["TRACE"], "52,41,49,4E,54,41,50,45")

    def test_openmsx_failure_marker_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "marker"):
            validate_report(
                VALID_OPENMSX_REPORT.replace(
                    "MARKER=54,41,50,45", "MARKER=E1,FF,FF,FF"
                )
            )

    def test_1983_success_address_is_accepted(self) -> None:
        self.assertEqual(validate_state(VALID_1983_STATE)["pc"], "4400")

    def test_1983_failure_address_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "expected success"):
            validate_state(
                VALID_1983_STATE.replace("pc=4400", "pc=4103")
            )

    def test_cassette_save_report_requires_recorded_output(self) -> None:
        report = "STATUS=SUCCESS\nPC=4400\nMARKER=5A\nTAPE_SIZE=4096\n"
        self.assertEqual(validate_save_report(report)["TAPE_SIZE"], "4096")
        with self.assertRaisesRegex(ValueError, "small"):
            validate_save_report(report.replace("4096", "44"))


if __name__ == "__main__":
    unittest.main()
