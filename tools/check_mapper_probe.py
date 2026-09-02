#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS M1 memory-mapper sizing report."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "MAPPER_SEGMENTS": "00",
    "BASELINE_MAP": "F0",
    "SEG255": "7A",
    "SEG0": "5A",
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
    print(
        f"validated M1 memory-mapper sizing: "
        "256 segments (4096 KB)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
