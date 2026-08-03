# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import pathlib
import tempfile
import unittest

from PIL import Image, ImageDraw

from tools.check_bbcbasic_screenshot import validate_screenshot


class BbcBasicScreenshotTests(unittest.TestCase):
    def make_image(self, *, prompt: bool = True) -> pathlib.Path:
        temporary = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
        temporary.close()
        path = pathlib.Path(temporary.name)
        image = Image.new("RGB", (640, 480), "black")
        drawing = ImageDraw.Draw(image)
        drawing.rectangle((45, 386, 200, 394), fill="white")
        if prompt:
            drawing.rectangle((44, 402, 50, 408), fill="white")
        image.save(path)
        self.addCleanup(path.unlink)
        return path

    def test_banner_and_prompt_are_accepted(self) -> None:
        validate_screenshot(self.make_image())

    def test_missing_prompt_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "prompt"):
            validate_screenshot(self.make_image(prompt=False))


if __name__ == "__main__":
    unittest.main()
