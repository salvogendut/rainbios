# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_services_probe import EXPECTED, validate_report


class ServicesProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        lines = ["INTERRUPT=0100,011E,1E,F0"]
        lines.extend(f"{key}={value}" for key, value in EXPECTED.items())
        return "\n".join(lines)

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_stalled_jiffy_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "JIFFY"):
            validate_report(
                self.make_report().replace(
                    "INTERRUPT=0100,011E,1E,F0",
                    "INTERRUPT=0100,0100,1E,F0",
                )
            )

    def test_unrestored_hook_map_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "primary map"):
            validate_report(
                self.make_report().replace(
                    "INTERRUPT=0100,011E,1E,F0",
                    "INTERRUPT=0100,011E,1E,FC",
                )
            )


if __name__ == "__main__":
    unittest.main()
