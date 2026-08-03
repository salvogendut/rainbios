# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import unittest

from tools.check_controller_probe import EXPECTED, validate_report


class ControllerProbeTests(unittest.TestCase):
    def make_report(self) -> str:
        return "\n".join(f"{key}={value}" for key, value in EXPECTED.items())

    def test_complete_report_is_accepted(self) -> None:
        validate_report(self.make_report())

    def test_cursor_direction_encoding_is_checked(self) -> None:
        with self.assertRaisesRegex(ValueError, "STICK_KEYS"):
            validate_report(
                self.make_report().replace(
                    "STICK_KEYS=00,01,02,03,04,05,06,07,08",
                    "STICK_KEYS=00,01,03,03,04,05,06,07,08",
                )
            )

    def test_trigger_value_and_register_preservation_are_checked(self) -> None:
        with self.assertRaisesRegex(ValueError, "TRIGGER_KEY"):
            validate_report(
                self.make_report().replace(
                    "TRIGGER_KEY=FF,1234,5678,9ABC",
                    "TRIGGER_KEY=01,0000,5678,9ABC",
                )
            )

    def test_mouse_request_and_axes_are_checked(self) -> None:
        with self.assertRaisesRegex(ValueError, "MOUSE_IDLE"):
            validate_report(
                self.make_report().replace(
                    "MOUSE_IDLE=FF,00,00,FF,00,00",
                    "MOUSE_IDLE=00,00,00,FF,00,00",
                )
            )

    def test_paddle_with_no_device_returns_zero(self) -> None:
        with self.assertRaisesRegex(ValueError, "PADDLE"):
            validate_report(
                self.make_report().replace("PADDLE=00,00,00", "PADDLE=00,40,00")
            )

    def test_psg_connector_state_is_checked(self) -> None:
        with self.assertRaisesRegex(ValueError, "PSG_PORT_B"):
            validate_report(
                self.make_report().replace(
                    "PSG_PORT_B=BC,93,CF", "PSG_PORT_B=00,00,00"
                )
            )


if __name__ == "__main__":
    unittest.main()
