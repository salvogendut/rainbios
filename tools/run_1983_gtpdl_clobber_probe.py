#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX1 main ROM in 1983 with the GTPDL clobber probe and validate
the paddle-read contract (result, HL/IX/IY preservation, R15 restore)."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)

R15_BEFORE = 0xF381
RESULT = 0xF382
HL_LO = 0xF383
HL_HI = 0xF384
IX_LO = 0xF385
IX_HI = 0xF386
IY_LO = 0xF387
IY_HI = 0xF388
R15_AFTER = 0xF389
PASS = 0xF38A


def parse_ram_dump(text: str) -> dict[int, int]:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    return values


def check_markers(ram: dict[int, int]) -> list[str]:
    missing: list[str] = []
    if ram.get(RESULT) != 0:
        missing.append(f"GTPDL result: found {ram.get(RESULT)!r}, expected 0")
    if (ram.get(HL_HI), ram.get(HL_LO)) != (0x12, 0x34):
        missing.append("HL not preserved")
    if (ram.get(IX_HI), ram.get(IX_LO)) != (0x56, 0x78):
        missing.append("IX not preserved")
    if (ram.get(IY_HI), ram.get(IY_LO)) != (0x9A, 0xBC):
        missing.append("IY not preserved")
    if ram.get(R15_AFTER) != ram.get(R15_BEFORE):
        missing.append("PSG R15 not restored after GTPDL")
    if ram.get(PASS) != 0x5A:
        missing.append("pass marker")
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
        "0xF381:0xA",
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
    print("validated GTPDL clobber contract: result, HL/IX/IY, R15 restore")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
