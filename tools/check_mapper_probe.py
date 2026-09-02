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


def validate_report(text: str, expected_segments: str = "00") -> None:
    expected_values = {**EXPECTED, "MAPPER_SEGMENTS": expected_segments.upper()}
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    for key, expected in expected_values.items():
        if values.get(key) != expected:
            raise ValueError(
                f"{key}: found {values.get(key)!r}, expected {expected!r}"
            )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--segments",
        default="00",
        type=lambda value: f"{int(value, 16):02X}",
        help="expected hexadecimal segment count (00 represents 256)",
    )
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(
            arguments.report.read_text(encoding="utf-8"), arguments.segments
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    segments = int(arguments.segments, 16) or 256
    print(f"validated M1 memory-mapper sizing: {segments} segments "
          f"({segments * 16} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
