#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the openMSX MSX2 main-ROM boot report."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    parser.add_argument("screenshot", type=Path)
    arguments = parser.parse_args()

    fields: dict[str, str] = {}
    for line in arguments.report.read_text().splitlines():
        key, separator, value = line.partition("=")
        if separator:
            fields[key] = value

    errors: list[str] = []
    expected = {
        "IDBYT1": "21",
        "IDBYT2": "11",
        "VERSION": "01",
        "EXBRSA": "83",
        "RG8SAV": "08",
    }
    for key, value in expected.items():
        if fields.get(key) != value:
            errors.append(f"{key}: found {fields.get(key)!r}, expected {value!r}")
    if int(fields.get("VRAM_NONZERO", "0")) <= 0:
        errors.append("openMSX reported blank VRAM")
    vdp_regs = [int(value, 16) for value in fields.get("VDP_REGS", "").split(",")]
    if len(vdp_regs) >= 16:
        for index, expected_value in enumerate((8, 0, 0, 0, 0, 0, 0, 0)):
            if vdp_regs[8 + index] != expected_value:
                errors.append(
                    f"VDP R{8 + index}: found {vdp_regs[8 + index]:02X}, "
                    f"expected {expected_value:02X}"
                )
    else:
        errors.append(f"VDP_REGS too short: {len(vdp_regs)}")

    with Image.open(arguments.screenshot) as image:
        rgb = image.convert("RGB")
        if rgb.size != (640, 480):
            errors.append(
                f"expected 640x480 screenshot, got {rgb.width}x{rgb.height}"
            )
        colors = rgb.getcolors(maxcolors=rgb.width * rgb.height)
        if colors is None or len(colors) < 10:
            errors.append("screenshot lacks the rendered boot UI")

    if errors:
        raise SystemExit("invalid MSX2 boot report:\n  " + "\n  ".join(errors))
    print(
        f"validated openMSX MSX2 boot: version={fields['VERSION']}, "
        f"EXBRSA={fields['EXBRSA']}, RG8SAV={fields['RG8SAV']}"
    )


if __name__ == "__main__":
    main()
