#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run 1983 and require execution inside a primary-slot cartridge."""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys

try:
    from tools.run_1983_m1 import parse_state
except ModuleNotFoundError:
    from run_1983_m1 import parse_state


def validate_state(
    text: str,
    *,
    expected_slot: str = "F4",
    expected_vdp_r0: str | None = None,
    expected_vdp_r1: str | None = None,
) -> dict[str, str]:
    fields = parse_state(text)
    try:
        pc = int(fields["pc"], 16)
        sp = int(fields["sp"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("1983 emitted an invalid PC or SP") from error
    if not 0x0000 <= pc < 0x10000:
        raise ValueError(f"PC {pc:04X} is outside the primary slot")
    # The cartridge scan runs on the extension stack (F092h), so a
    # non-returning INIT is sampled with SP in that region rather than the
    # main stack top (F380h). Accept either RainBIOS page-3 stack region.
    if not 0xF080 <= sp <= 0xF380:
        raise ValueError(f"SP {sp:04X} is outside RainBIOS page-3 stacks")
    if fields.get("slot") != expected_slot:
        raise ValueError(
            f"slot: found {fields.get('slot')!r}, expected {expected_slot!r}"
        )
    if int(fields.get("vram_nonzero", "0")) <= 0:
        raise ValueError("1983 reported blank VRAM")
    for register, expected in (
        ("vdp_r0", expected_vdp_r0),
        ("vdp_r1", expected_vdp_r1),
    ):
        if expected is not None and fields.get(register) != expected:
            raise ValueError(
                f"{register}: found {fields.get(register)!r}, expected {expected!r}"
            )
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--cartridge", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    parser.add_argument("--exit-after", type=int, default=180)
    parser.add_argument("--expected-slot", default="F4")
    parser.add_argument("--expected-vdp-r0")
    parser.add_argument("--expected-vdp-r1")
    parser.add_argument("--paste-text")
    parser.add_argument("--paste-at", type=int)
    parser.add_argument("--paste-repeat", type=int)
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
        str(arguments.exit_after),
        "--dump-state",
        "--screenshot",
        str(arguments.screenshot),
    ]
    for option, value in (
        ("--paste-text", arguments.paste_text),
        ("--paste-at", arguments.paste_at),
        ("--paste-repeat", arguments.paste_repeat),
    ):
        if value is not None:
            command.append(option)
            command.append(str(value))
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
        fields = validate_state(
            result.stdout,
            expected_slot=arguments.expected_slot,
            expected_vdp_r0=arguments.expected_vdp_r0,
            expected_vdp_r1=arguments.expected_vdp_r1,
        )
    except ValueError as error:
        print(f"error: invalid 1983 cartridge state: {error}", file=sys.stderr)
        return 1
    print(
        "validated 1983 primary cartridge boot: "
        f"PC={fields['pc']}, SP={fields['sp']}, slot={fields['slot']}, "
        f"VRAM nonzero={fields['vram_nonzero']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
