#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX1 main ROM in 1983 with the BIOS stub probe and validate the
safe-return contract (carry set, A/BC/DE/HL preserved) for every documented
stub entry."""

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
        "0xF400:0x19",
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
        results = [ram.get(0xF400 + i) for i in range(25)]
        for index, value in enumerate(results):
            if value != 0x07:
                raise ValueError(
                    f"stub {index}: result 0x{value:02X}, expected 0x07 "
                    "(carry + A + BC/DE/HL preserved)"
                )
    except (KeyError, ValueError) as error:
        print(
            f"error: invalid BIOS stub probe result: {error}",
            file=sys.stderr,
        )
        return 1

    print(
        "validated BIOS stub safe-return contract: "
        "all 25 documented stubs set carry and preserve A/BC/DE/HL"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
