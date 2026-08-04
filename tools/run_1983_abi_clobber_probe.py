#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX1 main ROM in 1983 with the ABI clobber probe and validate the
flag and register contracts of DCOMPR, WRTPSG, and RDPSG."""

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
        "600",
        "--dump-state",
        "--dump-ram",
        "0xF380:0x9",
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
            "dcompr_lt_carry": ram.get(0xF381),
            "dcompr_lt_zero": ram.get(0xF382),
            "dcompr_eq_carry": ram.get(0xF383),
            "dcompr_eq_zero": ram.get(0xF384),
            "dcompr_gt_carry": ram.get(0xF385),
            "dcompr_bc": ram.get(0xF386),
            "psg": ram.get(0xF387),
            "pass": ram.get(0xF388),
        }
        expected = {
            "dcompr_lt_carry": 0x01,
            "dcompr_lt_zero": 0x00,
            "dcompr_eq_carry": 0x00,
            "dcompr_eq_zero": 0x01,
            "dcompr_gt_carry": 0x00,
            "dcompr_bc": 0x01,
            "psg": 0x01,
            "pass": 0x01,
        }
        for name, value in expected.items():
            if markers[name] != value:
                raise ValueError(
                    f"{name}=0x{markers[name]:02X}, expected 0x{value:02X}"
                )
    except (KeyError, ValueError) as error:
        print(
            f"error: invalid ABI clobber probe result: {error}",
            file=sys.stderr,
        )
        return 1

    print(
        "validated ABI clobber/flag contracts: "
        "DCOMPR carry/zero cases, BC preservation, "
        "WRTPSG/RDPSG round trip"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
