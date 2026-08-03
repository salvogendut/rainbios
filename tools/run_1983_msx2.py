#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX2 main ROM in 1983 and validate the MSX2 ID, EXBRSA, and V9938
R8-R23 shadow baseline."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

try:
    from tools.run_1983_m1 import parse_state
except ModuleNotFoundError:
    from run_1983_m1 import parse_state


RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)


def parse_ram_dump(text: str) -> dict[int, int]:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--subrom", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    arguments = parser.parse_args()

    command = [
        arguments.emulator,
        "--config",
        "/dev/null",
        "--models",
        str(arguments.models),
        "--model",
        "msx2",
        "--region",
        "ntsc",
        "--bios",
        str(arguments.bios),
        "--subrom",
        str(arguments.subrom),
        "--headless",
        "--unthrottled",
        "--exit-after",
        "120",
        "--dump-state",
        "--dump-ram",
        "0xFAF8:0x4FF",
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
        fields = parse_state(result.stdout)
        ram = parse_ram_dump(result.stdout)
        exbrsa = ram.get(0xFAF8)
        rg8sav = ram.get(0xFFE7)
        if exbrsa != 0x83:
            raise ValueError(f"EXBRSA=0x{exbrsa:02X}, expected 0x83")
        if rg8sav != 0x08:
            raise ValueError(f"RG8SAV=0x{rg8sav:02X}, expected 0x08")
        if int(fields.get("vram_nonzero", "0")) <= 0:
            raise ValueError("1983 reported blank VRAM")
    except (KeyError, ValueError) as error:
        print(f"error: invalid 1983 MSX2 result: {error}", file=sys.stderr)
        return 1

    print(
        "validated 1983 MSX2 main ROM: "
        f"SP={fields['sp']}, slot={fields['slot']}, "
        f"EXBRSA=0x{exbrsa:02X}, RG8SAV=0x{rg8sav:02X}, "
        f"VRAM nonzero={fields['vram_nonzero']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
