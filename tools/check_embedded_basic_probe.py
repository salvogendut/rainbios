#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the openMSX internal BASIC payload report."""

from __future__ import annotations

import argparse
import pathlib
import re


def validate_report(text: str) -> None:
    required = (
        "ROM_WRITES=0",
        "SLOT=F0",
        "HEADER=41,42",
        "DESCRIPTOR=52,42,50,31",
        "BBC BASIC (Z80) Version 3.00+1",
        ">PRINT 2+2",
    )
    for fragment in required:
        if fragment not in text:
            raise ValueError(f"missing embedded-payload result: {fragment!r}")
    if not re.search(r"\n\s+4\s*$", text, flags=re.MULTILINE):
        raise ValueError("missing PRINT 2+2 result")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated openMSX embedded BASIC payload: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
