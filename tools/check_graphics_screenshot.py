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
    chromatic = {
        colour: count
        for colour, count in colours.items()
        if max(colour) - min(colour) >= 20 and max(colour) >= 80
    }
    substantial = {
        colour: count for colour, count in chromatic.items() if count >= 200
    }
    if len(substantial) < 3:
        raise ValueError(
            "graphics screenshot lacks the three coloured geometry strokes"
        )
    points = [
        (x, y)
        for y in range(image.height)
        for x in range(image.width)
        if image.getpixel((x, y)) in substantial
    ]
    left = min(x for x, _ in points)
    top = min(y for _, y in points)
    right = max(x for x, _ in points)
    bottom = max(y for _, y in points)
    if not (
        235 <= left <= 260
        and 385 <= right <= 405
        and 180 <= top <= 200
        and 275 <= bottom <= 300
    ):
        raise ValueError(
            "coloured geometry is outside its expected rectangle: "
            f"{left},{top}..{right},{bottom}"
        )


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
