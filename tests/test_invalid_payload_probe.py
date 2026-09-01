# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_invalid_payload_probe import EXPECTED, validate_report


class InvalidPayloadProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_invalid_init_must_not_run(self) -> None:
        with self.assertRaisesRegex(ValueError, "FALLBACK"):
            validate_report(
                self.make_report().replace(
                    "FALLBACK=00,4010,00001040,3",
                    "FALLBACK=FF,0000,42414421,1",
                )
            )

    def test_internal_payload_must_be_selected(self) -> None:
        with self.assertRaisesRegex(ValueError, "FALLBACK"):
            validate_report(
                self.make_report().replace("FALLBACK=00", "FALLBACK=FF")
            )


if __name__ == "__main__":
    unittest.main()
