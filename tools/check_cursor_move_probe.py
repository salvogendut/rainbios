#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS text cursor movement calls."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "INITXT": "00,28,18",
    "RIGHTC": "05,06",
    "RIGHTEDGE": "05,28",
    "LEFTC": "05,04",
    "LEFTEDGE": "05,01",
    "UPC": "04,05",
    "UPEDGE": "01,05",
    "DOWNC": "06,05",
    "DOWNEDGE": "18,05",
    "TUPC": "01,01,20,58",
    "TDOWNC": "18,01,59,20",
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
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated M2 cursor movement: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
