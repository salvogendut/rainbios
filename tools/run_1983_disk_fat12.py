#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the production NMS 8250 disk ROM in 1983 with the FAT12 FS.LOAD
fixture and validate the complete read path: BPB parse, root-directory walk,
FAT12 cluster chain, and PHYDIO sector delivery."""

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

BASE = 0xF3D0

M_CARRY = BASE + 0
M_ERROR = BASE + 1
M_SIZE_LO = BASE + 2
M_SIZE_HI = BASE + 3
M_COMPARE = BASE + 4
M_PASS = BASE + 5

EXPECTED_SIZE = 0x0C00


def parse_markers(text: str) -> dict[int, int]:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    return values


def check_markers(text: str) -> None:
    markers = parse_markers(text)
    if markers.get(M_PASS) != 0x5A:
        raise ValueError(
            f"FS.LOAD fixture did not reach its pass label "
            f"(pass={markers.get(M_PASS)!r})"
        )
    if markers.get(M_CARRY) != 0x00:
        raise ValueError(
            f"FS.LOAD carry={markers.get(M_CARRY)!r}, expected 0"
        )
    if markers.get(M_ERROR) != 0x00:
        raise ValueError(
            f"FS.LOAD error={markers.get(M_ERROR)!r}, expected 0"
        )
    size = markers.get(M_SIZE_LO, 0) | (markers.get(M_SIZE_HI, 0) << 8)
    if size != EXPECTED_SIZE:
        raise ValueError(
            f"FS.LOAD file size 0x{size:04X}, expected 0x{EXPECTED_SIZE:04X}"
        )
    if markers.get(M_COMPARE) != 0x5A:
        raise ValueError(
            f"content compare={markers.get(M_COMPARE)!r}, expected 0x5A"
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--disk-rom", type=pathlib.Path, required=True)
    parser.add_argument("--disk-a", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    arguments = parser.parse_args()

    command = [
        arguments.emulator,
        "--config",
        "/dev/null",
        "--models",
        str(arguments.models),
        "--model",
        "nms8250",
        "--region",
        "pal",
        "--bios",
        str(arguments.bios),
        "--disk-rom",
        str(arguments.disk_rom),
        "--disk-a",
        str(arguments.disk_a),
        "--floppy-mode",
        "read-only",
        "--headless",
        "--unthrottled",
        "--exit-after",
        "1500",
        "--dump-state",
        "--dump-ram",
        "0xF3D0:0x6",
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
        check_markers(result.stdout)
    except ValueError as error:
        print(f"error: invalid 1983 FS.LOAD result: {error}", file=sys.stderr)
        return 1
    print("validated 1983 FS.LOAD read path: cluster chain and content verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
