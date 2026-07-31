#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate a black-box external-cartridge run under openMSX."""

from __future__ import annotations

import argparse
import pathlib


def validate_report(
    text: str,
    *,
    expected_vdp_r0: int,
    expected_vdp_r1: int,
) -> dict[str, str]:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    try:
        pc = int(values["PC"], 16)
        sp = int(values["SP"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("missing or invalid cartridge state") from error
    if not 0x0000 <= pc < 0x10000:
        raise ValueError(f"PC {pc:04X} is outside the primary slot")
    if not 0xF300 <= sp <= 0xF380:
        raise ValueError(f"SP {sp:04X} is outside RainBIOS main RAM")
    expected = {
        "SLOT": "D4",
        "VDP_R0": f"{expected_vdp_r0:02X}",
        "VDP_R1": f"{expected_vdp_r1:02X}",
    }
    for key, value in expected.items():
        if values.get(key) != value:
            raise ValueError(
                f"{key}: found {values.get(key)!r}, expected {value!r}"
            )
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--vdp-r0", type=lambda value: int(value, 16), required=True)
    parser.add_argument("--vdp-r1", type=lambda value: int(value, 16), required=True)
    arguments = parser.parse_args()
    try:
        values = validate_report(
            arguments.report.read_text(encoding="utf-8"),
            expected_vdp_r0=arguments.vdp_r0,
            expected_vdp_r1=arguments.vdp_r1,
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(
        "validated openMSX external cartridge: "
        f"PC={values['PC']}, SP={values['SP']}, slot={values['SLOT']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
