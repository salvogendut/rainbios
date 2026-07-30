#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS M1C openMSX slot-call report."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "HELPER": "D3,A8,C9",
    "READHELPER": "D3,A8,46,7A,D3,A8,78,C9",
    "WRITEHELPER": "D3,A8,73,7A,D3,A8,C9",
    "RSLREG": "E4,2345,6789,ABCD,A5,E4",
    "WSLREG": "E4,1357,2468,9ABC,A4,E4",
    "ENASLT1": "F4,0",
    "ENASLT2": "E4,0",
    "ENASLT0": "E6,0",
    "ENASLT3": "64,0",
    "EXPANDED": "F0,1",
    "RDSLT0": "11,1234,F0,0",
    "RDSLT1": "22,5234,F0,0",
    "RDSLT2": "33,9234,F0,0",
    "RDSLT3": "44,D234,F0,0",
    "WRSLT0": "55,1234,55,F0,0",
    "WRSLT1": "66,5234,66,F0,0",
    "WRSLT2": "77,9234,77,F0,0",
    "WRSLT3": "88,D234,88,F0,0",
    "RDSLTEXP": "83,1234,F0,1",
    "WRSLTEXP": "55,1234,99,F0,1",
}


def validate_report(text: str) -> None:
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated M1C primary-slot calls: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
