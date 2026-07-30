#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS interrupt, VDP, mode, and console services."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "WRTVDP": "E2,E2",
    "INITXT": "00,F0,0000,0800,20,20,20,20,20,20,20,20,38",
    "CHPUT": "41,03,03",
    "SCROLL": "42,20,05,18",
    "CLS": "20,01,01",
    "INITGRP": "02,E0,00,01,02,03,04,05,06,07,00,00,F1,F1,D0",
}


def validate_report(text: str) -> dict[str, str]:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    for key, expected in EXPECTED.items():
        if values.get(key) != expected:
            raise ValueError(
                f"{key}: found {values.get(key)!r}, expected {expected!r}"
            )
    try:
        start_text, end_text, hook_text, map_text = values["INTERRUPT"].split(",")
        start = int(start_text, 16)
        end = int(end_text, 16)
        hook_count = int(hook_text, 16)
    except (KeyError, ValueError) as error:
        raise ValueError("missing or invalid INTERRUPT report") from error
    elapsed = (end - start) & 0xFFFF
    if not 20 <= elapsed <= 40:
        raise ValueError(f"JIFFY advanced by {elapsed}, expected 20..40")
    if not 20 <= hook_count <= 40:
        raise ValueError(f"H.TIMI ran {hook_count} times, expected 20..40")
    if map_text != "F0":
        raise ValueError(f"interrupt hook left primary map {map_text}, expected F0")
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated M1F interrupt/video services: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
