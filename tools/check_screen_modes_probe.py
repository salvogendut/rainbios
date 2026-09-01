#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS screen-mode switch calls."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "INITXT": "00,F0,00,00,01,36,07,B4,00,28",
    "INIT32": "00,E0,06,80,00,36,07,F5,01,20",
    "INITGRP": "02,E0,06,FF,03,36,07,01,02,20",
    "SETTXT": "00,F0,00,00,01,36,07,B4,00,28,55,01,01",
    "SETT32": "00,E0,06,80,00,36,07,F5,01,20",
    "SETGRP": "02,E0,06,FF,03,36,07,01,02,20",
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
    print(f"validated M2 screen-mode switches: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
