#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX2 main ROM in 1983 with the SUB-ROM probe cartridge and validate
the SUBROM/EXTROM/CHKSLZ calling contract markers."""

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
    parser.add_argument("--subrom", type=pathlib.Path, required=True)
    parser.add_argument("--cartridge", type=pathlib.Path, required=True)
    arguments = parser.parse_args()

    command = [
        arguments.emulator,
        "--config",
        "/dev/null",
        "--models",
        str(arguments.models),
        "--model",
        "msx2",
        "--region",
        "ntsc",
        "--bios",
        str(arguments.bios),
        "--subrom",
        str(arguments.subrom),
        "--cart1",
        str(arguments.cartridge),
        "--mapper1",
        "linear",
        "--headless",
        "--unthrottled",
        "--exit-after",
        "120",
        "--dump-state",
        "--dump-ram",
        "0xF360:0x10",
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
        fields = parse_state(result.stdout)
        ram = parse_ram_dump(result.stdout)
        markers = {
            "MARKER_CHKSLZ": ram.get(0xF360),
            "MARKER_EXBRSA": ram.get(0xF361),
            "MARKER_EXTROM": ram.get(0xF362),
            "MARKER_SUBROM": ram.get(0xF363),
        }
        expected = {
            "MARKER_CHKSLZ": 0x01,
            "MARKER_EXBRSA": 0x83,
            "MARKER_EXTROM": 0xA5,
            "MARKER_SUBROM": 0x5A,
        }
        for name, value in expected.items():
            if markers[name] != value:
                raise ValueError(
                    f"{name}=0x{markers[name]:02X}, expected 0x{value:02X}"
                )
        if int(fields.get("vram_nonzero", "0")) <= 0:
            raise ValueError("1983 reported blank VRAM")
    except (KeyError, ValueError) as error:
        print(f"error: invalid 1983 MSX2 SUB-ROM result: {error}", file=sys.stderr)
        return 1

    print(
        "validated 1983 MSX2 SUB-ROM contract: "
        f"CHKSLZ=0x{markers['MARKER_CHKSLZ']:02X}, "
        f"EXBRSA=0x{markers['MARKER_EXBRSA']:02X}, "
        f"EXTROM=0x{markers['MARKER_EXTROM']:02X}, "
        f"SUBROM=0x{markers['MARKER_SUBROM']:02X}, "
        f"PC={fields['pc']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
