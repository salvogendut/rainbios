#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot GeoBench through Sunrise IDE or SD Mapper V2 in 1983."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

try:
    from tools.check_geobench import validate_screenshot, validate_state
    from tools.run_1983_m1 import parse_state
except ModuleNotFoundError:
    from check_geobench import validate_screenshot, validate_state
    from run_1983_m1 import parse_state


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--model", default="nms8250")
    parser.add_argument("--region", default="pal")
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--subrom", type=pathlib.Path, required=True)
    controller = parser.add_mutually_exclusive_group(required=True)
    controller.add_argument("--sunrise-rom", type=pathlib.Path)
    controller.add_argument("--sd-mapper-rom", type=pathlib.Path)
    parser.add_argument("--image", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    parser.add_argument("--exit-after", type=int, default=2502)
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
        "--subrom",
        str(arguments.subrom),
        "--disk-rom",
        "",
        "--headless",
        "--unthrottled",
        "--exit-after",
        str(arguments.exit_after),
        "--dump-state",
        "--dump-ram",
        "0xFCAF:1",
        "--screenshot",
        str(arguments.screenshot),
    ]
    if arguments.sunrise_rom:
        command.extend(
            [
                "--sunrise-rom",
                str(arguments.sunrise_rom),
                "--ide",
                str(arguments.image),
                "--ide-mode",
                "read-only",
            ]
        )
    else:
        command.extend(
            [
                "--sd-mapper-rom",
                str(arguments.sd_mapper_rom),
                "--sd-a",
                str(arguments.image),
                "--sd-mode",
                "read-only",
            ]
        )

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
        state = parse_state(result.stdout)
        scrmod_match = re.search(r"^FCAF:\s+([0-9A-Fa-f]{2})$", result.stdout, re.MULTILINE)
        if scrmod_match is None:
            raise ValueError("1983 did not report SCRMOD")
        fields = {
            "VDP_R0": state["vdp_r0"],
            "VDP_R1": state["vdp_r1"],
            "SCRMOD": scrmod_match.group(1),
            "MAPPER": state["mapper"],
        }
        validate_state(fields)
        if int(state.get("vram_nonzero", "0")) <= 0:
            raise ValueError("1983 reported blank VRAM")
        validate_screenshot(arguments.screenshot)
    except (KeyError, ValueError, OSError) as error:
        print(f"error: invalid 1983 GeoBench result: {error}", file=sys.stderr)
        return 1

    controller = "Sunrise IDE" if arguments.sunrise_rom else "SD Mapper V2"
    print(
        f"validated 1983 GeoBench through {controller}: "
        f"R0={fields['VDP_R0']}, R1={fields['VDP_R1']}, "
        f"mapper={fields['MAPPER']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
