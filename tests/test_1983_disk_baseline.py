# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.run_1983_disk_baseline import (
    parse_symbols,
    validate_disk_baseline_state,
)


class DiskBaselineTests(unittest.TestCase):
    def make_state(self, pc: int) -> str:
        return (
            f"state frame=181 pc={pc:04X} sp=F360 slot=F4 subslot=00 "
            "mapper=00,00,00,00 vram_nonzero=9553 vdp_r0=02 vdp_r1=E0\n"
        )

    def test_pass_state_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            symbols = Path(root) / "symbols.sym"
            symbols.write_text(
                "DISK_BASELINE_PASS #41AA B0 L\n"
                "DISK_FAIL_PHYIO #41A0 B0 L\n",
                encoding="utf-8",
            )
            values = validate_disk_baseline_state(
                self.make_state(0x41AA),
                symbols=parse_symbols(symbols),
            )
            self.assertEqual(values["pc"], "41AA")

    def test_fail_state_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            symbols = Path(root) / "symbols.sym"
            symbols.write_text(
                "DISK_BASELINE_PASS #41AA B0 L\n"
                "DISK_FAIL_PHYIO #41A0 B0 L\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "disk baseline stopped"):
                validate_disk_baseline_state(
                    self.make_state(0x41A0),
                    symbols=parse_symbols(symbols),
                )

    def test_missing_symbol_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            symbols = Path(root) / "symbols.sym"
            symbols.write_text("SOME_OTHER_LABEL #41AA B0 L\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "missing required symbol"):
                validate_disk_baseline_state(
                    self.make_state(0x41AA),
                    symbols=parse_symbols(symbols),
                )


if __name__ == "__main__":
    unittest.main()

