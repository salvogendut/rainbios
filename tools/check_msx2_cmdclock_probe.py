#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the openMSX MSX2 SUB-ROM command/clock report."""

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
        "SCRMOD": "05",
        "M_BLTMV_NX": "08",
        "M_BLTMV_P0": "04",
        "M_BLTMV_P1": "03",
        "M_BLTMV_P2": "02",
        "M_RTC": "0A",
    }
    for key, value in expected.items():
        if fields.get(key) != value:
            errors.append(f"{key}: found {fields.get(key)!r}, expected {value!r}")
    for key, values in (("M_BLTVV", ("04", "03", "02", "01")),
                        ("M_BLTVM", ("33", "33", "33", "33"))):
        found = fields.get(key, "").split(",")
        if found != list(values):
            errors.append(f"{key}: found {found!r}, expected {list(values)!r}")
    if errors:
        raise SystemExit("invalid MSX2 SUB-ROM command/clock report:\n  " +
                         "\n  ".join(errors))
    print(
        f"validated openMSX MSX2 SUB-ROM command/clock: "
        f"BLTVV 04030201, BLTVM 33333333, BLTMV NX=08 pixels=040302, "
        f"RTC round trip=0A"
    )


if __name__ == "__main__":
    main()
