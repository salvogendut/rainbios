# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import pathlib
import tempfile
import unittest

from PIL import Image, ImageDraw

from tools.check_geobench import (
    parse_report,
    validate_active_screen,
    validate_application_state,
    validate_screenshot,
    validate_state,
)


class GeoBenchValidationTests(unittest.TestCase):
    def test_complete_runtime_state_is_accepted(self) -> None:
        fields = parse_report(
            "VDP_R0=0A\nVDP_R1=62\nSCRMOD=07\nMAPPER=03,02,01,00\n"
        )
        validate_state(fields)

    def test_wrong_video_mode_is_rejected(self) -> None:
        fields = parse_report(
            "VDP_R0=00\nVDP_R1=62\nSCRMOD=07\nMAPPER=03,02,01,00\n"
        )
        with self.assertRaisesRegex(ValueError, "active Screen 7"):
            validate_state(fields)

    def test_wrong_mapper_state_is_rejected(self) -> None:
        fields = parse_report(
            "VDP_R0=0A\nVDP_R1=62\nSCRMOD=07\nMAPPER=00,01,02,03\n"
        )
        with self.assertRaisesRegex(ValueError, "unexpected mapper"):
            validate_state(fields)

    def test_openmsx_mapper_readback_bits_are_accepted(self) -> None:
        fields = parse_report(
            "VDP_R0=0A\nVDP_R1=62\nSCRMOD=07\nMAPPER=E3,E2,E1,E0\n"
        )
        validate_state(fields)

    def test_openmsx_desktop_application_state_is_accepted(self) -> None:
        fields = parse_report(
            "PC=530B\nMAPPER=E3,E2,E1,E0\n"
            "APP_PAGES=02,05,06,07,08,09,0A,0B\n"
        )
        validate_application_state(fields)

    def test_openmsx_transient_kernel_pc_is_accepted(self) -> None:
        fields = parse_report(
            "PC=81FC\nMAPPER=E3,E2,E1,E0\n"
            "APP_PAGES=02,05,06,07,08,09,0A,0B\n"
        )
        validate_application_state(fields)

    def test_unmapped_desktop_application_is_rejected(self) -> None:
        fields = parse_report(
            "PC=530B\nMAPPER=E3,E6,E1,E0\n"
            "APP_PAGES=02,05,06,07,08,09,0A,0B\n"
        )
        with self.assertRaisesRegex(ValueError, "desktop segment"):
            validate_application_state(fields)

    def test_desktop_geometry_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "geobench.png"
            image = Image.new("RGB", (320, 240), (0, 0, 170))
            draw = ImageDraw.Draw(image)
            draw.rectangle((13, 14, 306, 22), fill=(255, 255, 255))
            draw.rectangle((20, 40, 25, 50), fill=(255, 0, 0))
            draw.rectangle((275, 180, 280, 190), fill=(255, 255, 255))
            draw.rectangle((274, 181, 275, 182), fill=(0, 0, 0))
            image.save(path)
            validate_screenshot(path)

    def test_text_prompt_without_status_bar_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "prompt.png"
            image = Image.new("RGB", (320, 240), (0, 0, 170))
            draw = ImageDraw.Draw(image)
            draw.rectangle((20, 40, 25, 50), fill=(255, 0, 0))
            draw.rectangle((40, 40, 45, 50), fill=(255, 255, 255))
            draw.rectangle((60, 40, 65, 50), fill=(0, 0, 0))
            image.save(path)
            with self.assertRaisesRegex(ValueError, "status bar"):
                validate_screenshot(path)

    def test_active_screen_without_desktop_geometry_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "active.png"
            image = Image.new("RGB", (320, 240), (0, 0, 170))
            draw = ImageDraw.Draw(image)
            draw.rectangle((20, 40, 25, 50), fill=(255, 0, 0))
            draw.rectangle((40, 40, 45, 50), fill=(255, 255, 255))
            draw.rectangle((60, 40, 65, 50), fill=(0, 0, 0))
            image.save(path)
            validate_active_screen(path)


if __name__ == "__main__":
    unittest.main()
