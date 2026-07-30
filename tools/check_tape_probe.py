#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS cassette input probe."""

from __future__ import annotations

import argparse
import pathlib


def validate_report(text: str) -> dict[str, str]:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    if values.get("MARKER") != "54,41,50,45":
        raise ValueError(f"unexpected tape marker: {values.get('MARKER')!r}")
    try:
        period = int(values["PERIOD"], 16)
        pc = int(values["PC"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("missing or invalid tape timing state") from error
    if not 2 <= period <= 64:
        raise ValueError(f"implausible measured tape period: {period}")
    if not 0x4000 <= pc < 0x8000:
        raise ValueError(f"tape probe PC is outside cartridge ROM: {pc:04X}")
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        values = validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(
        "validated RainBIOS cassette input: "
        f"period={values['PERIOD']}, PC={values['PC']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
