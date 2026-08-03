# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "tools"))

from png_to_screen2 import build_font  # noqa: E402


class FontGlyphTests(unittest.TestCase):
    def setUp(self) -> None:
        self.font = build_font()

    def glyph(self, code: int) -> bytes:
        return bytes(self.font[code * 8 : code * 8 + 8])

    def test_accented_glyphs_are_all_present(self) -> None:
        blank = [
            code for code in range(0x80, 0xA4)
            if not any(self.glyph(code))
        ]
        self.assertEqual(blank, [])

    def test_grave_a_glyph(self) -> None:
        self.assertEqual(
            self.glyph(0x85),
            bytes((0x04, 0x40, 0x38, 0x04, 0x3C, 0x44, 0x3C, 0x00)),
        )

    def test_acute_e_glyph(self) -> None:
        self.assertEqual(
            self.glyph(0x82),
            bytes((0x40, 0x04, 0x38, 0x44, 0x7C, 0x40, 0x38, 0x00)),
        )

    def test_umlaut_u_glyph(self) -> None:
        self.assertEqual(
            self.glyph(0x81),
            bytes((0x28, 0x00, 0x44, 0x44, 0x44, 0x44, 0x3C, 0x00)),
        )

    def test_cedilla_c_glyph(self) -> None:
        self.assertEqual(
            self.glyph(0x87),
            bytes((0x00, 0x00, 0x38, 0x40, 0x40, 0x40, 0x38, 0x10)),
        )

    def test_accented_glyph_is_distinct_from_plain_letter(self) -> None:
        for accented, plain in ((0x85, 0x61), (0x82, 0x65), (0x81, 0x75)):
            self.assertNotEqual(self.glyph(accented), self.glyph(plain))


if __name__ == "__main__":
    unittest.main()
