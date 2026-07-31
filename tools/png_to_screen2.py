#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Build the RainBIOS MSX1 boot-screen and early text-console assets."""

from __future__ import annotations

import argparse
from functools import lru_cache
import hashlib
import json
from pathlib import Path
from typing import Iterable

from PIL import Image


WIDTH = 256
HEIGHT = 192
PATTERN_SIZE = 6144
COLOR_SIZE = 6144
NAME_SIZE = 768
FONT_SIZE = 2048
SCREEN1_COLOR_SIZE = 32

BOOT_NOTICE = "PRESS SPACE TO SEE OPTIONS"
BOOT_NOTICE_BOX = (40, 176, 216, 192)
BOOT_NOTICE_Y = 180

# Original project 5x7 bitmap alphabet. Each integer is one five-pixel row.
# Uppercase letters use all seven rows. Lowercase letters use an x-height
# body in rows 2-6, ascenders rising to row 1, and descenders (g, j, p, q, y)
# carrying an eighth row. Generated font data is therefore BSD-3-Clause, while
# the logo image and its converted Graphics II tables remain CC0-1.0.
GLYPHS_5X7 = {
    " ": (0, 0, 0, 0, 0, 0, 0),
    "!": (0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0, 0b00100),
    '"': (0b01010, 0b01010, 0b01010, 0, 0, 0, 0),
    "#": (0b01010, 0b11111, 0b01010, 0b01010, 0b11111, 0b01010, 0),
    "$": (0b00100, 0b01111, 0b10100, 0b01110, 0b00101, 0b11110, 0b00100),
    "%": (0b11001, 0b11010, 0b00100, 0b01000, 0b10110, 0b10011, 0),
    "&": (0b01100, 0b10010, 0b10100, 0b01000, 0b10101, 0b10010, 0b01101),
    "'": (0b00100, 0b00100, 0b01000, 0, 0, 0, 0),
    "(": (0b00010, 0b00100, 0b01000, 0b01000, 0b01000, 0b00100, 0b00010),
    ")": (0b01000, 0b00100, 0b00010, 0b00010, 0b00010, 0b00100, 0b01000),
    "*": (0, 0b10101, 0b01110, 0b11111, 0b01110, 0b10101, 0),
    "+": (0, 0b00100, 0b00100, 0b11111, 0b00100, 0b00100, 0),
    ",": (0, 0, 0, 0, 0b00110, 0b00100, 0b01000),
    "-": (0, 0, 0, 0b11111, 0, 0, 0),
    ".": (0, 0, 0, 0, 0, 0b01100, 0b01100),
    "/": (0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0, 0),
    ":": (0, 0b01100, 0b01100, 0, 0b01100, 0b01100, 0),
    "0": (0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110),
    "1": (0b00100, 0b01100, 0b10100, 0b00100, 0b00100, 0b00100, 0b11111),
    "2": (0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111),
    "3": (0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110),
    "4": (0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010),
    "5": (0b11111, 0b10000, 0b10000, 0b11110, 0b00001, 0b00001, 0b11110),
    "6": (0b01110, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110),
    "7": (0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000),
    "8": (0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110),
    "9": (0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00001, 0b01110),
    ";": (0, 0b01100, 0b01100, 0, 0b00110, 0b00100, 0b01000),
    "<": (0b00010, 0b00100, 0b01000, 0b10000, 0b01000, 0b00100, 0b00010),
    "=": (0, 0b11111, 0, 0b11111, 0, 0, 0),
    ">": (0b01000, 0b00100, 0b00010, 0b00001, 0b00010, 0b00100, 0b01000),
    "?": (0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0, 0b00100),
    "@": (0b01110, 0b10001, 0b10111, 0b10101, 0b10111, 0b10000, 0b01110),
    "A": (0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001),
    "B": (0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110),
    "C": (0b01111, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b01111),
    "D": (0b11110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11110),
    "E": (0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111),
    "F": (0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000),
    "G": (0b01111, 0b10000, 0b10000, 0b10111, 0b10001, 0b10001, 0b01110),
    "H": (0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001),
    "I": (0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b11111),
    "J": (0b00111, 0b00010, 0b00010, 0b00010, 0b10010, 0b10010, 0b01100),
    "K": (0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001),
    "L": (0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111),
    "M": (0b10001, 0b11011, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001),
    "N": (0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001),
    "O": (0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110),
    "P": (0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000),
    "Q": (0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101),
    "R": (0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001),
    "S": (0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110),
    "T": (0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100),
    "U": (0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110),
    "V": (0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100),
    "W": (0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b10101, 0b01010),
    "X": (0b10001, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001, 0b10001),
    "Y": (0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100),
    "Z": (0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b11111),
    "a": (0, 0, 0b01110, 0b00001, 0b01111, 0b10001, 0b01111),
    "b": (0, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b11110),
    "c": (0, 0, 0b01110, 0b10000, 0b10000, 0b10000, 0b01110),
    "d": (0, 0b00001, 0b00001, 0b01111, 0b10001, 0b10001, 0b01111),
    "e": (0, 0, 0b01110, 0b10001, 0b11111, 0b10000, 0b01110),
    "f": (0, 0b00110, 0b01000, 0b11110, 0b01000, 0b01000, 0b01000),
    "g": (0, 0, 0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b01110),
    "h": (0, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b10001),
    "i": (0b00100, 0, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100),
    "j": (0b00100, 0, 0b00100, 0b00100, 0b00100, 0b00100, 0b01100, 0b11100),
    "k": (0, 0b10000, 0b10000, 0b10010, 0b11000, 0b10100, 0b10010),
    "l": (0, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100),
    "m": (0, 0, 0b01010, 0b10101, 0b10101, 0b10001, 0b10001),
    "n": (0, 0, 0b11110, 0b10001, 0b10001, 0b10001, 0b10001),
    "o": (0, 0, 0b01110, 0b10001, 0b10001, 0b10001, 0b01110),
    "p": (0, 0, 0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000),
    "q": (0, 0, 0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00011),
    "r": (0, 0, 0b11110, 0b10001, 0b10000, 0b10000, 0b10000),
    "s": (0, 0, 0b01111, 0b10000, 0b01110, 0b00001, 0b11110),
    "t": (0, 0b00100, 0b01110, 0b00100, 0b00100, 0b00100, 0b00100),
    "u": (0, 0, 0b10001, 0b10001, 0b10001, 0b10001, 0b01111),
    "v": (0, 0, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100),
    "w": (0, 0, 0b10001, 0b10001, 0b10101, 0b10101, 0b01010),
    "x": (0, 0, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001),
    "y": (0, 0, 0b10001, 0b10001, 0b01010, 0b00100, 0b01000, 0b10000),
    "z": (0, 0, 0b11111, 0b00010, 0b00100, 0b01000, 0b11111),
    "[": (0b01110, 0b01000, 0b01000, 0b01000, 0b01000, 0b01000, 0b01110),
    "\\": (0b10000, 0b01000, 0b00100, 0b00010, 0b00001, 0, 0),
    "]": (0b01110, 0b00010, 0b00010, 0b00010, 0b00010, 0b00010, 0b01110),
    "^": (0b00100, 0b01010, 0b10001, 0, 0, 0, 0),
    "_": (0, 0, 0, 0, 0, 0, 0b11111),
    "`": (0b01000, 0b00100, 0b00010, 0, 0, 0, 0),
    "{": (0b00010, 0b00100, 0b00100, 0b01000, 0b00100, 0b00100, 0b00010),
    "|": (0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100),
    "}": (0b01000, 0b00100, 0b00100, 0b00010, 0b00100, 0b00100, 0b01000),
    "~": (0, 0b01001, 0b10110, 0, 0, 0, 0),
}

OPTIONS_LINES = {
    2: "RAINBIOS BOOT MENU",
    5: "1  START BBC BASIC",
    7: "PRESS 1 TO LAUNCH",
    10: "BBC BASIC PAYLOAD READY",
    13: "STARTUP JINGLE       ON",
    14: "VIDEO              NTSC",
    17: "PRIMARY RAM AND STACK READY",
    18: "PRIMARY SLOT CALLS READY",
    19: "PRIMARY CART INIT READY",
    20: "EXPANDED SLOTS PENDING",
    22: "RESET TO RETURN",
}

OPTIONS_LINES_MISSING = {
    **OPTIONS_LINES,
    5: "1  BBC BASIC UNAVAILABLE",
    7: "ATTACH PAYLOAD AND RESET",
    10: "NO VALID BASIC PAYLOAD",
}

# A commonly used nominal TMS9918 palette. Color 0 is transparent and is not
# selected by this converter; color 1 supplies opaque black.
TMS9918_PALETTE = (
    (0x00, 0x00, 0x00),  # 0 transparent
    (0x00, 0x00, 0x00),  # 1 black
    (0x21, 0xC8, 0x42),  # 2 medium green
    (0x5E, 0xDC, 0x78),  # 3 light green
    (0x54, 0x55, 0xED),  # 4 dark blue
    (0x7D, 0x76, 0xFC),  # 5 light blue
    (0xD4, 0x52, 0x4D),  # 6 dark red
    (0x42, 0xEB, 0xF5),  # 7 cyan
    (0xFC, 0x55, 0x54),  # 8 medium red
    (0xFF, 0x79, 0x78),  # 9 light red
    (0xD4, 0xC1, 0x54),  # 10 dark yellow
    (0xE6, 0xCE, 0x80),  # 11 light yellow
    (0x21, 0xB0, 0x3B),  # 12 dark green
    (0xC9, 0x5B, 0xBA),  # 13 magenta
    (0xCC, 0xCC, 0xCC),  # 14 gray
    (0xFF, 0xFF, 0xFF),  # 15 white
)


@lru_cache(maxsize=None)
def rgb_to_lab_fixed(rgb: tuple[int, int, int]) -> tuple[int, int, int]:
    """Convert sRGB to D65 CIE Lab, scaled by 1024 for stable comparisons."""

    linear = []
    for component in rgb:
        normalized = component / 255.0
        linear.append(
            normalized / 12.92
            if normalized <= 0.04045
            else ((normalized + 0.055) / 1.055) ** 2.4
        )
    red, green, blue = linear
    x = (red * 0.4124564 + green * 0.3575761 + blue * 0.1804375) / 0.95047
    y = red * 0.2126729 + green * 0.7151522 + blue * 0.0721750
    z = (red * 0.0193339 + green * 0.1191920 + blue * 0.9503041) / 1.08883

    def lab_curve(value: float) -> float:
        return (
            value ** (1.0 / 3.0)
            if value > 0.008856
            else 7.787 * value + 16.0 / 116.0
        )

    fx = lab_curve(x)
    fy = lab_curve(y)
    fz = lab_curve(z)
    return (
        round((116.0 * fy - 16.0) * 1024),
        round(500.0 * (fx - fy) * 1024),
        round(200.0 * (fy - fz) * 1024),
    )


def rgb_distance(left: tuple[int, int, int], right: tuple[int, int, int]) -> int:
    """Return a deterministic fixed-point CIE76 squared distance."""

    left_lab = rgb_to_lab_fixed(left)
    right_lab = rgb_to_lab_fixed(right)
    return sum(
        (left_component - right_component) ** 2
        for left_component, right_component in zip(left_lab, right_lab)
    )


def rgb_pixels(image: Image.Image) -> list[tuple[int, int, int]]:
    rgb_data = image.convert("RGB").tobytes()
    return list(zip(rgb_data[0::3], rgb_data[1::3], rgb_data[2::3]))


def draw_text_5x7(
    image: Image.Image,
    text: str,
    x: int,
    y: int,
    color: tuple[int, int, int],
) -> None:
    """Draw project-owned 5x7 text into an RGB image."""

    for character in text:
        try:
            rows = GLYPHS_5X7[character]
        except KeyError as error:
            raise ValueError(f"no 5x7 glyph for {character!r}") from error
        for row_index, row_bits in enumerate(rows):
            for column in range(5):
                if row_bits & (1 << (4 - column)):
                    image.putpixel((x + column, y + row_index), color)
        x += 6


def add_boot_notice(image: Image.Image) -> Image.Image:
    """Return a copy with the Space-key prompt in an aligned two-color box."""

    rendered = image.convert("RGB")
    left, top, right, bottom = BOOT_NOTICE_BOX
    black = TMS9918_PALETTE[1]
    for y in range(top, bottom):
        for x in range(left, right):
            rendered.putpixel((x, y), black)
    text_width = len(BOOT_NOTICE) * 6 - 1
    draw_text_5x7(
        rendered,
        BOOT_NOTICE,
        (WIDTH - text_width) // 2,
        BOOT_NOTICE_Y,
        TMS9918_PALETTE[15],
    )
    return rendered


def build_font() -> bytes:
    """Build a 256-character 8x8 font from the project-owned glyphs."""

    font = bytearray(FONT_SIZE)
    for character, rows in GLYPHS_5X7.items():
        offset = ord(character) * 8
        for row_index, row_bits in enumerate(rows):
            font[offset + row_index] = row_bits << 2
    return bytes(font)


def build_options_name(lines: dict[int, str]) -> bytes:
    """Build one fixed 32x24 early-boot options screen."""

    name = bytearray(b" " * NAME_SIZE)
    for row, text in lines.items():
        if len(text) > 32:
            raise ValueError(f"options line {row} exceeds 32 columns")
        column = (32 - len(text)) // 2
        offset = row * 32 + column
        name[offset : offset + len(text)] = text.encode("ascii")
    return bytes(name)


def screen2_offset(cell_x: int, y: int) -> int:
    """Map an 8-pixel cell scanline to a Graphics II pattern/color offset."""

    third = y // 64
    row_in_third = (y % 64) // 8
    line_in_cell = y % 8
    character = row_in_third * 32 + cell_x
    return third * 2048 + character * 8 + line_in_cell


def _distances_for(
    pixels: Iterable[tuple[int, int, int]],
) -> dict[tuple[int, int, int], tuple[int, ...]]:
    return {
        pixel: tuple(
            rgb_distance(pixel, palette_color)
            for palette_color in TMS9918_PALETTE
        )
        for pixel in set(pixels)
    }


def encode_screen2(
    image: Image.Image,
) -> tuple[bytes, bytes, bytes, Image.Image, int]:
    """Encode an image and return pattern, color, name, preview, and error."""

    if image.size != (WIDTH, HEIGHT):
        raise ValueError(
            f"expected a {WIDTH}x{HEIGHT} image, got {image.width}x{image.height}"
        )

    pixels = rgb_pixels(image)
    distances = _distances_for(pixels)
    pattern = bytearray(PATTERN_SIZE)
    color = bytearray(COLOR_SIZE)
    preview_pixels = [(0, 0, 0)] * (WIDTH * HEIGHT)
    total_error = 0

    for y in range(HEIGHT):
        row_start = y * WIDTH
        for cell_x in range(32):
            pixel_start = row_start + cell_x * 8
            cell = pixels[pixel_start : pixel_start + 8]

            best_score: int | None = None
            best_background = 1
            best_foreground = 1
            for background in range(1, 16):
                for foreground in range(background, 16):
                    score = sum(
                        min(
                            distances[pixel][background],
                            distances[pixel][foreground],
                        )
                        for pixel in cell
                    )
                    if best_score is None or score < best_score:
                        best_score = score
                        best_background = background
                        best_foreground = foreground

            bits = 0
            selected = []
            for pixel in cell:
                bits <<= 1
                if (
                    distances[pixel][best_foreground]
                    < distances[pixel][best_background]
                ):
                    bits |= 1
                    selected.append(best_foreground)
                else:
                    selected.append(best_background)

            # Normalize one-color cells so the unused pattern plane cannot
            # expose a different color because of a corrupted bit.
            if bits == 0x00:
                best_foreground = best_background
            elif bits == 0xFF:
                best_background = best_foreground
                bits = 0x00
                selected = [best_foreground] * 8

            offset = screen2_offset(cell_x, y)
            pattern[offset] = bits
            color[offset] = (best_foreground << 4) | best_background

            for index, palette_index in enumerate(selected):
                source_pixel = cell[index]
                output_pixel = TMS9918_PALETTE[palette_index]
                preview_pixels[pixel_start + index] = output_pixel
                total_error += rgb_distance(source_pixel, output_pixel)

    name = bytes(range(256)) * 3
    preview = Image.new("RGB", (WIDTH, HEIGHT))
    preview.putdata(preview_pixels)
    return bytes(pattern), bytes(color), name, preview, total_error


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def convert(source: Path, output_dir: Path) -> None:
    source_bytes = source.read_bytes()
    with Image.open(source) as image:
        source_color_count = len(set(rgb_pixels(image)))
        boot_image = add_boot_notice(image)
        pattern, color, name, preview, total_error = encode_screen2(boot_image)

    output_dir.mkdir(parents=True, exist_ok=True)
    outputs = {
        "logo_pattern.bin": pattern,
        "logo_color.bin": color,
        "logo_name.bin": name,
        "boot_font.bin": build_font(),
        "options_name_ready.bin": build_options_name(OPTIONS_LINES),
        "options_name_missing.bin": build_options_name(OPTIONS_LINES_MISSING),
        "options_color.bin": bytes((0xF4,)) * SCREEN1_COLOR_SIZE,
    }
    for filename, data in outputs.items():
        (output_dir / filename).write_bytes(data)
    preview.save(output_dir / "logo_preview.png", optimize=False)

    manifest = {
        "format": "TMS9918 Graphics II",
        "source": source.name,
        "source_sha256": sha256(source_bytes),
        "source_size": [WIDTH, HEIGHT],
        "source_rgb_colors": source_color_count,
        "boot_notice": {
            "text": BOOT_NOTICE,
            "box": list(BOOT_NOTICE_BOX),
            "text_y": BOOT_NOTICE_Y,
        },
        "palette": [list(color_value) for color_value in TMS9918_PALETTE],
        "opaque_palette_indices": list(range(1, 16)),
        "weighted_squared_error_total": total_error,
        "weighted_squared_error_mean": total_error / (WIDTH * HEIGHT),
        "outputs": {
            filename: {"bytes": len(data), "sha256": sha256(data)}
            for filename, data in outputs.items()
        },
    }
    (output_dir / "logo_manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="256x192 source PNG")
    parser.add_argument("output_dir", type=Path, help="generated-data directory")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    convert(args.source, args.output_dir)


if __name__ == "__main__":
    main()
