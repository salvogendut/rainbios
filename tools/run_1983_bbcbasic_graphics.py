#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run the BBC BASIC graphics program under RainBIOS in 1983."""

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
        raise ValueError("1983 emitted an invalid graphics state") from error
    if not (0x0200 <= pc < 0x1000 or 0x4000 <= pc < 0x8000):
        raise ValueError(f"PC {pc:04X} is outside RainBIOS/BBC BASIC code")
    if not 0xF100 <= sp <= 0xF300:
        raise ValueError(f"SP {sp:04X} is outside the BBC BASIC stack window")
    expected = {"slot": "F4", "vdp_r0": "02", "vdp_r1": "E0"}
    for key, value in expected.items():
        if fields.get(key) != value:
            raise ValueError(
                f"{key}: found {fields.get(key)!r}, expected {value!r}"
            )
    if vram_nonzero < 1_000:
        raise ValueError(
            f"1983 reported only {vram_nonzero} nonzero VRAM bytes"
        )
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--cartridge", type=pathlib.Path, required=True)
    parser.add_argument("--input-cartridge", type=pathlib.Path, required=True)
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
        "--cart2",
        str(arguments.input_cartridge),
        "--mapper2",
        "linear",
        "--headless",
        "--unthrottled",
        "--exit-after",
        "7200",
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
        print(f"error: invalid 1983 graphics state: {error}", file=sys.stderr)
        return 1
    print(
        "validated 1983 BBC BASIC graphics state: "
        f"PC={fields['pc']}, SP={fields['sp']}, "
        f"VRAM nonzero={fields['vram_nonzero']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
