# SPDX-License-Identifier: BSD-3-Clause

import hashlib
import json
from pathlib import Path
import unittest

from PIL import Image

from tools.png_to_screen2 import (
    BOOT_NOTICE,
    BOOT_NOTICE_BOX,
    COLOR_SIZE,
    FONT_SIZE,
    NAME_SIZE,
    OPTIONS_LINES,
    OPTIONS_LINES_MISSING,
    PATTERN_SIZE,
    SCREEN1_COLOR_SIZE,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src" / "logo-simple.png"
OUTPUT = ROOT / "build" / "logo"


class LogoConversionTest(unittest.TestCase):
    def test_source_contains_an_msx1_raster(self):
        with Image.open(SOURCE) as image:
            self.assertEqual(image.size, (295, 192))

    def test_graphics_ii_output_sizes(self):
        self.assertEqual((OUTPUT / "logo_pattern.bin").stat().st_size, PATTERN_SIZE)
        self.assertEqual((OUTPUT / "logo_color.bin").stat().st_size, COLOR_SIZE)
        self.assertEqual((OUTPUT / "logo_name.bin").stat().st_size, NAME_SIZE)

    def test_early_text_assets_have_expected_sizes(self):
        self.assertEqual((OUTPUT / "boot_font.bin").stat().st_size, FONT_SIZE)
        self.assertEqual(
            (OUTPUT / "options_name_ready.bin").stat().st_size,
            NAME_SIZE,
        )
        self.assertEqual(
            (OUTPUT / "options_name_missing.bin").stat().st_size,
            NAME_SIZE,
        )
        self.assertEqual(
            (OUTPUT / "options_color.bin").stat().st_size,
            SCREEN1_COLOR_SIZE,
        )

    def test_lowercase_letters_have_distinct_readable_glyphs(self):
        font = (OUTPUT / "boot_font.bin").read_bytes()
        for uppercase in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            lowercase = uppercase.lower()
            with self.subTest(lowercase=lowercase):
                self.assertNotEqual(
                    font[ord(lowercase) * 8 : (ord(lowercase) + 1) * 8],
                    font[ord(uppercase) * 8 : (ord(uppercase) + 1) * 8],
                )
                self.assertNotEqual(
                    font[ord(lowercase) * 8 : (ord(lowercase) + 1) * 8],
                    bytes(8),
                )

    def test_printable_ascii_has_a_visible_glyph(self):
        font = (OUTPUT / "boot_font.bin").read_bytes()
        for character in (chr(code) for code in range(0x21, 0x7F)):
            with self.subTest(character=character):
                self.assertNotEqual(
                    font[ord(character) * 8 : (ord(character) + 1) * 8],
                    bytes(8),
                )

    def test_name_table_selects_all_patterns_in_each_screen_third(self):
        expected = bytes(range(256)) * 3
        self.assertEqual((OUTPUT / "logo_name.bin").read_bytes(), expected)

    def test_color_table_uses_only_opaque_palette_entries(self):
        for value in (OUTPUT / "logo_color.bin").read_bytes():
            self.assertIn(value >> 4, range(1, 16))
            self.assertIn(value & 0x0F, range(1, 16))

    def test_manifest_identifies_the_exact_source_asset(self):
        manifest = json.loads((OUTPUT / "logo_manifest.json").read_text())
        self.assertEqual(BOOT_NOTICE, "RainBIOS booting...")
        self.assertEqual(
            manifest["source_sha256"],
            hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        )
        self.assertEqual(manifest["source_size"], [295, 192])
        self.assertEqual(manifest["source_crop"], [0, 0, 256, 192])
        self.assertEqual(manifest["raster_size"], [256, 192])
        self.assertGreater(manifest["source_rgb_colors"], 16)
        self.assertEqual(manifest["boot_notice"]["text"], BOOT_NOTICE)
        self.assertEqual(manifest["boot_notice"]["box"], list(BOOT_NOTICE_BOX))

    def test_preview_is_an_msx_sized_rgb_png(self):
        with Image.open(OUTPUT / "logo_preview.png") as preview:
            self.assertEqual(preview.size, (256, 192))
            self.assertEqual(preview.mode, "RGB")
            colors = preview.getcolors(maxcolors=256)
            self.assertIsNotNone(colors)
            self.assertLessEqual(len(colors), 15)
            left, top, right, bottom = BOOT_NOTICE_BOX
            notice_colors = set(
                preview.crop((left, top, right, bottom)).get_flattened_data()
            )
            self.assertEqual(notice_colors, {(0, 0, 0), (255, 255, 255)})

    def test_options_name_table_contains_all_documented_lines(self):
        for filename, lines in (
            ("options_name_ready.bin", OPTIONS_LINES),
            ("options_name_missing.bin", OPTIONS_LINES_MISSING),
        ):
            name = (OUTPUT / filename).read_bytes()
            for row, text in lines.items():
                with self.subTest(filename=filename, row=row, text=text):
                    self.assertIn(
                        text.encode("ascii"),
                        name[row * 32 : (row + 1) * 32],
                    )

    def test_converted_tables_are_embedded_in_the_main_rom(self):
        rom = (ROOT / "build" / "rainbios_msx1.rom").read_bytes()
        self.assertIn((OUTPUT / "boot_font.bin").read_bytes(), rom)
        for filename in (
            "logo_pattern.zx0",
            "logo_name.zx0",
            "logo_color.zx0",
            "options_name_ready.zx0",
            "options_name_missing.zx0",
            "options_color.zx0",
        ):
            with self.subTest(filename=filename):
                self.assertIn((OUTPUT / filename).read_bytes(), rom)


if __name__ == "__main__":
    unittest.main()
