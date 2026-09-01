#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate that the Screen 1 menu pattern table carries the console font.

The font probe holds Space during startup, waits for the Screen 1 menu,
and dumps the pattern-table glyphs. This checker compares those glyphs against
the built boot_font.bin and confirms lowercase code points are distinct from
their uppercase counterparts.
"""

from __future__ import annotations

import argparse
import pathlib

FONT = pathlib.Path(__file__).resolve().parents[1] / "build" / "logo" / "boot_font.bin"

PROBED_CODES = (0x41, 0x42, 0x5A, 0x61, 0x62, 0x7A, 0x67, 0x70, 0x81, 0x82, 0x85, 0x98)


def validate_report(text: str, font: bytes) -> dict[int, bytes]:
    glyphs = {}
    for line in text.splitlines():
        code, separator, value = line.partition("=")
        if not separator:
            continue
        glyphs[int(code, 16)] = bytes(int(byte, 16) for byte in value.split(","))
    for code in PROBED_CODES:
        reported = glyphs.get(code)
        if reported != font[code * 8 : code * 8 + 8]:
            raise ValueError(
                f"glyph {code:02X}: pattern table {reported!r} != boot_font {font[code * 8 : code * 8 + 8]!r}"
            )
    for code in (0x61, 0x62, 0x7A):
        if glyphs[code] == glyphs[code - 0x20]:
            raise ValueError(f"glyph {code:02X} is not distinct from uppercase")
    return glyphs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        validate_report(arguments.report.read_text(encoding="utf-8"), FONT.read_bytes())
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(f"validated console font pattern table: {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
