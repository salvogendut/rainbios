# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import hashlib
from pathlib import Path
import unittest

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = {
    "src/logo-simple.png": (
        (295, 192),
        "4487be3b3b0c5d2953668a645b5ee3796b55aac5fd121cf1977756b4eec6bd09",
    ),
    "rainbios.png": (
        (1448, 1086),
        "781810b02af6d79b2de26347bb73ba9c7249f7c3286ec1bde644b868e4587d5e",
    ),
    "screenshots/Screenshot From 2026-07-30 11-38-10.png": (
        (1280, 1000),
        "3cf8e6f5bfbd9bdfc3171cd35a7460f63cdff146768ffd5f28fffbf6622d7786",
    ),
    "screenshots/Screenshot From 2026-07-30 11-46-22.png": (
        (1280, 1000),
        "11030bfc57eb5cca1857e10b4a07e87bf98b1651d3087f73bd79f45aa4d2db73",
    ),
}


class DocumentationAssetTests(unittest.TestCase):
    def test_selected_assets_have_recorded_identity(self) -> None:
        for filename, (expected_size, expected_digest) in ASSETS.items():
            with self.subTest(filename=filename):
                path = ROOT / filename
                self.assertEqual(
                    hashlib.sha256(path.read_bytes()).hexdigest(),
                    expected_digest,
                )
                with Image.open(path) as image:
                    self.assertEqual(image.size, expected_size)

    def test_selected_assets_are_declared_cc0(self) -> None:
        for filename in ASSETS:
            with self.subTest(filename=filename):
                license_text = (ROOT / f"{filename}.license").read_text(
                    encoding="utf-8"
                )
                self.assertIn("SPDX-License-Identifier: CC0-1.0", license_text)


if __name__ == "__main__":
    unittest.main()
