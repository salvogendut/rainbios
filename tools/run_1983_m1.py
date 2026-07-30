#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run 1983 and require the RainBIOS M1 RAM/stack state."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


STATE_RE = re.compile(r"^state (?P<fields>.+)$", re.MULTILINE)


def parse_state(text: str) -> dict[str, str]:
    match = STATE_RE.search(text)
    if not match:
        raise ValueError("1983 did not emit a state line")
    fields = {}
    for field in match.group("fields").split():
        key, separator, value = field.rstrip(",").partition("=")
        if separator:
            fields[key] = value
    return fields


def validate_state(text: str) -> dict[str, str]:
    fields = parse_state(text)
    expected = {"sp": "F380", "slot": "F0"}
    for key, expected_value in expected.items():
        if fields.get(key) != expected_value:
            raise ValueError(
                f"{key}: found {fields.get(key)!r}, expected {expected_value!r}"
            )
    if int(fields.get("vram_nonzero", "0")) <= 0:
        raise ValueError("1983 reported blank VRAM")
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    arguments = parser.parse_args()
    command = [
        arguments.emulator,
        "--config",
        "/dev/null",
        "--models",
        str(arguments.models),
        "--model",
        "msx1",
        "--region",
        "ntsc",
        "--bios",
        str(arguments.bios),
        "--headless",
        "--unthrottled",
        "--exit-after",
        "120",
        "--dump-state",
        "--screenshot",
        str(arguments.screenshot),
    ]
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    sys.stdout.write(result.stdout)
    if result.returncode:
        return result.returncode
    try:
        fields = validate_state(result.stdout)
    except ValueError as error:
        print(f"error: invalid 1983 M1 state: {error}", file=sys.stderr)
        return 1
    print(
        "validated 1983 M1 state: "
        f"SP={fields['sp']}, slot={fields['slot']}, "
        f"VRAM nonzero={fields['vram_nonzero']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
