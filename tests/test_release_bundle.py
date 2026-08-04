# SPDX-License-Identifier: BSD-3-Clause
"""Validate a produced RainBIOS release bundle."""

from __future__ import annotations

import hashlib
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"

PRODUCTION_ROMS = [
    "rainbios_msx1.rom",
    "rainbios_msx2.rom",
    "rainbios_msx2_sub.rom",
    "rainbios_nms8250_disk.rom",
]

TRACKED_TEXTS = [
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "components.json",
    "LICENSES/ZX0.txt",
    "LICENSES/BBCBASIC-Z80.txt",
    "LICENSES/BBCBASIC-MSX-BSD-3-Clause.txt",
    "LICENSES/CC0-1.0.txt",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def find_bundle() -> Path | None:
    releases = BUILD / "release"
    if not releases.is_dir():
        return None
    candidates = sorted(releases.iterdir(), reverse=True)
    return candidates[0] if candidates else None


class ReleaseBundleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.bundle = find_bundle()

    def test_bundle_exists(self):
        if self.bundle is None:
            self.skipTest("no release bundle produced; run `make release`")
        self.assertTrue(self.bundle.is_dir())

    def test_bundle_has_all_roms(self):
        if self.bundle is None:
            self.skipTest("no release bundle produced; run `make release`")
        for name in PRODUCTION_ROMS:
            with self.subTest(rom=name):
                self.assertTrue(
                    (self.bundle / name).is_file(),
                    f"bundle missing ROM: {name}",
                )

    def test_bundle_roms_match_build_outputs(self):
        if self.bundle is None:
            self.skipTest("no release bundle produced; run `make release`")
        for name in PRODUCTION_ROMS:
            with self.subTest(rom=name):
                build_rom = BUILD / name
                if not build_rom.is_file():
                    continue
                self.assertEqual(
                    sha256(build_rom),
                    sha256(self.bundle / name),
                    f"bundle ROM {name} differs from the build output",
                )

    def test_bundle_has_tracked_texts(self):
        if self.bundle is None:
            self.skipTest("no release bundle produced; run `make release`")
        for relative in TRACKED_TEXTS:
            with self.subTest(text=relative):
                self.assertTrue(
                    (self.bundle / relative).is_file(),
                    f"bundle missing tracked text: {relative}",
                )

    def test_bundle_sha256sums_are_consistent(self):
        if self.bundle is None:
            self.skipTest("no release bundle produced; run `make release`")
        checksums = self.bundle / "SHA256SUMS"
        self.assertTrue(checksums.is_file())
        for line in checksums.read_text().splitlines():
            digest, separator, name = line.partition("  ")
            self.assertTrue(separator, f"malformed line: {line!r}")
            self.assertIn(name, PRODUCTION_ROMS)
            self.assertEqual(sha256(self.bundle / name), digest)

    def test_bundle_has_release_notes(self):
        if self.bundle is None:
            self.skipTest("no release bundle produced; run `make release`")
        notes = self.bundle / "RELEASE-NOTES.md"
        self.assertTrue(notes.is_file())
        self.assertIn("RainBIOS", notes.read_text())


if __name__ == "__main__":
    unittest.main()
