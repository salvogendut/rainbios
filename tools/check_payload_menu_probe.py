#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate descriptor discovery, menu state, and payload transfer."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "DISCOVERY": "01,4010,0",
    "MENU": "1,1",
    "LAUNCH": "F4,F380,00,0000,0000,0000,0000,0000",
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
    print(f"validated descriptor-driven BASIC launch: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
