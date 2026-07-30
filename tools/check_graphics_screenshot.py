#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Check that a 1983 screenshot visibly contains the graphics test pattern."""

from __future__ import annotations

import argparse
import collections
import pathlib

from PIL import Image


def validate_screenshot(path: pathlib.Path) -> None:
    with Image.open(path) as source:
        image = source.convert("RGB")
    if image.size != (640, 480):
        raise ValueError(f"unexpected screenshot dimensions: {image.size}")
    colours = collections.Counter(image.get_flattened_data())
    visible = sum(
        count for colour, count in colours.items() if max(colour) >= 80
    )
    if len(colours) < 4:
        raise ValueError(f"graphics screenshot has only {len(colours)} colours")
    if visible < 1_000:
        raise ValueError(f"graphics screenshot has only {visible} visible pixels")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("screenshot", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_screenshot(arguments.screenshot)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated rendered BBC BASIC graphics: {arguments.screenshot}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
