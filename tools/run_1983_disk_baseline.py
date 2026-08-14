#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run a cartridge that validates read-only disk BIOS baseline behavior in 1983."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

try:
    from tools.run_1983_cartridge import validate_state as validate_cartridge_state
except ModuleNotFoundError:
    from run_1983_cartridge import validate_state as validate_cartridge_state


SYMBOL_RE = re.compile(r"^([A-Za-z0-9_]+)\s+#([0-9A-Fa-f]+)\b")


def parse_symbols(path: pathlib.Path) -> dict[str, int]:
    symbols: dict[str, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = SYMBOL_RE.match(line.strip())
        if not match:
            continue
        label, value = match.groups()
        symbols[label.lower()] = int(value, 16)
    return symbols


def expected_label_for_pc(
    symbols: dict[str, int], pc: int, *, success_label: str
) -> str:
    success_label = success_label.lower()
    for label, address in symbols.items():
        if address == pc:
            return label
    return success_label if pc == symbols.get(success_label) else "unknown"


def validate_disk_baseline_state(
    text: str,
    *,
    symbols: dict[str, int],
    expected_slot: str = "F4",
    expected_pass_label: str = "disk_baseline_pass",
    minimum_sp: int = 0xF080,
) -> dict[str, str]:
    fields = validate_cartridge_state(
        text, expected_slot=expected_slot, minimum_sp=minimum_sp
    )
    try:
        pc = int(fields["pc"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("1983 emitted an invalid PC for disk baseline") from error
    expected_pc = symbols.get(expected_pass_label.lower())
    if expected_pc is None:
        raise ValueError(f"missing required symbol {expected_pass_label!r}")
    reached = expected_label_for_pc(symbols, pc, success_label=expected_pass_label)
    if pc != expected_pc:
        raise ValueError(
            f"disk baseline stopped at {reached} ({pc:04X}), expected "
            f"{expected_pass_label} ({expected_pc:04X})"
        )
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--model", default="msx1")
    parser.add_argument("--region", default="ntsc")
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--cartridge", type=pathlib.Path)
    parser.add_argument("--symbols", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    parser.add_argument("--expected-slot", default="F4")
    parser.add_argument("--expected-pass-label", default="disk_baseline_pass")
    parser.add_argument(
        "--minimum-sp", type=lambda value: int(value, 0), default=0xF080
    )
    parser.add_argument("--disk-rom", type=pathlib.Path)
    parser.add_argument("--disk-a", type=pathlib.Path)
    parser.add_argument("--floppy-mode", default="read-only")
    parser.add_argument("--expect-disk-unchanged", action="store_true")
    parser.add_argument("--exit-after", type=int, default=300)
    arguments = parser.parse_args()

    disk_before = None
    if arguments.expect_disk_unchanged:
        if arguments.disk_a is None:
            parser.error("--expect-disk-unchanged requires --disk-a")
        disk_before = arguments.disk_a.read_bytes()

    command = [
        arguments.emulator,
        "--config",
        "/dev/null",
        "--models",
        str(arguments.models),
        "--model",
        arguments.model,
        "--region",
        arguments.region,
        "--bios",
        str(arguments.bios),
        "--headless",
        "--unthrottled",
        "--exit-after",
        str(arguments.exit_after),
        "--dump-state",
        "--screenshot",
        str(arguments.screenshot),
    ]
    if arguments.cartridge:
        command.extend(
            ["--cart", str(arguments.cartridge), "--mapper", "linear"]
        )
    if arguments.disk_rom:
        command.extend(["--disk-rom", str(arguments.disk_rom)])
    if arguments.disk_a:
        command.extend(["--disk-a", str(arguments.disk_a), "--floppy-mode", arguments.floppy_mode])

    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if disk_before is not None:
        disk_after = arguments.disk_a.read_bytes()
        if disk_after != disk_before:
            arguments.disk_a.write_bytes(disk_before)
            print("error: disk image changed during guarded run", file=sys.stderr)
            return 1
    sys.stdout.write(result.stdout)
    if result.returncode:
        return result.returncode
    try:
        symbols = parse_symbols(arguments.symbols)
        fields = validate_disk_baseline_state(
            result.stdout,
            symbols=symbols,
            expected_slot=arguments.expected_slot,
            expected_pass_label=arguments.expected_pass_label,
            minimum_sp=arguments.minimum_sp,
        )
    except ValueError as error:
        print(f"error: invalid 1983 disk baseline state: {error}", file=sys.stderr)
        return 1
    print(
        "validated 1983 disk baseline cartridge: "
        f"PC={fields['pc']}, slot={fields['slot']}, "
        f"VRAM nonzero={fields['vram_nonzero']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
