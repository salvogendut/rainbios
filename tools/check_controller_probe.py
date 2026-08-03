#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate RainBIOS keyboard, joystick, trigger, and mouse BIOS services."""

from __future__ import annotations

import argparse
import pathlib


EXPECTED = {
    "STICK_KEYS": "00,01,02,03,04,05,06,07,08",
    "TRIGGER_KEY": "FF,1234,5678,9ABC",
    "STICK_PORTS": "01,00,00",
    "TRIGGER_PORTS": "00,00",
    "MOUSE_EMPTY": "FF,01,01",
    "MOUSE_IDLE": "FF,00,00,FF,00,00",
    "MOUSE_BUTTON": "00,30",
    "PADDLE": "00,00,00",
    "PSG_INIT": "B8,8F",
    "PSG_PORT_B": "AF,DF,CF",
}


def validate_report(text: str) -> dict[str, str]:
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
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated M3 controller services: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
