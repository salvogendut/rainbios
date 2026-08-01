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

    def make_sd_image(
        self,
        *,
        status: bool = True,
        banner: bool = True,
        prompt: bool = True,
        dual: bool = False,
    ) -> pathlib.Path:
        temporary = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
        temporary.close()
        path = pathlib.Path(temporary.name)
        image = Image.new("RGB", (640, 480), "black")
        drawing = ImageDraw.Draw(image)
        if status:
            drawing.rectangle((52, 52, 400, 106), fill="white")
        offset = 32 if dual else 0
        if banner:
            drawing.rectangle((52, 132 + offset, 300, 154 + offset), fill="white")
        if prompt:
            drawing.rectangle((52, 180 + offset, 100, 186 + offset), fill="white")
        image.save(path)
        self.addCleanup(path.unlink)
        return path

    def make_mixed_storage_image(self) -> pathlib.Path:
        temporary = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
        temporary.close()
        path = pathlib.Path(temporary.name)
        image = Image.new("RGB", (640, 480), "black")
        drawing = ImageDraw.Draw(image)
        drawing.rectangle((52, 52, 540, 202), fill="white")
        drawing.rectangle((52, 228, 300, 250), fill="white")
        drawing.rectangle((52, 276, 100, 282), fill="white")
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

    def expected_sd_hashes(
        self, path: pathlib.Path, *, dual: bool = False
    ) -> tuple[str, str, str]:
        with Image.open(path) as source:
            image = source.convert("RGB")
        return (
            check_nextor_screenshot.region_mask_hash(
                image, check_nextor_screenshot.SD_STATUS_BOX
            ),
            check_nextor_screenshot.region_mask_hash(
                image,
                check_nextor_screenshot.SD_DUAL_BANNER_BOX
                if dual
                else check_nextor_screenshot.SD_BANNER_BOX,
            ),
            check_nextor_screenshot.region_mask_hash(
                image,
                check_nextor_screenshot.SD_DUAL_PROMPT_BOX
                if dual
                else check_nextor_screenshot.SD_PROMPT_BOX,
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

    def test_sd_card_profile_is_accepted(self) -> None:
        path = self.make_sd_image()
        status_hash, banner_hash, prompt_hash = self.expected_sd_hashes(path)
        with mock.patch.multiple(
            check_nextor_screenshot,
            BANNER_HASH=banner_hash,
            SD_STATUS_HASHES={"A": status_hash},
            SD_PROMPT_HASHES={"A": prompt_hash},
        ):
            check_nextor_screenshot.validate_sd_screenshot(path, "A")

    def test_wrong_sd_card_status_is_rejected(self) -> None:
        complete = self.make_sd_image()
        _, banner_hash, prompt_hash = self.expected_sd_hashes(complete)
        path = self.make_sd_image(status=False)
        with mock.patch.multiple(
            check_nextor_screenshot,
            BANNER_HASH=banner_hash,
            SD_STATUS_HASHES={"B": "wrong"},
            SD_PROMPT_HASHES={"B": prompt_hash},
        ):
            with self.assertRaisesRegex(ValueError, "card-B status"):
                check_nextor_screenshot.validate_sd_screenshot(path, "B")

    def test_dual_sd_card_selection_is_accepted(self) -> None:
        path = self.make_sd_image(dual=True)
        status_hash, banner_hash, prompt_hash = self.expected_sd_hashes(
            path, dual=True
        )
        with mock.patch.multiple(
            check_nextor_screenshot,
            BANNER_HASH=banner_hash,
            SD_DUAL_STATUS_HASH=status_hash,
            SD_PROMPT_HASHES={"B": prompt_hash},
        ):
            check_nextor_screenshot.validate_sd_screenshot(path, "B", dual=True)

    def test_mixed_storage_profile_is_accepted(self) -> None:
        path = self.make_mixed_storage_image()
        with Image.open(path) as source:
            image = source.convert("RGB")
        status_hash = check_nextor_screenshot.region_mask_hash(
            image, check_nextor_screenshot.MIXED_STATUS_BOX
        )
        banner_hash = check_nextor_screenshot.region_mask_hash(
            image, check_nextor_screenshot.MIXED_BANNER_BOX
        )
        prompt_hash = check_nextor_screenshot.region_mask_hash(
            image, check_nextor_screenshot.MIXED_PROMPT_BOX
        )
        with mock.patch.multiple(
            check_nextor_screenshot,
            BANNER_HASH=banner_hash,
            MIXED_STATUS_HASH=status_hash,
            MIXED_PROMPT_HASH=prompt_hash,
        ):
            check_nextor_screenshot.validate_mixed_storage_screenshot(path)


if __name__ == "__main__":
    unittest.main()
