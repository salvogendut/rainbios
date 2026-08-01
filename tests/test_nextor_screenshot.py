# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import pathlib
import tempfile
import unittest
from unittest import mock

from PIL import Image, ImageDraw

from tools import check_nextor_screenshot


class NextorScreenshotTests(unittest.TestCase):
    def make_image(
        self, *, banner: bool = True, prompt: bool = True
    ) -> pathlib.Path:
        temporary = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
        temporary.close()
        path = pathlib.Path(temporary.name)
        image = Image.new("RGB", (640, 480), "black")
        drawing = ImageDraw.Draw(image)
        if banner:
            drawing.rectangle((52, 148, 300, 170), fill="white")
        if prompt:
            drawing.rectangle((52, 196, 100, 202), fill="white")
        image.save(path)
        self.addCleanup(path.unlink)
        return path

    def expected_hashes(self, path: pathlib.Path) -> tuple[str, str]:
        with Image.open(path) as source:
            image = source.convert("RGB")
        return (
            check_nextor_screenshot.region_mask_hash(
                image, check_nextor_screenshot.BANNER_BOX
            ),
            check_nextor_screenshot.region_mask_hash(
                image, check_nextor_screenshot.PROMPT_BOX
            ),
        )

    def test_expected_banner_and_prompt_are_accepted(self) -> None:
        path = self.make_image()
        banner_hash, prompt_hash = self.expected_hashes(path)
        with mock.patch.multiple(
            check_nextor_screenshot,
            BANNER_HASH=banner_hash,
            PROMPT_HASH=prompt_hash,
        ):
            check_nextor_screenshot.validate_screenshot(path)

    def test_missing_prompt_is_rejected(self) -> None:
        complete = self.make_image()
        banner_hash, prompt_hash = self.expected_hashes(complete)
        path = self.make_image(prompt=False)
        with mock.patch.multiple(
            check_nextor_screenshot,
            BANNER_HASH=banner_hash,
            PROMPT_HASH=prompt_hash,
        ):
            with self.assertRaisesRegex(ValueError, "prompt"):
                check_nextor_screenshot.validate_screenshot(path)

    def test_wrong_banner_is_rejected(self) -> None:
        complete = self.make_image()
        banner_hash, prompt_hash = self.expected_hashes(complete)
        path = self.make_image(banner=False)
        with mock.patch.multiple(
            check_nextor_screenshot,
            BANNER_HASH=banner_hash,
            PROMPT_HASH=prompt_hash,
        ):
            with self.assertRaisesRegex(ValueError, "banner"):
                check_nextor_screenshot.validate_screenshot(path)


if __name__ == "__main__":
    unittest.main()
