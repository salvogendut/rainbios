# SPDX-License-Identifier: BSD-3-Clause

import unittest

from tools.check_boot_info_probe import validate_report
from tools.png_to_screen2 import build_font


FONT = build_font()


def encode_row(text: str) -> str:
    padded = text.ljust(14)
    return b"".join(
        FONT[ord(character) * 8 : (ord(character) + 1) * 8]
        for character in padded
    ).hex()


def make_report(
    ram: str = "RAM     512 KB",
    vram: str = "VRAM    128 KB",
    date: str = "DATE 02/09/26",
    time: str = "TIME 12:34:56",
    mapper: str = "20",
    mode: str = "04",
) -> str:
    return "\n".join(
        (
            f"RAM={encode_row(ram)}",
            f"VRAM={encode_row(vram)}",
            f"DATE={encode_row(date)}",
            f"TIME={encode_row(time)}",
            f"MAPPER={mapper}",
            f"MODE={mode}",
        )
    )


class BootInfoProbeTests(unittest.TestCase):
    def test_accepts_ram_vram_and_rtc_text(self):
        values = validate_report(make_report(), FONT, 512, 128, True)
        self.assertEqual(values["date"], "DATE 02/09/26")
        self.assertEqual(values["time"], "TIME 12:34:56")

    def test_accepts_msx1_without_rtc_text(self):
        report = make_report(
            ram="RAM      64 KB",
            vram="VRAM     16 KB",
            date="",
            time="",
            mapper="01",
            mode="00",
        )
        values = validate_report(report, FONT, 64, 16, False)
        self.assertEqual(values["ram"], "RAM      64 KB")

    def test_rejects_wrong_memory_text(self):
        with self.assertRaisesRegex(ValueError, "RAM line"):
            validate_report(
                make_report(ram="RAM     256 KB"), FONT, 512, 128, True
            )

    def test_rejects_rtc_text_when_rtc_is_absent(self):
        with self.assertRaisesRegex(ValueError, "without a usable RTC"):
            validate_report(make_report(), FONT, 512, 128, False)

    def test_rejects_wrong_vram_mode_marker(self):
        with self.assertRaisesRegex(ValueError, "MODE"):
            validate_report(make_report(mode="02"), FONT, 512, 128, True)


if __name__ == "__main__":
    unittest.main()
