#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS CHGCLR color behavior."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "BOOT": "01,0F,01,01",
    "S0": "51,51",
    "S1": "04,51,51",
    "S2": "04,04",
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
    print(f"validated M2 color behavior: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
