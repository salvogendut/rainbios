#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS buffered keyboard services."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "INIT": "FBF0,FBF0,FF,FF",
    "EMPTY": "1,FBF0,FBF0",
    "MATRIX": "FB,FB,FB,FBF1",
    "READY": "1,FBF1",
    "CHAR": "41,1234,5678,9ABC",
    "DRAINED": "1,FBF1,FBF1",
    "KILLED": "1,FBF0,FBF0",
    "BLOCKING": "0D",
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
    print(f"validated M3 keyboard services: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
