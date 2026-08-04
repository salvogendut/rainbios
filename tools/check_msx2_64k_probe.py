#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the openMSX MSX2 64 KiB VRAM report."""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    arguments = parser.parse_args()

    fields: dict[str, str] = {}
    for line in arguments.report.read_text().splitlines():
        key, separator, value = line.partition("=")
        if separator:
            fields[key] = value

    errors: list[str] = []
    expected = {
        "SCRMOD": "08",
        "M_SC5": "05",
        "M_SC8": "08",
        "M_V0": "A0",
        "M_V1": "A2",
        "M_V2": "A4",
        "M_V3": "A6",
        "M_V4": "A8",
        "M_V5": "AA",
        "M_V6": "AC",
    }
    for key, value in expected.items():
        if fields.get(key) != value:
            errors.append(f"{key}: found {fields.get(key)!r}, expected {value!r}")
    # The direct debugger read of 0x8000 reflects the final SC8 write.
    if fields.get("VRAM_8000") != "AC":
        errors.append(
            f"VRAM_8000: found {fields.get('VRAM_8000')!r}, expected AC"
        )
    if errors:
        raise SystemExit("invalid MSX2 64 KiB VRAM report:\n  " +
                         "\n  ".join(errors))
    print(
        f"validated openMSX MSX2 64 KiB VRAM: "
        f"Screens 5/8, even-address 16-bit VRAM round trips "
        f"A0/A2/A4/A6/A8/AA/AC"
    )


if __name__ == "__main__":
    main()
