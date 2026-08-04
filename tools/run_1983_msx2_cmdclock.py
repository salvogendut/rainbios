#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX2 main ROM in 1983 with the RainBIOS SUB-ROM command/clock
probe and validate the BLTVV/BLTVM/BLTMV and REDCLK/WRTCLK markers."""

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
        "0xF380:0x10",
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
            "BLTVV0": ram.get(0xF380),
            "BLTVV1": ram.get(0xF381),
            "BLTVV2": ram.get(0xF382),
            "BLTVV3": ram.get(0xF383),
            "BLTVM0": ram.get(0xF384),
            "BLTVM1": ram.get(0xF385),
            "BLTVM2": ram.get(0xF386),
            "RTC": ram.get(0xF387),
            "BLTMV_NX": ram.get(0xF388),
            "BLTMV_P0": ram.get(0xF389),
            "BLTMV_P1": ram.get(0xF38A),
            "BLTMV_P2": ram.get(0xF38B),
        }
        expected = {
            "BLTVV0": 0x04,
            "BLTVV1": 0x03,
            "BLTVV2": 0x02,
            "BLTVV3": 0x01,
            "BLTVM0": 0x33,
            "BLTVM1": 0x33,
            "BLTVM2": 0x33,
            "RTC": 0x0A,
            "BLTMV_NX": 0x08,
            "BLTMV_P0": 0x04,
            "BLTMV_P1": 0x03,
            "BLTMV_P2": 0x02,
        }
        for name, value in expected.items():
            if markers[name] != value:
                raise ValueError(
                    f"{name}=0x{markers[name]:02X}, expected 0x{value:02X}"
                )
    except (KeyError, ValueError) as error:
        print(
            f"error: invalid 1983 MSX2 SUB-ROM command/clock result: {error}",
            file=sys.stderr,
        )
        return 1

    print(
        "validated 1983 MSX2 SUB-ROM command/clock: "
        f"BLTVV copy {markers['BLTVV0']:02X}{markers['BLTVV1']:02X}"
        f"{markers['BLTVV2']:02X}{markers['BLTVV3']:02X}, "
        f"BLTVM dest=0x{markers['BLTVM0']:02X}, "
        f"BLTMV header NX=0x{markers['BLTMV_NX']:02X} "
        f"pixels={markers['BLTMV_P0']:02X}{markers['BLTMV_P1']:02X}"
        f"{markers['BLTMV_P2']:02X}, "
        f"RTC round trip=0x{markers['RTC']:02X}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
