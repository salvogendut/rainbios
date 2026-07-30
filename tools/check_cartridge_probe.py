#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS primary-slot cartridge boot report."""

from __future__ import annotations

import argparse
import pathlib


def validate_report(
    text: str,
    expected_slot: str = "F4",
    expected_exptbl: str | None = None,
    expected_slttbl: str | None = None,
) -> dict[str, str]:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    try:
        pc = int(values["PC"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("missing or invalid PC") from error
    if not 0x4000 <= pc < 0x8000:
        raise ValueError(f"PC {pc:04X} is outside cartridge page 1")
    expected = {
        "SLOT": expected_slot,
        "SIGNATURE": "52,41,49,4E,5E",
    }
    if expected_exptbl is not None:
        expected["EXPTBL"] = expected_exptbl
    if expected_slttbl is not None:
        expected["SLTTBL"] = expected_slttbl
    for key, expected_value in expected.items():
        if values.get(key) != expected_value:
            raise ValueError(
                f"{key}: found {values.get(key)!r}, expected {expected_value!r}"
            )
    try:
        sp = int(values["SP"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("missing or invalid SP") from error
    if not 0xF300 <= sp <= 0xF380:
        raise ValueError(f"SP {sp:04X} is outside RainBIOS main RAM")
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--expected-slot", default="F4")
    parser.add_argument("--expected-exptbl")
    parser.add_argument("--expected-slttbl")
    arguments = parser.parse_args()
    try:
        values = validate_report(
            arguments.report.read_text(encoding="utf-8"),
            arguments.expected_slot,
            arguments.expected_exptbl,
            arguments.expected_slttbl,
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(
        "validated cartridge boot: "
        f"PC={values['PC']}, SP={values['SP']}, slot={values['SLOT']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
