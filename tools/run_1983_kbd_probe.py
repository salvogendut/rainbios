#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX1 main ROM in 1983 with the keyboard probe and validate the
CHSNS, CHGET, and KILBUF contracts."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


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
    parser.add_argument("--cartridge", type=pathlib.Path, required=True)
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
        "--cart1",
        str(arguments.cartridge),
        "--mapper1",
        "linear",
        "--headless",
        "--unthrottled",
        "--exit-after",
        "600",
        "--dump-state",
        "--dump-ram",
        "0xF380:0x8",
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
        ram = parse_ram_dump(result.stdout)
        markers = {
            "chsns_empty": ram.get(0xF381),
            "chsns_data": ram.get(0xF382),
            "chget_char": ram.get(0xF383),
            "chget_regs": ram.get(0xF384),
            "chget_ptr": ram.get(0xF385),
            "chsns_after": ram.get(0xF386),
            "pass": ram.get(0xF387),
        }
        for name, value in markers.items():
            if value != 0x01:
                raise ValueError(
                    f"{name}=0x{value:02X}, expected 0x01"
                )
    except (KeyError, ValueError) as error:
        print(
            f"error: invalid keyboard probe result: {error}",
            file=sys.stderr,
        )
        return 1

    print(
        "validated keyboard contracts: "
        "CHSNS empty/data, CHGET char + BC/DE/HL preserved + pointer advance, "
        "KILBUF reset"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
