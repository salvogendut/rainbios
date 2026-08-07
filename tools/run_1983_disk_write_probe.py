#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the production NMS 8250 disk ROM in 1983 with the DSKIO write fixture
and validate the writable-media and write-protect contracts."""

from __future__ import annotations

import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

try:
    from tools.run_1983_m1 import parse_state
except ModuleNotFoundError:
    from run_1983_m1 import parse_state


RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)

BASE = 0xF3C0
SECTOR_SIZE = 512
WRITE_SECTOR = 2
PATTERN = bytes(range(256)) * 2

M_WRITE_CARRY = BASE + 0
M_WRITE_ERROR = BASE + 1
M_PASS = BASE + 4


def parse_markers(text: str) -> dict[int, int]:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    return values


def check_markers(text: str, *, write_protect: bool) -> None:
    markers = parse_markers(text)
    if markers.get(M_PASS) != 0x5A:
        raise ValueError("DSKIO write fixture did not reach its pass label")
    if write_protect:
        if markers.get(M_WRITE_CARRY) != 0x01:
            raise ValueError(
                f"write-protect carry={markers.get(M_WRITE_CARRY)!r}, expected 1"
            )
        if markers.get(M_WRITE_ERROR) != 0x03:
            raise ValueError(
                f"write-protect error={markers.get(M_WRITE_ERROR)!r}, expected 3"
            )
    else:
        if markers.get(M_WRITE_CARRY) != 0x00:
            raise ValueError(
                f"writable carry={markers.get(M_WRITE_CARRY)!r}, expected 0"
            )
        if markers.get(M_WRITE_ERROR) != 0x00:
            raise ValueError(
                f"writable error={markers.get(M_WRITE_ERROR)!r}, expected 0"
            )


def check_image_written(image: pathlib.Path) -> None:
    with image.open("rb") as handle:
        handle.seek(WRITE_SECTOR * SECTOR_SIZE)
        sector = handle.read(SECTOR_SIZE)
    if sector != PATTERN:
        raise ValueError("disk image sector 2 does not hold the written pattern")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--disk-rom", type=pathlib.Path, required=True)
    parser.add_argument("--disk-a", type=pathlib.Path, required=True)
    parser.add_argument("--write-protect", action="store_true")
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    arguments = parser.parse_args()

    mode = "read-only" if arguments.write_protect else "read-write"
    with tempfile.TemporaryDirectory() as directory:
        working = pathlib.Path(directory) / "disk-write.dsk"
        shutil.copy2(arguments.disk_a, working)
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
            str(working),
            "--floppy-mode",
            mode,
            "--headless",
            "--unthrottled",
            "--exit-after",
            "300",
            "--dump-state",
            "--dump-ram",
            "0xF3C0:0x5",
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
            check_markers(result.stdout, write_protect=arguments.write_protect)
            if not arguments.write_protect:
                check_image_written(working)
        except (ValueError, OSError) as error:
            print(f"error: invalid 1983 DSKIO write result: {error}", file=sys.stderr)
            return 1
    if arguments.write_protect:
        print("validated 1983 DSKIO write-protect: error 3, image untouched")
    else:
        print("validated 1983 DSKIO write path: sector 2 pattern persisted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
