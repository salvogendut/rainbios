#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the runtime RAM/VRAM/RTC text drawn over the boot logo."""

from __future__ import annotations

import argparse
import pathlib
import re


def parse_report(text: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            fields[key] = value
    return fields


def glyph_map(font: bytes) -> dict[bytes, str]:
    if len(font) != 2048:
        raise ValueError(f"boot font is {len(font)} bytes, expected 2048")
    result: dict[bytes, str] = {}
    for code in range(0x20, 0x7F):
        pattern = font[code * 8 : (code + 1) * 8]
        result.setdefault(pattern, chr(code))
    return result


def decode_row(value: str, font: bytes, characters: int) -> str:
    try:
        patterns = bytes.fromhex(value)
    except ValueError as error:
        raise ValueError("boot row is not hexadecimal") from error
    expected = 14 * 8
    if len(patterns) != expected:
        raise ValueError(
            f"boot row is {len(patterns)} bytes, expected {expected}"
        )
    mapping = glyph_map(font)
    decoded = []
    for offset in range(0, characters * 8, 8):
        pattern = patterns[offset : offset + 8]
        decoded.append(mapping.get(pattern, "?"))
    return "".join(decoded)


def validate_report(
    text: str,
    font: bytes,
    expected_ram: int,
    expected_vram: int,
    expect_rtc: bool,
) -> dict[str, str]:
    fields = parse_report(text)
    required = {"RAM", "VRAM", "DATE", "TIME", "MAPPER", "MODE"}
    missing = required - fields.keys()
    if missing:
        raise ValueError(f"missing boot-info fields: {sorted(missing)}")

    ram = decode_row(fields["RAM"], font, 14)
    vram = decode_row(fields["VRAM"], font, 14)
    if ram.split() != ["RAM", str(expected_ram), "KB"]:
        raise ValueError(f"RAM line is {ram!r}")
    if vram.split() != ["VRAM", str(expected_vram), "KB"]:
        raise ValueError(f"VRAM line is {vram!r}")

    date = decode_row(fields["DATE"], font, 13)
    time = decode_row(fields["TIME"], font, 13)
    if expect_rtc:
        if date != "DATE 02/09/26":
            raise ValueError(f"RTC date line is {date!r}")
        if not re.fullmatch(r"TIME 12:34:5[6-7]", time):
            raise ValueError(f"RTC time line is {time!r}")
    elif date.startswith("DATE ") or time.startswith("TIME "):
        raise ValueError("RTC text was rendered without a usable RTC")

    expected_mode = {16: "00", 64: "02", 128: "04"}[expected_vram]
    if fields["MODE"] != expected_mode:
        raise ValueError(
            f"MODE is {fields['MODE']!r}, expected {expected_mode!r}"
        )
    expected_mapper = "01" if expected_ram == 64 else f"{expected_ram // 16:02X}"
    if fields["MAPPER"] != expected_mapper:
        raise ValueError(
            f"MAPPER is {fields['MAPPER']!r}, expected {expected_mapper!r}"
        )
    return {"ram": ram, "vram": vram, "date": date, "time": time}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("font", type=pathlib.Path)
    parser.add_argument("--ram", type=int, required=True)
    parser.add_argument("--vram", type=int, required=True)
    parser.add_argument("--rtc", action="store_true")
    arguments = parser.parse_args()

    try:
        values = validate_report(
            arguments.report.read_text(),
            arguments.font.read_bytes(),
            arguments.ram,
            arguments.vram,
            arguments.rtc,
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    rtc = f", {values['date']} {values['time']}" if arguments.rtc else ""
    print(f"validated boot info: {values['ram']}, {values['vram']}{rtc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
