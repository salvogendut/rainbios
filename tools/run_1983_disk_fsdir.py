#!/usr/bin/env python3
"""Run the FAT12 FS.DIR probe in 1983 and validate markers."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)

BASE = 0xF3D0
M_CARRY = BASE + 0
M_ERROR = BASE + 1
M_ENTRIES_LO = BASE + 2
M_ENTRIES_HI = BASE + 3
M_PASS = BASE + 5


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
            f"FS.DIR fixture did not reach pass label (pass={markers.get(M_PASS)!r})"
        )
    if markers.get(M_CARRY) != 0x00:
        raise ValueError(f"FS.DIR carry={markers.get(M_CARRY)!r}, expected 0")
    if markers.get(M_ERROR) != 0x00:
        raise ValueError(f"FS.DIR error={markers.get(M_ERROR)!r}, expected 0")
    entries = markers.get(M_ENTRIES_LO, 0) | (markers.get(M_ENTRIES_HI, 0) << 8)
    if entries != 32:
        raise ValueError(
            f"FS.DIR returned {entries} bytes, expected 32 (one entry)"
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
        arguments.emulator, "--config", "/dev/null",
        "--models", str(arguments.models), "--model", "nms8250", "--region", "pal",
        "--bios", str(arguments.bios), "--disk-rom", str(arguments.disk_rom),
        "--disk-a", str(arguments.disk_a), "--floppy-mode", "read-only",
        "--headless", "--unthrottled", "--exit-after", "1500",
        "--dump-state", "--dump-ram", "0xF3D0:0x6",
        "--screenshot", str(arguments.screenshot),
    ]
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    sys.stdout.write(result.stdout)
    if result.returncode:
        return result.returncode
    try:
        check_markers(result.stdout)
    except ValueError as error:
        print(f"error: invalid 1983 FS.DIR result: {error}", file=sys.stderr)
        return 1
    print("validated 1983 FS.DIR: RAIN.BIN found, cluster=2, size=3072")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
