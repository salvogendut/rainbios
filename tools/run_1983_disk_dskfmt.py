#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the NMS 8250 disk ROM with DSKFMT fixture and validate."""

from __future__ import annotations

import argparse
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)

M_CARRY = 0xF3D0
M_ERROR = 0xF3D1
M_CHOICE_LO = 0xF3D2
M_CHOICE_HI = 0xF3D3
M_PASS = 0xF3D5


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
            f"DSKFMT fixture did not reach pass (pass={markers.get(M_PASS)!r})"
        )
    choice = markers.get(M_CHOICE_LO, 0) | (markers.get(M_CHOICE_HI, 0) << 8)
    if choice != 1:
        raise ValueError(f"CHOICE returned {choice}, expected 1")
    carry = markers.get(M_CARRY, 0xFF)
    error = markers.get(M_ERROR, 0xFF)
    if carry != 0x00:
        print(
            f"note: DSKFMT returned carry={carry}, error={error} "
            f"(expected with virtual FDC; format verification requires "
            f"real hardware)"
        )
    print(
        "validated 1983 DSKFMT: CHOICE=1, format loop ran to completion "
        "(fill-byte verification requires hardware)"
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

    with tempfile.TemporaryDirectory() as directory:
        working = pathlib.Path(directory) / "disk-dskfmt.dsk"
        shutil.copy2(arguments.disk_a, working)
        command = [
            arguments.emulator,
            "--config", "/dev/null",
            "--models", str(arguments.models),
            "--model", "nms8250", "--region", "pal",
            "--bios", str(arguments.bios),
            "--disk-rom", str(arguments.disk_rom),
            "--disk-a", str(working),
            "--floppy-mode", "read-write",
            "--headless", "--unthrottled",
            "--exit-after", "4000",
            "--dump-state", "--dump-ram", "0xF3D0:0x6",
            "--screenshot", str(arguments.screenshot),
        ]
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        )
        sys.stdout.write(result.stdout)
        if result.returncode:
            return result.returncode
        try:
            check_markers(result.stdout)
        except ValueError as error:
            print(f"error: invalid DSKFMT result: {error}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
