#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Run the WD2793 fault-injection cartridge in openMSX with a Tcl test double.

The cartridge redirects the shared read-only driver to a RAM controller
double; tests/openmsx/disk_fault_probe.tcl reacts to each command write and
programs the registers the driver reads next. This runner extracts the pass
label address from the cartridge symbols, runs openMSX, and requires the probe
report to show the cartridge reached disk_fault_pass.
"""

from __future__ import annotations

import argparse
import os
import pathlib
import re
import shlex
import subprocess
import sys

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


def label_for_pc(symbols: dict[str, int], pc: int) -> str:
    for label, address in symbols.items():
        if address == pc:
            return label
    return "unknown"


def validate_report(
    text: str, symbols: dict[str, int], expected_pass: int
) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if not separator:
            continue
        fields[key] = value
    status = fields.get("STATUS")
    if status != "PASS":
        label = fields.get("LABEL", "")
        detail = f" at {label}" if label else ""
        raise ValueError(f"disk fault probe reported {status!r}{detail}")
    try:
        pc = int(fields["PC"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("disk fault probe emitted an invalid PC") from error
    if pc != expected_pass:
        reached = label_for_pc(symbols, pc)
        raise ValueError(
            f"disk fault stopped at {reached} ({pc:04X}), expected "
            f"disk_fault_pass ({expected_pass:04X})"
        )
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--openmsx", required=True)
    parser.add_argument("--home", type=pathlib.Path, required=True)
    parser.add_argument("--user-data", type=pathlib.Path, required=True)
    parser.add_argument("--machine", required=True)
    parser.add_argument("--script", type=pathlib.Path, required=True)
    parser.add_argument("--symbols", type=pathlib.Path, required=True)
    parser.add_argument("--report", type=pathlib.Path, required=True)
    parser.add_argument("--pass-label", default="disk_fault_pass")
    arguments = parser.parse_args()

    symbols = parse_symbols(arguments.symbols)
    pass_label = arguments.pass_label.lower()
    expected_pass = symbols.get(pass_label)
    if expected_pass is None:
        print(f"error: missing required symbol {arguments.pass_label!r}",
              file=sys.stderr)
        return 1

    env = dict(os.environ)
    env["OPENMSX_HOME"] = str(arguments.home)
    env["OPENMSX_USER_DATA"] = str(arguments.user_data)
    fails = [
        f"{label}={address:#x}"
        for label, address in symbols.items()
        if label.startswith("disk_fault_fail_")
    ]
    wrapper = arguments.report.with_suffix(".wrap.tcl")
    wrapper.write_text(
        f"set disk_fault_output {{{arguments.report.resolve()}}}\n"
        f"set disk_fault_pass {{0x{expected_pass:X}}}\n"
        f"set disk_fault_fails {{{' '.join(fails)}}}\n"
        f"source {arguments.script.resolve()}\n",
        encoding="utf-8",
    )
    command = shlex.split(arguments.openmsx) + [
        "-machine",
        arguments.machine,
        "-script",
        str(wrapper),
    ]
    result = subprocess.run(
        command,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    sys.stdout.write(result.stdout)
    if not arguments.report.exists():
        print("error: openMSX did not produce the disk fault report",
              file=sys.stderr)
        return 1
    try:
        fields = validate_report(
            arguments.report.read_text(encoding="utf-8"),
            symbols,
            expected_pass,
        )
    except ValueError as error:
        print(f"error: invalid openMSX disk fault state: {error}",
              file=sys.stderr)
        return 1
    print(
        f"validated openMSX disk fault cartridge: PC={fields['PC']}, "
        f"slot={fields['SLOT']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
