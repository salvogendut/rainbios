#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS VRAM transfer calls."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "ROUNDTRIP": "5A,5A",
    "READLOW": "11",
    "READWRAP": "11",
    "READMID": "22",
    "READTOP": "33",
    "FILL": "5A,5A,00",
    "LDIRMV": "61,62,63,64",
    "LDIRVM": "41,42,43,44",
    "VDPREG": "02,E0",
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
    print(f"validated M2 VRAM transfer calls: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
