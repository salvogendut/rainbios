# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import pathlib
import tempfile
import unittest

from tools.run_openmsx_disk_fault import (
    label_for_pc,
    parse_symbols,
    validate_report,
)

PASS_ADDRESS = 0x43D2


class DiskFaultProbeTests(unittest.TestCase):
    def _symbols(self) -> pathlib.Path:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        symbols = pathlib.Path(directory.name) / "disk_fault_rom.sym"
        symbols.write_text(
            "DISK_FAULT_PASS #43D2 B0 L\n"
            "DISK_FAULT_FAIL_CONTROL #43D8 B0 L\n"
            "DISK_FAULT_FAIL_SEEK_CRC #43E4 B0 L\n",
            encoding="utf-8",
        )
        return symbols

    def _pass_report(self) -> str:
        return (
            "STATUS=PASS\n"
            f"PC={PASS_ADDRESS:04X}\n"
            "SCENARIO=0E\n"
            "SLOT=F4\n"
        )

    def test_parse_symbols_extracts_labels(self) -> None:
        symbols = parse_symbols(self._symbols())
        self.assertEqual(symbols["disk_fault_pass"], PASS_ADDRESS)
        self.assertEqual(symbols["disk_fault_fail_seek_crc"], 0x43E4)

    def test_label_for_pc(self) -> None:
        symbols = {"disk_fault_fail_seek_crc": 0x43E4}
        self.assertEqual(label_for_pc(symbols, 0x43E4), "disk_fault_fail_seek_crc")
        self.assertEqual(label_for_pc(symbols, 0x0000), "unknown")

    def test_pass_report_is_accepted(self) -> None:
        validate_report(self._pass_report(), {}, PASS_ADDRESS)

    def test_fail_report_is_rejected(self) -> None:
        report = self._pass_report().replace(
            "STATUS=PASS",
            "STATUS=FAIL\nLABEL=disk_fault_fail_seek_crc",
        )
        with self.assertRaisesRegex(
            ValueError, "disk_fault_fail_seek_crc"
        ):
            validate_report(report, {}, PASS_ADDRESS)

    def test_wrong_stop_address_is_rejected(self) -> None:
        report = self._pass_report().replace(f"PC={PASS_ADDRESS:04X}", "PC=43E4")
        symbols = {"disk_fault_fail_seek_crc": 0x43E4}
        with self.assertRaisesRegex(ValueError, "disk_fault_fail_seek_crc"):
            validate_report(report, symbols, PASS_ADDRESS)


if __name__ == "__main__":
    unittest.main()
