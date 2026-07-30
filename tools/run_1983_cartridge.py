#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run 1983 and require execution inside the RainBIOS test cartridge."""

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
    if not 0x4000 <= pc < 0x8000:
        raise ValueError(f"PC {pc:04X} is outside cartridge page 1")
    if not 0xF300 <= sp <= 0xF380:
        raise ValueError(f"SP {sp:04X} is outside RainBIOS main RAM")
    if fields.get("slot") != "F4":
        raise ValueError(
            f"slot: found {fields.get('slot')!r}, expected 'F4'"
        )
    if int(fields.get("vram_nonzero", "0")) <= 0:
        raise ValueError("1983 reported blank VRAM")
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--cartridge", type=pathlib.Path, required=True)
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
        "--cart",
        str(arguments.cartridge),
        "--mapper",
        "linear",
        "--headless",
        "--unthrottled",
        "--exit-after",
        "180",
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
        print(f"error: invalid 1983 cartridge state: {error}", file=sys.stderr)
        return 1
    print(
        "validated 1983 primary cartridge boot: "
        f"PC={fields['pc']}, SP={fields['sp']}, slot={fields['slot']}, "
        f"VRAM nonzero={fields['vram_nonzero']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
