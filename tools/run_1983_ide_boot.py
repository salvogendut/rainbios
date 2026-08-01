#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run 1983 and require the RainBIOS IDE bootstrap to boot a fixture image or
fall back to the interactive menu when no bootable IDE medium is present."""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys

try:
    from tools.run_1983_m1 import parse_state
    from tools.run_1983_disk_baseline import parse_symbols
except ModuleNotFoundError:
    from run_1983_m1 import parse_state
    from run_1983_disk_baseline import parse_symbols


def validate_boot_pass(
    text: str,
    *,
    symbols: dict[str, int],
    expected_slot: str = "F8",
    expected_pass_label: str = "ide_boot_pass",
) -> dict[str, str]:
    fields = parse_state(text)
    if int(fields.get("vram_nonzero", "0")) <= 0:
        raise ValueError("1983 reported blank VRAM")
    if fields.get("slot") != expected_slot:
        raise ValueError(
            f"slot: found {fields.get('slot')!r}, expected {expected_slot!r}"
        )
    try:
        pc = int(fields["pc"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("1983 emitted an invalid PC for IDE boot") from error
    expected_pc = symbols.get(expected_pass_label.lower())
    if expected_pc is None:
        raise ValueError(f"missing required symbol {expected_pass_label!r}")
    if pc != expected_pc:
        raise ValueError(
            f"IDE boot stopped at {pc:04X}, expected "
            f"{expected_pass_label} ({expected_pc:04X})"
        )
    return fields


def validate_fallback(
    text: str,
    *,
    expected_slot: str = "F0",
) -> dict[str, str]:
    fields = parse_state(text)
    if int(fields.get("vram_nonzero", "0")) <= 0:
        raise ValueError("1983 reported blank VRAM")
    if fields.get("slot") != expected_slot:
        raise ValueError(
            f"slot: found {fields.get('slot')!r}, expected {expected_slot!r}"
        )
    try:
        sp = int(fields["sp"], 16)
        pc = int(fields["pc"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("1983 emitted an invalid state for IDE boot") from error
    if not 0xF300 <= sp <= 0xF380:
        raise ValueError(
            f"SP {sp:04X} is outside RainBIOS main RAM; the bootstrap hook "
            "failed to return to the interactive menu"
        )
    if not 0x0000 <= pc < 0x8000:
        raise ValueError(
            f"PC {pc:04X} is outside the main BIOS ROM; the bootstrap hook "
            "did not resume the interactive menu"
        )
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--model", default="nms8250")
    parser.add_argument("--region", default="pal")
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--disk-rom", type=pathlib.Path)
    parser.add_argument("--sunrise-rom", type=pathlib.Path, required=True)
    parser.add_argument("--ide", type=pathlib.Path)
    parser.add_argument("--input-cartridge", type=pathlib.Path)
    parser.add_argument("--symbols", type=pathlib.Path)
    parser.add_argument("--expected-pass-label", default="ide_boot_pass")
    parser.add_argument("--expected-slot", default="F8")
    parser.add_argument("--expect-fallback", action="store_true")
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    parser.add_argument("--exit-after", type=int, default=1200)
    arguments = parser.parse_args()

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
        "--sunrise-rom",
        str(arguments.sunrise_rom),
    ]
    if arguments.disk_rom:
        command.extend(["--disk-rom", str(arguments.disk_rom)])
    if arguments.input_cartridge:
        command.extend(
            ["--cart1", str(arguments.input_cartridge), "--mapper1", "linear"]
        )
    if arguments.ide:
        command.extend(["--ide", str(arguments.ide)])

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
        if arguments.expect_fallback:
            fields = validate_fallback(
                result.stdout,
                expected_slot=arguments.expected_slot,
            )
            print(
                "validated 1983 IDE boot fallback: "
                f"PC={fields['pc']}, SP={fields['sp']}, slot={fields['slot']}"
            )
        else:
            if arguments.symbols is None:
                parser.error("--symbols is required without --expect-fallback")
            symbols = parse_symbols(arguments.symbols)
            fields = validate_boot_pass(
                result.stdout,
                symbols=symbols,
                expected_slot=arguments.expected_slot,
                expected_pass_label=arguments.expected_pass_label,
            )
            print(
                "validated 1983 IDE boot: "
                f"PC={fields['pc']}, SP={fields['sp']}, slot={fields['slot']}"
            )
    except ValueError as error:
        print(f"error: invalid 1983 IDE boot state: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
