# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
LICENSES = ROOT / "LICENSES"


class CombinedRomNoticeTests(unittest.TestCase):
    def test_interpreter_license_notices_are_exactly_recorded(self) -> None:
        expected = {
            "BBCBASIC-Z80.txt":
                "cf5efb79a693ab044d2c5354d00f682e22fde66b428da1b4dc24cb1ad2ef42bb",
            "BBCBASIC-MSX-BSD-3-Clause.txt":
                "adabed6158b0f1ed2b08a4b1a6a013fa2f8f0f1eeb222b5a3f201edb123b9824",
        }
        for filename, digest in expected.items():
            with self.subTest(filename=filename):
                actual = hashlib.sha256((LICENSES / filename).read_bytes()).hexdigest()
                self.assertEqual(actual, digest)

    def test_notice_maps_the_pinned_payload_identity(self) -> None:
        lock = json.loads(
            (ROOT / "deps" / "bbcbasic-z80-msx.lock.json").read_text(
                encoding="utf-8"
            )
        )
        notice = (ROOT / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
        self.assertIn(lock["revision"], notice)
        self.assertIn(lock["artifact"]["sha256"], notice)
        self.assertIn("LICENSES/BBCBASIC-Z80.txt", notice)
        self.assertIn("LICENSES/BBCBASIC-MSX-BSD-3-Clause.txt", notice)

    def test_zx0_notice_is_present(self) -> None:
        notice = (ROOT / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
        self.assertIn("LICENSES/ZX0.txt", notice)
        self.assertIn("ecde3a2ae05061fe06469ed46df81a33b7de7d86", notice)


if __name__ == "__main__":
    unittest.main()
