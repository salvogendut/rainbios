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
) -> dict[str, str]:
    fields = validate_cartridge_state(text, expected_slot=expected_slot)
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
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--cartridge", type=pathlib.Path, required=True)
    parser.add_argument("--symbols", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    parser.add_argument("--expected-slot", default="F4")
    parser.add_argument("--expected-pass-label", default="disk_baseline_pass")
    parser.add_argument("--disk-a", type=pathlib.Path)
    parser.add_argument("--floppy-mode", default="read-only")
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
        "--cart",
        str(arguments.cartridge),
        "--mapper",
        "linear",
        "--headless",
        "--unthrottled",
        "--exit-after",
        "300",
        "--dump-state",
        "--screenshot",
        str(arguments.screenshot),
    ]
    if arguments.disk_a:
        command.extend(["--disk-a", str(arguments.disk_a), "--floppy-mode", arguments.floppy_mode])

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
        symbols = parse_symbols(arguments.symbols)
        fields = validate_disk_baseline_state(
            result.stdout,
            symbols=symbols,
            expected_slot=arguments.expected_slot,
            expected_pass_label=arguments.expected_pass_label,
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
