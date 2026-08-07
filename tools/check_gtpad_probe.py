#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS touch-panel GTPAD selectors."""

from __future__ import annotations

import argparse
import pathlib


def validate_report(text: str) -> None:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    expected = {
        "NODEVICE": "00",   # GTPAD(0) without a touchpad: no device
        "FETCH": "00",      # GTPAD(0) with a not-touched touchpad: no sense
        "PADX": "00",       # cached X untouched
        "PADY": "00",       # cached Y untouched
    }
    for key, want in expected.items():
        if values.get(key) != want:
            raise ValueError(f"{key}: found {values.get(key)!r}, expected {want!r}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated touch-panel GTPAD: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
