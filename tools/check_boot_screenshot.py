#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate that an emulator screenshot contains the expected rendered video."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("screenshot", type=Path)
    parser.add_argument(
        "--size",
        default="320x240",
        help="expected WIDTHxHEIGHT (default: 320x240)",
    )
    parser.add_argument(
        "--min-colors",
        type=int,
        default=10,
        help="minimum distinct RGB colors (default: 10)",
    )
    parser.add_argument(
        "--max-colors",
        type=int,
        help="optional maximum distinct RGB colors",
    )
    args = parser.parse_args()
    try:
        expected_size = tuple(int(value) for value in args.size.lower().split("x"))
    except ValueError as error:
        raise SystemExit(f"invalid --size value: {args.size}") from error
    if len(expected_size) != 2 or min(expected_size) <= 0:
        raise SystemExit(f"invalid --size value: {args.size}")

    with Image.open(args.screenshot) as image:
        rgb = image.convert("RGB")
        if rgb.size != expected_size:
            raise SystemExit(
                f"expected a {args.size} screenshot, got {rgb.width}x{rgb.height}"
            )
        colors = rgb.getcolors(maxcolors=rgb.width * rgb.height)
        if colors is None:
            raise SystemExit("screenshot contains too many colors to count")
        if len(colors) < args.min_colors:
            color_count = "over limit" if colors is None else str(len(colors))
            raise SystemExit(
                "screenshot does not contain enough rendered colors "
                f"({color_count}, expected at least {args.min_colors})"
            )
        if args.max_colors is not None and len(colors) > args.max_colors:
            raise SystemExit(
                "screenshot contains more rendered colors than expected "
                f"({len(colors)}, expected at most {args.max_colors})"
            )

    print(
        f"validated rendered screenshot ({len(colors)} colors): "
        f"{args.screenshot}"
    )


if __name__ == "__main__":
    main()
