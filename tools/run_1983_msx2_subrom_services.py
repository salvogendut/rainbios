#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the MSX2 main ROM in 1983 with the RainBIOS SUB-ROM services probe and
validate the bitmap CHGMOD, palette, and 16-bit VRAM markers."""

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
        "360",
        "--dump-state",
        "--dump-ram",
        "0xF360:0x20",
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
            "SC5": ram.get(0xF360),
            "NAM5": int.from_bytes(
                bytes((ram.get(0xF361, 0), ram.get(0xF362, 0))), "little"
            ),
            "PAT5": int.from_bytes(
                bytes((ram.get(0xF363, 0), ram.get(0xF364, 0))), "little"
            ),
            "ATR5": int.from_bytes(
                bytes((ram.get(0xF365, 0), ram.get(0xF366, 0))), "little"
            ),
            "SC6": ram.get(0xF367),
            "SC7": ram.get(0xF368),
            "SC8": ram.get(0xF369),
            "VRAM16": ram.get(0xF36A),
            "PLT_B": ram.get(0xF36B),
            "PLT_C": ram.get(0xF36C),
            "LOW_VRAM": ram.get(0xF36D),
            "HIGH_VRAM": ram.get(0xF36E),
            "CE_FONT": ram.get(0xF36F),
            "SC5_PAGE0": ram.get(0xF370),
            "SC5_PAGE1": ram.get(0xF371),
            "SC5_PAGE2": ram.get(0xF372),
            "SC5_PAGE3": ram.get(0xF373),
            "SC8_PAGE0": ram.get(0xF374),
            "SC8_PAGE1": ram.get(0xF375),
        }
        expected = {
            "SC5": 0x05,
            "NAM5": 0x0000,
            "PAT5": 0x7800,
            "ATR5": 0x7600,
            "SC6": 0x06,
            "SC7": 0x07,
            "SC8": 0x08,
            "VRAM16": 0x5A,
            "PLT_B": 0x00,
            "PLT_C": 0x07,
            "LOW_VRAM": 0xA5,
            "HIGH_VRAM": 0x3C,
            "CE_FONT": 0x38,
            "SC5_PAGE0": 0x50,
            "SC5_PAGE1": 0x51,
            "SC5_PAGE2": 0x52,
            "SC5_PAGE3": 0x53,
            "SC8_PAGE0": 0x70,
            "SC8_PAGE1": 0x71,
        }
        for name, value in expected.items():
            if markers[name] != value:
                raise ValueError(
                    f"{name}=0x{markers[name]:04X}, expected 0x{value:04X}"
                )
        if int(fields.get("vram_nonzero", "0")) <= 0:
            raise ValueError("1983 reported blank VRAM")
    except (KeyError, ValueError) as error:
        print(
            f"error: invalid 1983 MSX2 SUB-ROM services result: {error}",
            file=sys.stderr,
        )
        return 1

    print(
        "validated 1983 MSX2 SUB-ROM services: "
        f"Screens 5/6/7/8 SCRMOD, SC5 bases 0000/7800/7600, "
        f"16-bit VRAM=0x{markers['VRAM16']:02X}, "
        f"low-bank reset=0x{markers['LOW_VRAM']:02X}/0x{markers['HIGH_VRAM']:02X}, "
        f"SC5 pages={markers['SC5_PAGE0']:02X}/{markers['SC5_PAGE1']:02X}/"
        f"{markers['SC5_PAGE2']:02X}/{markers['SC5_PAGE3']:02X}, "
        f"SC8 pages={markers['SC8_PAGE0']:02X}/{markers['SC8_PAGE1']:02X}, "
        f"async INITXT font=0x{markers['CE_FONT']:02X}, "
        f"palette B=0x{markers['PLT_B']:02X} C=0x{markers['PLT_C']:02X}, "
        f"VDP R0={fields['vdp_r0']} R1={fields['vdp_r1']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
