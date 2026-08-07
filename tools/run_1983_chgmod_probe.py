#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX1 main ROM in 1983 with the CHGMOD probe and validate the
screen-mode dispatch and unsupported-mode carry contract."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)

BASE = 0xF381

# (marker, expected, label)
EXPECTED = (
    (BASE + 0, 0x00, "CHGMOD(0) SCRMOD 0"),
    (BASE + 1, 0x01, "CHGMOD(1) SCRMOD 1"),
    (BASE + 2, 0x02, "CHGMOD(2) SCRMOD 2"),
    (BASE + 3, 0x03, "CHGMOD(3) SCRMOD 3"),
    (BASE + 4, 0x01, "CHGMOD(4) carry set"),
    (BASE + 5, 0x03, "CHGMOD(4) leaves SCRMOD 3"),
    (BASE + 6, 0x01, "CHGMOD(5) carry set"),
    (BASE + 7, 0x01, "CHGMOD(9) carry set"),
    (BASE + 8, 0x5A, "pass marker"),
)


def parse_ram_dump(text: str) -> dict[int, int]:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    return values


def check_markers(ram: dict[int, int]) -> list[str]:
    missing: list[str] = []
    for address, expected, label in EXPECTED:
        found = ram.get(address)
        if found != expected:
            missing.append(f"{label}: found {found!r}, expected {expected!r}")
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
        "600",
        "--dump-state",
        "--dump-ram",
        "0xF381:0x9",
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
    print("validated CHGMOD dispatch and unsupported-mode carry")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
