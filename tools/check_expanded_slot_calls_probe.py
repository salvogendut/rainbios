#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS expanded-slot openMSX report."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "INIT": "00,00,80,00/00,00,00,00/50/00",
    "RDSLT0": "11,1234,A1,50/00/0",
    "RDSLT1": "22,5234,A2,50/00/0",
    "RDSLT2": "33,9234,A3,50/00/0",
    "RDSLT3": "44,D234,A4,50/00/0",
    "WRSLT0": "51,1234,51,50/00/0",
    "WRSLT1": "62,5234,62,50/00/0",
    "WRSLT2": "73,9234,73,50/00/0",
    "WRSLT3": "84,D234,84,50/00/0",
    "ENASLT0": "52/01/01/0",
    "ENASLT1": "58/08/08/0",
    "ENASLT2": "60/30/30/0",
    "ENASLT3": "90/40/40/0",
    "CALSLT": "5A,1234,5678,9ABC,5000,8A00,08/54/40/40/1",
    "CALLF": "5A,1234,5678,9ABC,5000,8A00,08/54/40/40/1",
    "INVALID": "50/00/1",
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
    print(f"validated expanded-slot calls: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
