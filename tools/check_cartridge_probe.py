#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the RainBIOS cartridge boot report and INIT entry state."""

from __future__ import annotations

import argparse
import pathlib


def _parse_bytes(value: str) -> list[int]:
    try:
        return [int(byte, 16) for byte in value.split(",")]
    except ValueError as error:
        raise ValueError(f"invalid byte list {value!r}") from error


def validate_report(
    text: str,
    expected_slot: str = "F4",
    expected_exptbl: str | None = None,
    expected_slttbl: str | None = None,
    expected_entry: int = 0x4010,
) -> dict[str, str]:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    try:
        pc = int(values["PC"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError("missing or invalid PC") from error
    # The sampled PC is the cartridge loop, in page 1 (0x4000) or page 2
    # (0x8000) depending on where the INIT entry lives.
    if not (0x4000 <= pc < 0x8000 or 0x8000 <= pc < 0xC000):
        raise ValueError(f"PC {pc:04X} is outside the cartridge pages")

    # Cartridge INIT entry contract (authoritative breakpoint capture):
    # A and B both carry the slot ID, C is zero, DE and IX are the INIT
    # pointer from the AB header, HL is the scan's header address, IY holds
    # the slot in the high byte, and SP is on a RainBIOS page-3 stack.
    try:
        entry_pc = int(values["ENTRYPC"], 16)
        a, f = _parse_bytes(values["ENTRYAF"])
        bc = int(values["ENTRYBC"], 16)
        de = int(values["ENTRYDE"], 16)
        hl = int(values["ENTRYHL"], 16)
        ix = int(values["ENTRYIX"], 16)
        iy = int(values["ENTRYIY"], 16)
        sp = int(values["ENTRYSP"], 16)
    except (KeyError, ValueError) as error:
        raise ValueError(f"missing or invalid ENTRY state: {error}") from error
    if entry_pc != expected_entry:
        raise ValueError(
            f"ENTRYPC {entry_pc:04X} must be the configured INIT entry "
            f"{expected_entry:04X}"
        )
    b, c = bc >> 8, bc & 0xFF
    if a != b:
        raise ValueError(f"A {a:02X} and B {b:02X} must both carry the slot ID")
    if c != 0:
        raise ValueError(f"C must be zero at INIT, found {c:02X}")
    if de != ix:
        raise ValueError(f"DE {de:04X} and IX {ix:04X} must both be the INIT pointer")
    if iy != (a << 8):
        raise ValueError(f"IY {iy:04X} must hold the slot ID in its high byte")
    if not 0xF060 <= sp <= 0xF380:
        raise ValueError(f"SP {sp:04X} is outside RainBIOS page-3 stacks")
    if hl != 0x4003:
        raise ValueError(f"HL {hl:04X} must be the scan header address (4003)")

    screen = _parse_bytes(values.get("ENTRYSCREEN", ""))
    expected_screen = [0x00, 0x28, 0x01, 0x01, 0xBC, 0x0B, 0x0C, 0x0C]
    if screen != expected_screen:
        raise ValueError(
            "ENTRYSCREEN must be cleared Screen 0 with yellow text on green: "
            f"found {screen!r}, expected {expected_screen!r}"
        )

    # The fixture's in-ROM snapshot must agree with the breakpoint capture,
    # proving the register values survive the transfer.
    pairs = (
        ("INITAF", [a, f]),
        ("INITBC", [b, c]),
        ("INITDE", [de >> 8, de & 0xFF]),
        ("INITHL", [hl >> 8, hl & 0xFF]),
        ("INITIX", [ix >> 8, ix & 0xFF]),
        ("INITIY", [iy >> 8, iy & 0xFF]),
        ("INITSP", [sp >> 8, sp & 0xFF]),
    )
    for key, expected in pairs:
        if _parse_bytes(values.get(key, "")) != expected:
            raise ValueError(
                f"{key}: fixture snapshot {values.get(key)!r} does not match "
                f"the breakpoint capture {expected!r}"
            )

    expected = {
        "SLOT": expected_slot,
        "SIGNATURE": "52,41,49,4E,5E",
    }
    if expected_exptbl is not None:
        expected["EXPTBL"] = expected_exptbl
    if expected_slttbl is not None:
        expected["SLTTBL"] = expected_slttbl
    for key, expected_value in expected.items():
        if values.get(key) != expected_value:
            raise ValueError(
                f"{key}: found {values.get(key)!r}, expected {expected_value!r}"
            )
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--expected-slot", default="F4")
    parser.add_argument("--expected-exptbl")
    parser.add_argument("--expected-slttbl")
    parser.add_argument("--expected-entry", type=lambda v: int(v, 16), default=0x4010)
    arguments = parser.parse_args()
    try:
        values = validate_report(
            arguments.report.read_text(encoding="utf-8"),
            arguments.expected_slot,
            arguments.expected_exptbl,
            arguments.expected_slttbl,
            arguments.expected_entry,
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(
        "validated cartridge boot: "
        f"PC={values['PC']}, SP={values['SP']}, slot={values['SLOT']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
