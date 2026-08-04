#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the openMSX MSX2 SUB-ROM services report."""

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
        "VDP_R0": "0E",
        "M_SC5": "05",
        "M_SC6": "06",
        "M_SC7": "07",
        "M_SC8": "08",
        "M_VRAM": "5A",
        "M_PLTB": "00",
        "M_PLTC": "07",
    }
    for key, value in expected.items():
        if fields.get(key) != value:
            errors.append(f"{key}: found {fields.get(key)!r}, expected {value!r}")
    for key, low, high in (("M_NAM5", "00", "00"), ("M_PAT5", "00", "78"),
                           ("M_ATR5", "00", "76")):
        values = fields.get(key, "").split(",")
        if len(values) != 2 or values[0] != low or values[1] != high:
            errors.append(
                f"{key}: found {values!r}, expected {low},{high}"
            )
    if fields.get("VRAM_8000") != "5A":
        errors.append(
            f"VRAM_8000: found {fields.get('VRAM_8000')!r}, expected 5A"
        )
    try:
        palette = fields.get("PALETTE2", "")
        if not palette or not palette.strip():
            errors.append("missing PALETTE2 value")
    except ValueError:
        errors.append("invalid PALETTE2 value")
    if errors:
        raise SystemExit("invalid MSX2 SUB-ROM services report:\n  " +
                         "\n  ".join(errors))
    print(
        f"validated openMSX MSX2 SUB-ROM services: "
        f"SCRMOD=08, VDP R0=0E, Screens 5/6/7/8, "
        f"16-bit VRAM=5A, palette B=00 C=07"
    )


if __name__ == "__main__":
    main()
