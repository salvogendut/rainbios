# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import pathlib
import tempfile
import unittest

from PIL import Image, ImageDraw

from tools.check_graphics_screenshot import validate_screenshot


class GraphicsScreenshotTests(unittest.TestCase):
    def make_image(self, path: pathlib.Path, *, misplaced: bool = False) -> None:
        image = Image.new("RGB", (640, 480))
        draw = ImageDraw.Draw(image)
        offset = 100 if misplaced else 0
        box = (247 + offset, 190, 394 + offset, 287)
        draw.rectangle(box, outline=(219, 101, 89), width=4)
        draw.line(
            (box[0], box[1], box[2], box[3]),
            fill=(128, 118, 241),
            width=4,
        )
        draw.line(
            (box[0], box[3], box[2], box[1]),
            fill=(116, 208, 125),
            width=4,
        )
        image.save(path)

    def test_expected_geometry_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "graphics.png"
            self.make_image(path)
            validate_screenshot(path)

    def test_coloured_noise_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "graphics.png"
            self.make_image(path, misplaced=True)
            with self.assertRaisesRegex(ValueError, "expected rectangle"):
                validate_screenshot(path)


if __name__ == "__main__":
    unittest.main()
