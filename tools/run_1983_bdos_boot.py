#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the source-built DOS fixture and validate the resident BDOS path."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

try:
    from tools.run_1983_disk_baseline import parse_symbols
    from tools.run_1983_m1 import parse_state
except ModuleNotFoundError:
    from run_1983_disk_baseline import parse_symbols
    from run_1983_m1 import parse_state

RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)
LOADER_HL = 0xF3CC
LOADER_DE = 0xF3CE
M_VERSION = 0xF3D0
M_LOGIN = 0xF3D2
M_DRIVE = 0xF3D4
M_PASS = 0xF3D5
M_INPUT = 0xF3D6


def parse_ram(text: str) -> dict[int, int]:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    return values


def word(values: dict[int, int], address: int) -> int:
    return values.get(address, -1) | (values.get(address + 1, -1) << 8)


def validate(
    text: str, *, symbols: dict[str, int], expected_slot: str
) -> dict[str, str]:
    fields = parse_state(text)
    values = parse_ram(text)
    if word(values, LOADER_HL) != 0xF323:
        raise ValueError("boot loader did not receive DISKVE F323h")
    if word(values, LOADER_DE) != 0xF368:
        raise ValueError("boot loader did not receive ENAKRN F368h")
    if word(values, M_VERSION) != 0x0022:
        raise ValueError("CALL 5 GET VERSION did not return 0022h")
    if word(values, M_LOGIN) != 0x0001:
        raise ValueError("CALL 5 GET LOGIN VECTOR did not return drive A")
    if values.get(M_DRIVE) != 0:
        raise ValueError("CALL 5 GET DEFAULT DRIVE did not return drive A")
    if values.get(M_PASS) != 0x5A:
        raise ValueError("source-built DOS system did not reach its pass marker")
    if values.get(M_INPUT + 1) != 2:
        raise ValueError("CALL 5 buffered input did not return two characters")
    input_bytes = bytes(
        values.get(M_INPUT + offset, -1) for offset in range(2, 5)
    )
    if input_bytes != b"OK\r":
        raise ValueError(
            "CALL 5 buffered input did not return OK plus carriage return"
        )
    expected_pc = symbols.get("disk_bdos_system_pass")
    if expected_pc is None:
        raise ValueError("system symbol file has no pass label")
    if int(fields.get("pc", "-1"), 16) != expected_pc:
        raise ValueError(
            f"PC={fields.get('pc')}, expected system pass {expected_pc:04X}"
        )
    if fields.get("slot") != expected_slot:
        raise ValueError(
            f"page-0 execution slot={fields.get('slot')}, expected {expected_slot}"
        )
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--subrom", type=pathlib.Path)
    parser.add_argument("--disk-rom", type=pathlib.Path, required=True)
    parser.add_argument("--disk-a", type=pathlib.Path, required=True)
    parser.add_argument("--symbols", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    parser.add_argument("--expected-slot", default="FF")
    arguments = parser.parse_args()

    command = [
        arguments.emulator,
        "--config", "/dev/null",
        "--models", str(arguments.models),
        "--model", "nms8250",
        "--region", "pal",
        "--bios", str(arguments.bios),
        "--disk-rom", str(arguments.disk_rom),
        "--disk-a", str(arguments.disk_a),
        "--floppy-mode", "read-only",
        "--headless", "--unthrottled",
        "--exit-after", "1800",
        "--paste-text", "OK\n",
        "--paste-at", "200",
        "--dump-state",
        "--dump-ram", "0xF3CC:0x10",
        "--screenshot", str(arguments.screenshot),
    ]
    if arguments.subrom is not None:
        command.extend(["--subrom", str(arguments.subrom)])
    result = subprocess.run(
        command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
    )
    sys.stdout.write(result.stdout)
    if result.returncode:
        return result.returncode
    try:
        fields = validate(
            result.stdout,
            symbols=parse_symbols(arguments.symbols),
            expected_slot=arguments.expected_slot,
        )
    except ValueError as error:
        print(f"error: invalid clean-room BDOS boot: {error}", file=sys.stderr)
        return 1
    machine = "MSX2" if arguments.subrom is not None else "MSX1"
    print(
        f"validated clean-room BDOS boot on {machine}: "
        f"PC={fields['pc']}, slot={fields['slot']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
