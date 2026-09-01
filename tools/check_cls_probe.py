#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate that CLS clears every screen mode and homes the cursor.

The cls probe cartridge dirties the Screen 0 name table and the Screen 2
pattern/colour planes, calls CLS after each, and records the resulting VRAM
bytes and cursor for this checker. Screen 0 must end as spaces; Screen 2 must
end with an empty pattern plane and a uniform background-colour plane.
"""

from __future__ import annotations

import argparse
import pathlib


def validate_report(text: str) -> dict[str, int]:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if not separator:
            continue
        values[key] = int(value)
    required = (
        "SCREEN0_NAME",
        "SCREEN0_CSRX",
        "SCREEN0_CSRY",
        "SCREEN2_PATTERN",
        "SCREEN2_COLOUR",
        "SCREEN2_CSRX",
        "SCREEN2_CSRY",
        "BAKCLR",
        "BASIC",
    )
    for key in required:
        if key not in values:
            raise ValueError(f"missing CLS probe key {key}")
    if values["SCREEN0_NAME"] != 0x20:
        raise ValueError(
            f"Screen 0 name table byte after CLS is {values['SCREEN0_NAME']:02X}, expected 20"
        )
    if values["SCREEN0_CSRX"] != 1 or values["SCREEN0_CSRY"] != 1:
        raise ValueError(
            "Screen 0 cursor after CLS is "
            f"({values['SCREEN0_CSRX']},{values['SCREEN0_CSRY']}), expected (1,1)"
        )
    if values["SCREEN2_PATTERN"] != 0:
        raise ValueError(
            f"Screen 2 pattern byte after CLS is {values['SCREEN2_PATTERN']:02X}, expected 0"
        )
    if values["SCREEN2_COLOUR"] != values["BAKCLR"]:
        raise ValueError(
            "Screen 2 colour byte after CLS is "
            f"{values['SCREEN2_COLOUR']:02X}, expected background {values['BAKCLR']:02X}"
        )
    if values["SCREEN2_CSRX"] != 1 or values["SCREEN2_CSRY"] != 1:
        raise ValueError(
            "Screen 2 cursor after CLS is "
            f"({values['SCREEN2_CSRX']},{values['SCREEN2_CSRY']}), expected (1,1)"
        )
    if values["BASIC"] != 1:
        raise ValueError("returning cartridge INIT did not fall through to BASIC")
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated CLS screen clearing: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
