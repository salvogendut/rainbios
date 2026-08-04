# SPDX-License-Identifier: BSD-3-Clause
"""Validate the machine-readable component manifest."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import unittest


ROOT = Path(__file__).resolve().parents[1]


def load_manifest() -> dict:
    with (ROOT / "components.json").open(encoding="utf-8") as handle:
        return json.load(handle)


def load_lock() -> dict:
    with (ROOT / "deps" / "bbcbasic-z80-msx.lock.json").open(
        encoding="utf-8"
    ) as handle:
        return json.load(handle)


class ComponentManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = load_manifest()
        cls.lock = load_lock()

    def test_format_version(self) -> None:
        self.assertEqual(self.manifest["format_version"], 1)

    def test_product_artifacts_exist(self) -> None:
        for name, relative in self.manifest["product"]["artifacts"].items():
            self.assertTrue(
                (ROOT / relative).is_file(),
                f"artifact {name} missing: {relative}",
            )

    def test_component_shape(self) -> None:
        for component in self.manifest["components"]:
            with self.subTest(component=component.get("id")):
                self.assertIn("name", component)
                self.assertIn("license", component)
                self.assertIn("origin", component)

    def test_license_files_exist(self) -> None:
        for component in self.manifest["components"]:
            with self.subTest(component=component.get("id")):
                license_file = component.get("license_file")
                self.assertIsNotNone(license_file)
                self.assertTrue(
                    (ROOT / license_file).is_file(),
                    f"missing license file: {license_file}",
                )

    def test_manifest_and_notices_agree_on_licenses(self) -> None:
        """Every license the manifest declares must also be cited in the
        human-readable THIRD_PARTY_NOTICES.md table, keeping the two sources
        of truth consistent."""
        notices = (ROOT / "THIRD_PARTY_NOTICES.md").read_text(
            encoding="utf-8"
        )
        manifest_licenses = {
            component["license_file"]
            for component in self.manifest["components"]
            if "license_file" in component
        }
        self.assertGreaterEqual(len(manifest_licenses), 4)
        for license_file in manifest_licenses:
            self.assertIn(license_file, notices)

    def test_repository_sources_exist(self) -> None:
        for component in self.manifest["components"]:
            with self.subTest(component=component.get("id")):
                source = component.get("source")
                if source:
                    self.assertTrue(
                        (ROOT / source).is_file(),
                        f"missing source: {source}",
                    )

    def test_external_components_pin_identity(self) -> None:
        for component in self.manifest["components"]:
            with self.subTest(component=component.get("id")):
                if component["origin"] == "external":
                    identity = component.get("source_identity")
                    self.assertIsNotNone(identity)
                    self.assertIn("repository", identity)
                    self.assertIn("commit", identity)

    def test_bbc_basic_lock_resolves(self) -> None:
        for component in self.manifest["components"]:
            with self.subTest(component=component.get("id")):
                lock_file = component.get("lock_file")
                if not lock_file:
                    continue
                lock_path = ROOT / lock_file
                self.assertTrue(
                    lock_path.is_file(),
                    f"missing lock file: {lock_file}",
                )
                self.assertEqual(
                    self.lock["revision"],
                    component["source_identity"]["commit"],
                    "manifest commit differs from dependency lock revision",
                )

    def test_bbc_basic_lock_has_artifact_digest(self) -> None:
        artifact = self.lock.get("artifact")
        self.assertIsNotNone(artifact)
        self.assertIn("sha256", artifact)
        self.assertIn("size", artifact)

    def test_embedded_payload_matches_lock_digest(self) -> None:
        """The combined ROM's RBC1 container must carry the same compressed
        payload that the build produces, whose uncompressed digest is locked."""
        artifact = self.lock.get("artifact")
        if not artifact:
            self.skipTest("no BBC BASIC payload digest in lock")
        rom_path = ROOT / "build" / "rainbios_msx1.rom"
        zx0_path = ROOT / "build" / "payload" / "bbcbasic_msx_console.zx0"
        payload_path = ROOT / "build" / "payload" / "bbcbasic_msx_console.rom"
        if not rom_path.is_file() or not zx0_path.is_file():
            self.skipTest("combined ROM or embedded payload not built")
        rom = rom_path.read_bytes()
        self.assertEqual(len(rom), 0x8000)
        self.assertEqual(rom[0x4000:0x4004], b"RBC1")
        entry, length = int.from_bytes(rom[0x4004:0x4006], "little"), \
                        int.from_bytes(rom[0x4006:0x4008], "little")
        self.assertEqual(entry, 0x4010)
        stream = rom[0x4008:0x4008 + length]
        self.assertEqual(stream, zx0_path.read_bytes())
        payload = payload_path.read_bytes() if payload_path.is_file() else b""
        if payload:
            self.assertEqual(len(payload), artifact["size"])
            digest = hashlib.sha256(payload).hexdigest()
            self.assertEqual(digest, artifact["sha256"])


if __name__ == "__main__":
    unittest.main()
