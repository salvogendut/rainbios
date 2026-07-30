#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS M1 openMSX state report."""

from __future__ import annotations

import argparse
import pathlib


def validate_report(text: str, ram_slot: int) -> None:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value

    expected = {
        "SP": "F380",
        "SLOTS": f"0/0/{ram_slot}/{ram_slot}",
        "BOTTOM": "8000",
        "HIMEM": "F380",
        "BIOSSLT": "00",
        "EXPTBL": "00000000",
        "SLTTBL": "00000000",
        "HOOKS": "C9,C9,C9",
    }
    for key, expected_value in expected.items():
        if values.get(key) != expected_value:
            raise ValueError(
                f"{key}: found {values.get(key)!r}, expected {expected_value!r}"
            )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--ram-slot", type=int, choices=range(1, 4), required=True)
    arguments = parser.parse_args()
    try:
        validate_report(
            arguments.report.read_text(encoding="utf-8"),
            arguments.ram_slot,
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(
        f"validated M1 primary RAM slot {arguments.ram_slot}: "
        f"{arguments.report}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
