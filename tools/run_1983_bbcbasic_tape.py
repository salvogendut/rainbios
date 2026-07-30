#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run the BBC BASIC cassette LOAD/RUN integration probe in 1983."""

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
        vram_nonzero = int(fields["vram_nonzero"])
    except (KeyError, ValueError) as error:
        raise ValueError("1983 emitted an invalid BBC BASIC tape state") from error
    if pc != 0x4400:
        raise ValueError(
            f"cassette program stopped at {pc:04X}, expected success at 4400"
        )
    expected = {"slot": "F8", "vdp_r0": "00", "vdp_r1": "F0"}
    for key, value in expected.items():
        if fields.get(key) != value:
            raise ValueError(
                f"{key}: found {fields.get(key)!r}, expected {value!r}"
            )
    if vram_nonzero <= 0:
        raise ValueError("1983 reported blank VRAM")
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--cartridge", type=pathlib.Path, required=True)
    parser.add_argument("--input-cartridge", type=pathlib.Path, required=True)
    parser.add_argument("--cassette", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    parser.add_argument("--exit-after", type=int, default=1800)
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
        "--cart2",
        str(arguments.input_cartridge),
        "--mapper2",
        "linear",
        "--cassette",
        str(arguments.cassette),
        "--headless",
        "--unthrottled",
        "--exit-after",
        str(arguments.exit_after),
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
        print(f"error: invalid 1983 BBC BASIC tape state: {error}", file=sys.stderr)
        return 1
    print(
        "validated BBC BASIC cassette LOAD/RUN in 1983: "
        f"PC={fields['pc']}, slot={fields['slot']}, "
        f"VRAM nonzero={fields['vram_nonzero']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
