#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Require the expected Nextor banner and drive-A prompt in a screenshot."""

from __future__ import annotations

import argparse
import hashlib
import pathlib

from PIL import Image


BANNER_BOX = (48, 144, 360, 176)
PROMPT_BOX = (48, 192, 128, 208)
BANNER_HASH = (
    "a40ec341567fd2082d2809330d9d49c799892189606212092b2b9acfcb3d08c8"
)
PROMPT_HASH = (
    "a9fde67a440f0798471cc61d38cc292330558f7ade14907965940fad2f71f43c"
)


def region_mask_hash(
    image: Image.Image, box: tuple[int, int, int, int]
) -> str:
    background = image.getpixel((0, 0))
    region = image.crop(box)
    mask = bytes(
        region.getpixel((x, y)) != background
        for y in range(region.height)
        for x in range(region.width)
    )
    return hashlib.sha256(mask).hexdigest()


def validate_screenshot(path: pathlib.Path) -> None:
    with Image.open(path) as source:
        image = source.convert("RGB")
    if image.size != (640, 480):
        raise ValueError(f"unexpected screenshot size: {image.size}")
    if region_mask_hash(image, BANNER_BOX) != BANNER_HASH:
        raise ValueError("Nextor 2.12 banner is not rendered as expected")
    if region_mask_hash(image, PROMPT_BOX) != PROMPT_HASH:
        raise ValueError("Nextor drive-A prompt is not rendered as expected")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("screenshot", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_screenshot(arguments.screenshot)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated Nextor 2.12 banner and A:\\> prompt: {arguments.screenshot}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
