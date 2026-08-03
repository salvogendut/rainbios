#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS sprite utility calls."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "BASES": "3800,1B00,0F",
    "GSPSIZ0": "08,0,E0",
    "GSPSIZ1": "20,1,E2",
    "CALPAT16": "3820",
    "CALPAT8": "3828",
    "CALATR7": "1B1C",
    "ATR0": "D1,00,00,0F,D1,00,1F,0F",
    "PAT": "00,00",
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
    print(f"validated M2 sprite utilities: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
