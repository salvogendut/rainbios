#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX1 main ROM in 1983 with the function-key/text probe and validate
the FNKSB, ERAFNK, DSPFNK, TOTEXT, and POSIT contracts."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


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
        "800",
        "--dump-state",
        "--dump-ram",
        "0xF380:0xC",
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
        markers = {
            "posit_x": ram.get(0xF381),
            "posit_y": ram.get(0xF382),
            "erafnk_cns": ram.get(0xF383),
            "erafnk_vram": ram.get(0xF384),
            "dspfnk_cns": ram.get(0xF385),
            "dspfnk_row": ram.get(0xF386),
            "fnksb_on": ram.get(0xF387),
            "fnksb_off": ram.get(0xF388),
            "totext_mode": ram.get(0xF389),
            "totext_cns": ram.get(0xF38A),
            "pass": ram.get(0xF38B),
        }
        expected = {
            "posit_x": 0x05,
            "posit_y": 0x03,
            "erafnk_cns": 0x00,
            "erafnk_vram": 0x20,
            "dspfnk_cns": 0xFF,
            "dspfnk_row": 0x17,
            "fnksb_on": 0xFF,
            "fnksb_off": 0x00,
            "totext_mode": 0x00,
            "totext_cns": 0xFF,
            "pass": 0x01,
        }
        for name, value in expected.items():
            if markers[name] != value:
                raise ValueError(
                    f"{name}=0x{markers[name]:02X}, expected 0x{value:02X}"
                )
    except (KeyError, ValueError) as error:
        print(
            f"error: invalid function-key probe result: {error}",
            file=sys.stderr,
        )
        return 1

    print(
        "validated function-key/text contracts: "
        "POSIT cursor, ERAFNK erase, DSPFNK render, FNKSB toggle, TOTEXT mode"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
