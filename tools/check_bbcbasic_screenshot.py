#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Require a rendered BBC BASIC banner and prompt in a 1983 screenshot."""

from __future__ import annotations

import argparse
import pathlib

from PIL import Image


def region_has_foreground(image: Image.Image, box: tuple[int, int, int, int]) -> bool:
    colors = image.crop(box).convert("RGB").getcolors()
    return colors is not None and len(colors) >= 2


def validate_screenshot(path: pathlib.Path) -> None:
    with Image.open(path) as source:
        image = source.convert("RGB")
    if image.size != (640, 480):
        raise ValueError(f"unexpected screenshot size: {image.size}")
    colors = image.getcolors(maxcolors=image.width * image.height)
    if colors is None or len(colors) < 2:
        raise ValueError("BBC BASIC screenshot is blank")
    if not region_has_foreground(image, (40, 380, 610, 416)):
        raise ValueError("BBC BASIC banner is not visibly rendered")
    if not region_has_foreground(image, (40, 396, 60, 414)):
        raise ValueError("BBC BASIC prompt is not visibly rendered")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("screenshot", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_screenshot(arguments.screenshot)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated 1983 BBC BASIC banner and prompt: {arguments.screenshot}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
