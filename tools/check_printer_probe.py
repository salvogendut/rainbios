#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS printer calls (LPTOUT/LPTSTT)."""

from __future__ import annotations

import argparse
import pathlib


def validate_report(text: str) -> None:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    expected = {
        "NOPRINTER": "00,1",   # no printer: A=00, Z set (busy)
        "READY": "FF,0",       # printer attached: A=FF, Z clear (ready)
        "WRITE1": "0",         # LPTOUT 'A': carry clear
        "WRITE2": "0",         # LPTOUT 'B': carry clear
        "LPTPOS": "00",        # printer position untouched (no break)
    }
    for key, want in expected.items():
        if values.get(key) != want:
            raise ValueError(f"{key}: found {values.get(key)!r}, expected {want!r}")


def validate_log(log: str) -> None:
    if log != "AB":
        raise ValueError(f"printer log: expected 'AB', found {log!r}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--log", type=pathlib.Path, required=True)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
        validate_log(arguments.log.read_bytes().decode("ascii", "replace"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated printer calls: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
