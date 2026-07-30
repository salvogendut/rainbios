#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS M1 openMSX state report."""

from __future__ import annotations

import argparse
import pathlib


def validate_report(
    text: str,
    ram_slot: int,
    expanded_primary: int | list[int] | None = None,
    selector: int = 0,
    bios_slot: int = 0,
) -> None:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value

    expansion = [0, 0, 0, 0]
    selectors = [0, 0, 0, 0]
    expanded_primaries = (
        []
        if expanded_primary is None
        else [expanded_primary]
        if isinstance(expanded_primary, int)
        else expanded_primary
    )
    for primary in expanded_primaries:
        expansion[primary] = 0x80
    if expanded_primaries:
        selectors[expanded_primaries[-1]] = selector
    expansion_word = sum(value << (index * 8) for index, value in enumerate(expansion))
    selector_word = sum(value << (index * 8) for index, value in enumerate(selectors))

    expected = {
        "SP": "F380",
        "SLOTS": f"0/0/{ram_slot}/{ram_slot}",
        "BOTTOM": "8000",
        "HIMEM": "F380",
        "BIOSSLT": f"{bios_slot:02X}",
        "EXPTBL": f"{expansion_word:08X}",
        "SLTTBL": f"{selector_word:08X}",
        "HOOKS": "C9,C9,C9",
    }
    for key, expected_value in expected.items():
        if values.get(key) != expected_value:
            raise ValueError(
                f"{key}: found {values.get(key)!r}, expected {expected_value!r}"
            )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--ram-slot", type=int, choices=range(1, 4), required=True)
    parser.add_argument(
        "--expanded-primary", type=int, choices=range(4), action="append"
    )
    parser.add_argument("--selector", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--bios-slot", type=lambda value: int(value, 0), default=0)
    arguments = parser.parse_args()
    try:
        validate_report(
            arguments.report.read_text(encoding="utf-8"),
            arguments.ram_slot,
            arguments.expanded_primary,
            arguments.selector,
            arguments.bios_slot,
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(
        f"validated M1 primary RAM slot {arguments.ram_slot}: "
        f"{arguments.report}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
