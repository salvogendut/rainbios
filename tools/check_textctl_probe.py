#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS CHPUT text control characters."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "TAB1": "02,09",
    "TAB2": "03,01",
    "UP1": "04,03",
    "UP2": "01,03",
    "FF": "01,01,20",
    "ESCX4": "00,00",
    "ESCK": "03,04,41,20,20",
    "DEL": "04,05,20",
    "LEFT": "05,05",
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
    print(f"validated M2 text control characters: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
