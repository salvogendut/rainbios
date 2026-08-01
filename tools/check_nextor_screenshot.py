#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Require the expected Nextor banner and drive prompt in a screenshot."""

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
SD_BANNER_BOX = (48, 128, 360, 160)
SD_PROMPT_BOX = (48, 176, 128, 192)
SD_DUAL_BANNER_BOX = (48, 160, 360, 192)
SD_DUAL_PROMPT_BOX = (48, 208, 128, 224)
SD_STATUS_BOX = (48, 48, 448, 112)
SD_STATUS_HASHES = {
    "A": "ddcd8be8b0bbeb2fae164083eff1ba41c9372b3dfc6aa092098af4f9b23e65d6",
    "B": "95cd59f06260021b1207e4774c7c17d666e01b5fd5be620dccdcffe84f4df003",
}
SD_DUAL_STATUS_HASH = (
    "4f998d3538874660717a5c2fec12dc92d7ad13957214d0437bcc3035a09d0bff"
)
MIXED_STATUS_BOX = (48, 48, 592, 208)
MIXED_BANNER_BOX = (48, 224, 360, 256)
MIXED_PROMPT_BOX = (48, 272, 128, 288)
MIXED_STATUS_HASH = (
    "7fc58d9bff9e50a2d83f5837fbfcd0febdaf3160110e8e85aca62e1d0c14a26d"
)
MIXED_PROMPT_HASH = (
    "b1f3ba80db9add4f0611016330f7e009982f1b9f6ea9dd8bfd9baba62e332c8f"
)
SD_PROMPT_HASHES = {
    "A": PROMPT_HASH,
    "B": "db4ff0a871f84ed88ebef4bb3bf6a598cb71ed9a50222eab0f618563a1e1abb6",
}


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


def validate_sd_screenshot(
    path: pathlib.Path, card: str, *, dual: bool = False
) -> None:
    with Image.open(path) as source:
        image = source.convert("RGB")
    if image.size != (640, 480):
        raise ValueError(f"unexpected screenshot size: {image.size}")
    status_hash = SD_DUAL_STATUS_HASH if dual else SD_STATUS_HASHES[card]
    if region_mask_hash(image, SD_STATUS_BOX) != status_hash:
        raise ValueError(f"SD Mapper card-{card} status is not rendered as expected")
    banner_box = SD_DUAL_BANNER_BOX if dual else SD_BANNER_BOX
    prompt_box = SD_DUAL_PROMPT_BOX if dual else SD_PROMPT_BOX
    if region_mask_hash(image, banner_box) != BANNER_HASH:
        raise ValueError("Nextor 2.12 banner is not rendered as expected")
    if region_mask_hash(image, prompt_box) != SD_PROMPT_HASHES[card]:
        raise ValueError(f"Nextor drive-{card} prompt is not rendered as expected")


def validate_mixed_storage_screenshot(path: pathlib.Path) -> None:
    with Image.open(path) as source:
        image = source.convert("RGB")
    if image.size != (640, 480):
        raise ValueError(f"unexpected screenshot size: {image.size}")
    if region_mask_hash(image, MIXED_STATUS_BOX) != MIXED_STATUS_HASH:
        raise ValueError("mixed SD Mapper/Sunrise status is not rendered as expected")
    if region_mask_hash(image, MIXED_BANNER_BOX) != BANNER_HASH:
        raise ValueError("Nextor 2.12 banner is not rendered as expected")
    if region_mask_hash(image, MIXED_PROMPT_BOX) != MIXED_PROMPT_HASH:
        raise ValueError("Nextor drive-C prompt is not rendered as expected")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sd-card", choices=("A", "B"))
    parser.add_argument("--sd-dual", action="store_true")
    parser.add_argument("--mixed-storage", action="store_true")
    parser.add_argument("screenshot", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        if arguments.mixed_storage:
            validate_mixed_storage_screenshot(arguments.screenshot)
        elif arguments.sd_card:
            validate_sd_screenshot(
                arguments.screenshot,
                arguments.sd_card,
                dual=arguments.sd_dual,
            )
        else:
            validate_screenshot(arguments.screenshot)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    drive = "C" if arguments.mixed_storage else arguments.sd_card or "A"
    print(
        f"validated Nextor 2.12 banner and {drive}:\\> prompt: "
        f"{arguments.screenshot}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
