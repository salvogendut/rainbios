#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate descriptor discovery, menu state, and payload transfer."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "DISCOVERY": "01,4010,0",
    "MENU": "1,1",
    "LAUNCH": "F4,F380,00,0000,0000,0000,0000,0000",
}


def validate_report(
    text: str,
    payload_slot: str = "01",
    selected_primary: int = 0,
    launch_slot: str = "F4",
) -> dict[str, str]:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    expected_values = dict(EXPECTED)
    expected_values["DISCOVERY"] = f"{payload_slot},4010,{selected_primary}"
    expected_values["LAUNCH"] = (
        f"{launch_slot},F380,00,0000,0000,0000,0000,0000"
    )
    for key, expected in expected_values.items():
        if values.get(key) != expected:
            raise ValueError(
                f"{key}: found {values.get(key)!r}, expected {expected!r}"
            )
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--payload-slot", default="01")
    parser.add_argument("--selected-primary", type=int, default=0)
    parser.add_argument("--launch-slot", default="F4")
    arguments = parser.parse_args()
    try:
        validate_report(
            arguments.report.read_text(encoding="utf-8"),
            arguments.payload_slot,
            arguments.selected_primary,
            arguments.launch_slot,
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated descriptor-driven BASIC launch: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
