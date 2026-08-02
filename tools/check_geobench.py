#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate GeoBench's Screen 7 runtime state and rendered output."""

from __future__ import annotations

import argparse
import pathlib

from PIL import Image


EXPECTED_MAPPER = (0x03, 0x02, 0x01, 0x00)


def pixels(image: Image.Image):
    data = image.tobytes()
    return zip(data[0::3], data[1::3], data[2::3])


def parse_report(text: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        fields[key.strip().upper()] = value.strip()
    return fields


def validate_state(fields: dict[str, str]) -> None:
    try:
        vdp_r0 = int(fields["VDP_R0"], 16)
        vdp_r1 = int(fields["VDP_R1"], 16)
        scrmod = int(fields["SCRMOD"], 16)
        mapper = tuple(int(value, 16) for value in fields["MAPPER"].split(","))
    except (KeyError, ValueError) as error:
        raise ValueError("GeoBench report is missing valid runtime fields") from error

    if vdp_r0 != 0x0A or vdp_r1 != 0x62:
        raise ValueError(
            f"GeoBench is not in active Screen 7 state: R0={vdp_r0:02X}, "
            f"R1={vdp_r1:02X}"
        )
    if scrmod != 7:
        raise ValueError(f"GeoBench did not publish Screen 7: SCRMOD={scrmod:02X}")
    normalized_mapper = tuple(value & 0x1F for value in mapper)
    if normalized_mapper != EXPECTED_MAPPER:
        rendered = ",".join(f"{value:02X}" for value in mapper)
        raise ValueError(
            f"unexpected mapper state {rendered}; expected 03,02,01,00"
        )


def validate_application_state(fields: dict[str, str]) -> None:
    try:
        pc = int(fields["PC"], 16)
        mapper = tuple(int(value, 16) for value in fields["MAPPER"].split(","))
        app_pages = tuple(
            int(value, 16) for value in fields["APP_PAGES"].split(",")
        )
    except (KeyError, ValueError) as error:
        raise ValueError("GeoBench report is missing application state") from error

    if not 0 <= pc <= 0xFFFF:
        raise ValueError(f"GeoBench report has an invalid PC: {pc:X}")
    if len(mapper) != 4 or len(app_pages) != 8:
        raise ValueError("GeoBench report has invalid mapper application state")
    if (mapper[1] & 0x1F) != app_pages[0]:
        raise ValueError(
            "GeoBench desktop segment is not mapped in page 1: "
            f"mapper={mapper[1]:02X}, desktop={app_pages[0]:02X}"
        )


def load_screenshot(path: pathlib.Path) -> Image.Image:
    with Image.open(path) as source:
        image = source.convert("RGB")
    if image.size not in ((320, 240), (640, 480)):
        raise ValueError(f"unexpected GeoBench screenshot size: {image.size}")
    if image.size == (640, 480):
        image = image.resize((320, 240), Image.Resampling.NEAREST)
    return image


def validate_active_screen(path: pathlib.Path) -> None:
    image = load_screenshot(path)
    colors = image.getcolors(maxcolors=image.width * image.height)
    if colors is None or len(colors) < 4:
        count = "over limit" if colors is None else str(len(colors))
        raise ValueError(f"GeoBench screen has an invalid palette ({count} colors)")

    dominant_count, dominant = max(colors)
    if dominant_count < image.width * image.height // 2:
        raise ValueError("GeoBench screen lacks its dominant background plane")
    if dominant[2] < dominant[0] + 40 or dominant[2] < dominant[1] + 20:
        raise ValueError(f"GeoBench screen background is not blue: {dominant!r}")

    red_pixels = 0
    bright_pixels = 0
    for red, green, blue in pixels(image):
        if red >= 120 and red >= green * 3 // 2 and red >= blue * 3 // 2:
            red_pixels += 1
        if min(red, green, blue) >= 180:
            bright_pixels += 1
    if red_pixels < 10 or bright_pixels < 10:
        raise ValueError("GeoBench Screen 7 output lacks its active UI colours")


def validate_screenshot(path: pathlib.Path) -> None:
    image = load_screenshot(path)

    colors = image.getcolors(maxcolors=image.width * image.height)
    if colors is None or len(colors) < 4:
        count = "over limit" if colors is None else str(len(colors))
        raise ValueError(f"GeoBench desktop has an invalid palette ({count} colors)")

    dominant_count, dominant = max(colors)
    if dominant_count < image.width * image.height // 2:
        raise ValueError("GeoBench desktop lacks its dominant background plane")
    if dominant[2] < dominant[0] + 40 or dominant[2] < dominant[1] + 20:
        raise ValueError(f"GeoBench desktop background is not blue: {dominant!r}")

    top_bar = image.crop((13, 14, 307, 23))
    bright_bar_pixels = sum(
        1 for red, green, blue in pixels(top_bar) if min(red, green, blue) >= 180
    )
    if bright_bar_pixels < int(top_bar.width * top_bar.height * 0.70):
        raise ValueError("GeoBench desktop top status bar is missing")

    red_pixels = sum(
        1
        for red, green, blue in pixels(image)
        if red >= 120 and red >= green * 3 // 2 and red >= blue * 3 // 2
    )
    if red_pixels < 10:
        raise ValueError("GeoBench desktop icons and pointer are missing")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--boot-state",
        action="store_true",
        help="accept active GeoBench application output without desktop geometry",
    )
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("screenshot", type=pathlib.Path)
    arguments = parser.parse_args()

    try:
        fields = parse_report(arguments.report.read_text(encoding="utf-8"))
        validate_state(fields)
        if arguments.boot_state:
            validate_application_state(fields)
            validate_active_screen(arguments.screenshot)
        else:
            validate_screenshot(arguments.screenshot)
    except (OSError, ValueError) as error:
        raise SystemExit(f"invalid GeoBench integration result: {error}") from error

    result = "boot state" if arguments.boot_state else "desktop"
    print(
        f"validated GeoBench Screen 7 {result}: "
        f"R0={fields['VDP_R0']}, R1={fields['VDP_R1']}, "
        f"mapper={fields['MAPPER']}, screenshot={arguments.screenshot}"
    )


if __name__ == "__main__":
    main()
