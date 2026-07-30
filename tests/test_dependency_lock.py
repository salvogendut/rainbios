# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
LOCK_PATH = ROOT / "deps" / "bbcbasic-z80-msx.lock.json"


class BasicDependencyLockTests(unittest.TestCase):
    def test_lock_has_complete_git_identities(self) -> None:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
        for field in ("revision", "upstream_snapshot", "upstream_tip", "upstream_tree"):
            with self.subTest(field=field):
                self.assertRegex(lock[field], r"^[0-9a-f]{40}$")

    def test_console_payload_identity_is_pinned(self) -> None:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
        artifact = lock["artifact"]
        self.assertEqual(
            artifact["path"],
            "build/msx-console/bbcbasic_msx_console.rom",
        )
        self.assertEqual(artifact["size"], 16_384)
        self.assertEqual(
            artifact["sha256"],
            "14733ea4ae0b7956dfcf9ab9ec4d6f1be838ec1f6efc6da83887fb0c69a7b817",
        )

    def test_boot_menu_names_the_pinned_interpreter(self) -> None:
        from tools.png_to_screen2 import OPTIONS_LINES

        self.assertEqual(OPTIONS_LINES[5], "1  START BBC BASIC")


if __name__ == "__main__":
    unittest.main()
