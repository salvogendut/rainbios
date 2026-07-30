#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate BBC BASIC language and console behavior under RainBIOS."""

from __future__ import annotations

import argparse
import pathlib
import re


def validate_report(text: str) -> None:
    required = (
        "ROM_WRITES=0",
        "BBC BASIC (Z80) Version 3.00+1",
        ">PRINT 2+2",
        "1.41421356",
        "RAINBIOS",
        ">RUN",
        "Storage unsupported",
        ">PRINT TIME>=1000",
        ">PRINT INKEY(1)",
    )
    for fragment in required:
        if fragment not in text:
            raise ValueError(f"missing BBC BASIC result: {fragment!r}")
    patterns = (
        (r"(?m)^\s+4\s*$", "edited integer expression"),
        (r"\n\s+1\s+2\s+3>", "FOR/NEXT program output"),
    )
    for pattern, description in patterns:
        if not re.search(pattern, text):
            raise ValueError(f"missing BBC BASIC result: {description}")
    if len(re.findall(r"(?m)^\s+-1\s*$", text)) < 2:
        raise ValueError("missing TIME assignment or INKEY timeout result")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated BBC BASIC under RainBIOS: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
