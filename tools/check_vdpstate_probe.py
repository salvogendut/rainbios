#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the TMS9918-compatible VDP state initialization."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "BOOT": "02,E0,06,FF,03,36,07,01,02,E0,06,FF,03,36,07,01,1800,0000,3800,1B00,02,20",
    "DISSCR": "A0,A0",
    "ENASCR": "E0,E0",
    "WRTVDP": "08,08",
    "INITXT": "00,F0,00,00,01,36,07,F1,00,F0,00,00,01,36,07,F1,0000,0800,0000,0000,00,28",
    "INIT32": "00,E0,06,80,00,36,07,F1,00,E0,06,80,00,36,07,F1,1800,0000,3800,1B00,01,20",
    "INITGRP": "02,E0,06,FF,03,36,07,01,02,E0,06,FF,03,36,07,01,1800,0000,3800,1B00,02,20",
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
    print(f"validated M2 TMS9918 VDP state: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
