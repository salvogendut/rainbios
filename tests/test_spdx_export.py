# SPDX-License-Identifier: BSD-3-Clause
"""Validate the generated SPDX 2.3 JSON document against the manifest and the
built ROMs."""

from __future__ import annotations

import hashlib
import json
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


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def find_bundle() -> Path | None:
    releases = BUILD / "release"
    if not releases.is_dir():
        return None
    candidates = [
        entry
        for entry in releases.iterdir()
        if entry.is_dir() and (entry / "rainbios.spdx.json").is_file()
    ]
    if not candidates:
        return None
    return sorted(candidates, reverse=True)[0]


class SpdxExportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ROOT / "components.json").read_text())
        bundle = find_bundle()
        cls.spdx = None
        if bundle is not None:
            cls.spdx = json.loads(
                (bundle / "rainbios.spdx.json").read_text()
            )

    def test_document_is_spdx_2_3(self):
        if self.spdx is None:
            self.skipTest("SPDX document not produced")
        self.assertEqual(self.spdx["spdxVersion"], "SPDX-2.3")
        self.assertEqual(self.spdx["dataLicense"], "CC0-1.0")
        self.assertTrue(self.spdx["documentNamespace"].startswith("https://"))

    def test_packages_match_manifest(self):
        if self.spdx is None:
            self.skipTest("SPDX document not produced")
        manifest_names = {c["name"] for c in self.manifest["components"]}
        package_names = {p["name"] for p in self.spdx["packages"]}
        self.assertEqual(package_names, manifest_names)

    def test_external_packages_pin_download(self):
        if self.spdx is None:
            self.skipTest("SPDX document not produced")
        for component, package in zip(
            self.manifest["components"], self.spdx["packages"]
        ):
            if component.get("source_identity"):
                self.assertNotEqual(
                    package["downloadLocation"], "NOASSERTION"
                )

    def test_files_cover_roms(self):
        if self.spdx is None:
            self.skipTest("SPDX document not produced")
        file_names = {f["fileName"] for f in self.spdx["files"]}
        self.assertEqual(file_names, set(PRODUCTION_ROMS))

    def test_file_checksums_match_build(self):
        if self.spdx is None:
            self.skipTest("SPDX document not produced")
        for entry in self.spdx["files"]:
            rom = BUILD / entry["fileName"]
            if not rom.is_file():
                continue
            with self.subTest(rom=entry["fileName"]):
                digest = entry["checksums"][0]["checksumValue"]
                self.assertEqual(sha256(rom), digest)

    def test_relationships_describe_every_element(self):
        if self.spdx is None:
            self.skipTest("SPDX document not produced")
        described = {
            rel["relatedSpdxElement"]
            for rel in self.spdx["relationships"]
            if rel["relationshipType"] == "DESCRIBES"
        }
        elements = (
            {p["SPDXID"] for p in self.spdx["packages"]}
            | {f["SPDXID"] for f in self.spdx["files"]}
        )
        self.assertEqual(described, elements)


if __name__ == "__main__":
    unittest.main()
