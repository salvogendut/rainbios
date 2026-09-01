#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run the source-embedded BASIC payload under RainBIOS in 1983."""

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
        vram_nonzero = int(fields["vram_nonzero"])
    except (KeyError, ValueError) as error:
        raise ValueError("1983 emitted an invalid embedded BASIC state") from error
    if not 0x0000 <= pc < 0x4000:
        raise ValueError(f"PC {pc:04X} is outside RainBIOS page-0 services")
    if not 0xF200 <= sp <= 0xF300:
        raise ValueError(f"SP {sp:04X} is outside the BASIC stack window")
    expected = {"slot": "FC", "vdp_r0": "00", "vdp_r1": "F0"}
    for key, value in expected.items():
        if fields.get(key) != value:
            raise ValueError(f"{key}: found {fields.get(key)!r}, expected {value!r}")
    if vram_nonzero <= 0:
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
        print(f"error: invalid 1983 embedded BASIC state: {error}", file=sys.stderr)
        return 1
    print(
        "validated immediate 1983 embedded BASIC state: "
        f"PC={fields['pc']}, SP={fields['sp']}, slot={fields['slot']}, "
        f"VRAM nonzero={fields['vram_nonzero']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
