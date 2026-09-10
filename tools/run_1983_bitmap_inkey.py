#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Require embedded BBC BASIC INKEY to keep working after MSX2 bitmap CHGMOD."""

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
PROGRAM = (
    "1\n"
    "10 MODE 8\n"
    "20 A%=INKEY(100)\n"
    "30 ?&E000=&5A:?&E001=&A5:?&E002=A%\n"
    "40 MODE 0\n"
    "RUN\n"
)


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
        "--paste-at",
        "300",
        "--paste-text",
        PROGRAM,
        "--exit-after",
        "900",
        "--dump-state",
        "--dump-ram",
        "0xE000:3",
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
        marker = [ram.get(address) for address in range(0xE000, 0xE003)]
        if marker != [0x5A, 0xA5, 0xFF]:
            rendered = " ".join(
                "??" if value is None else f"{value:02X}" for value in marker
            )
            raise ValueError(
                f"completion/timeout marker is {rendered}, expected 5A A5 FF"
            )
        expected = {"vdp_r0": "00", "vdp_r1": "70"}
        for key, value in expected.items():
            if fields.get(key) != value:
                raise ValueError(
                    f"{key}: found {fields.get(key)!r}, expected {value!r}"
                )
    except ValueError as error:
        print(f"error: invalid 1983 bitmap INKEY result: {error}", file=sys.stderr)
        return 1

    print(
        "validated embedded BASIC bitmap INKEY timeout in 1983: "
        "completion marker=5A A5 FF, final Screen 0 VDP R0=00 R1=70"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
