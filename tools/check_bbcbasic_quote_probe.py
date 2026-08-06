#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate that the double-quote key reaches the BBC BASIC console."""

from __future__ import annotations

import argparse
import pathlib


def validate_report(text: str) -> None:
    required = (
        "BBC BASIC (Z80) Version 3.00+1",
    )
    for fragment in required:
        if fragment not in text:
            raise ValueError(f"missing BBC BASIC result: {fragment!r}")
    if '>"A' not in text and '>"a' not in text and '>"A"' not in text:
        raise ValueError("double-quote key did not reach the BBC BASIC console")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated BBC BASIC double-quote input: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
