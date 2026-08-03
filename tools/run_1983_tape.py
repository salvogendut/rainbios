#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run the RainBIOS cassette byte probe in 1983."""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys

try:
    from tools.run_1983_m1 import parse_state
except ModuleNotFoundError:
    from run_1983_m1 import parse_state


def validate_state(text: str) -> dict[str, str]:
    fields = parse_state(text)
    try:
        pc = int(fields["pc"], 16)
        sp = int(fields["sp"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("1983 emitted an invalid PC or SP") from error
    if pc != 0x4400:
        raise ValueError(
            f"cassette probe stopped at {pc:04X}, expected success at 4400"
        )
    if not 0xF080 <= sp <= 0xF380:
        raise ValueError(f"SP {sp:04X} is outside RainBIOS page-3 stacks")
    if fields.get("slot") != "F4":
        raise ValueError(
            f"slot: found {fields.get('slot')!r}, expected 'F4'"
        )
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--cartridge", type=pathlib.Path, required=True)
    parser.add_argument("--cassette", type=pathlib.Path, required=True)
    parser.add_argument("--exit-after", type=int, default=600)
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
        "--cart",
        str(arguments.cartridge),
        "--mapper",
        "linear",
        "--cassette",
        str(arguments.cassette),
        "--headless",
        "--unthrottled",
        "--exit-after",
        str(arguments.exit_after),
        "--dump-state",
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
        print(f"error: invalid 1983 cassette state: {error}", file=sys.stderr)
        return 1
    print(
        "validated 1983 cassette input: "
        f"PC={fields['pc']}, SP={fields['sp']}, slot={fields['slot']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
