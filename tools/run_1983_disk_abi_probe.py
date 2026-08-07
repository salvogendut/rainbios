#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX1 main ROM in 1983 with the disk ABI probe and validate the
hook-dispatching disk entries and the PSG voice pointer entries."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)

# (marker, expected, label)
EXPECTED = (
    (0xF381, 0x01, "PHYDIO carry set (H_PHYD default)"),
    (0xF382, 0x01, "FORMAT carry set (H_FORM default)"),
    (0xF383, 0x01, "OUTDLP carry set (H_OUTD default)"),
    (0xF384, 0x00, "ISFLIO A=0 (H_ISFL default)"),
    (0xF385, 0x43, "GETVCP low byte"),
    (0xF386, 0xFB, "GETVCP high byte"),
    (0xF387, 0x01, "GETVCP carry"),
    (0xF388, 0x46, "GETVC2 low byte"),
    (0xF389, 0xFB, "GETVC2 high byte"),
    (0xF38A, 0x42, "FORMAT dispatches to the H_FORM hook"),
    (0xF38B, 0x5A, "pass marker"),
)


def check_markers(ram: dict[int, int]) -> list[str]:
    missing: list[str] = []
    for address, expected, label in EXPECTED:
        found = ram.get(address)
        if found != expected:
            missing.append(f"{label}: found {found!r}, expected {expected!r}")
    return missing


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
        "0xF380:0xC",
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
    print("validated disk ABI baseline: hook-dispatching entries and voice pointers")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
