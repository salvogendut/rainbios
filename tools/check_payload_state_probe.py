#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the payload-launch register and work-area state."""

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
        "PC": "4010",
        "SP": "F380",
        "BC": "0000",
        "DE": "0000",
        "HL": "0000",
        "IX": "0000",
        "IY": "0000",
        "SLOT": "FC",
        "JIFFY": "XXXX,1",
    }
    for key, want in expected.items():
        found = values.get(key)
        if key == "JIFFY":
            if not found or not found.endswith(",1"):
                raise ValueError(f"{key}: expected an advancing JIFFY, found {found!r}")
            continue
        if found != want:
            raise ValueError(f"{key}: found {found!r}, expected {want!r}")
    if "AF" not in values or not values["AF"].startswith("00,"):
        raise ValueError(f"AF: expected a zeroed A, found {values.get('AF')!r}")
    buf = values.get("BUF", "")
    if not buf:
        raise ValueError("BUF: missing keyboard-buffer pointer check")
    putpnt, getpnt = buf.split(",")
    if putpnt != getpnt:
        raise ValueError(f"BUF: buffer not empty at launch (PUTPNT={putpnt}, GETPNT={getpnt})")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated payload launch state: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
