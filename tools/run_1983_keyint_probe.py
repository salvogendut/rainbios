#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX1 main ROM in 1983 with the KEYINT probe and validate the
VBlank bookkeeping contract (STATFL and JIFFY updates)."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)

BASE = 0xF381

M_JIFFY0 = BASE + 0
M_JIFFY1 = BASE + 1
M_STATFL = BASE + 2
M_PASS = BASE + 3


def parse_ram_dump(text: str) -> dict[int, int]:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    return values


def check_markers(ram: dict[int, int]) -> list[str]:
    missing: list[str] = []
    jiffy0 = ram.get(M_JIFFY0)
    jiffy1 = ram.get(M_JIFFY1)
    statfl = ram.get(M_STATFL)
    if jiffy0 is None or jiffy1 is None or statfl is None:
        missing.append("KEYINT markers not present in the RAM dump")
        return missing
    if jiffy1 != jiffy0 + 1:
        missing.append(f"JIFFY grew to {jiffy1} from {jiffy0}, expected +1")
    if statfl != 0x80:
        missing.append(f"STATFL after KEYINT is {statfl:02X}, expected 80")
    if ram.get(M_PASS) != 0x5A:
        missing.append("pass marker not set")
    return missing


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
        "1200",
        "--dump-state",
        "--dump-ram",
        "0xF381:0x4",
    ]
    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        timeout=120,
    )
    output = result.stdout + result.stderr
    try:
        ram = parse_ram_dump(output)
    except ValueError:
        ram = {}
    missing = check_markers(ram)
    if missing:
        print("\n".join(missing), file=sys.stderr)
        return 1
    print("validated KEYINT VBlank bookkeeping: STATFL and JIFFY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
