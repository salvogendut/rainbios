# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import pathlib
import unittest

from tools.run_1983_disk_write_probe import (
    PATTERN,
    check_image_written,
    check_markers,
    parse_markers,
)


GOOD_WRITABLE = (
    "state frame=301 pc=C070 sp=E000 slot=FC subslot=AC "
    "mapper=03,02,01,00 cycles=0 instructions=0 vram_nonzero=7271 "
    "vdp_r0=02 vdp_r1=60\n"
    "F3C0: 00 00 00 00 5A\n"
)
GOOD_PROTECT = (
    "state frame=301 pc=C070 sp=E000 slot=FC subslot=AC "
    "mapper=03,02,01,00 cycles=0 instructions=0 vram_nonzero=7271 "
    "vdp_r0=02 vdp_r1=60\n"
    "F3C0: 01 03 00 00 5A\n"
)


class DiskWriteMarkerTests(unittest.TestCase):
    def test_writable_markers_accepted(self) -> None:
        check_markers(GOOD_WRITABLE, write_protect=False)

    def test_write_protect_markers_accepted(self) -> None:
        check_markers(GOOD_PROTECT, write_protect=True)

    def test_missing_pass_is_rejected(self) -> None:
        bad = GOOD_WRITABLE.replace("5A\n", "00\n")
        with self.assertRaisesRegex(ValueError, "pass label"):
            check_markers(bad, write_protect=False)

    def test_writable_carry_must_be_clear(self) -> None:
        with self.assertRaisesRegex(ValueError, "carry"):
            check_markers(GOOD_PROTECT, write_protect=False)

    def test_write_protect_must_report_error_3(self) -> None:
        bad = GOOD_PROTECT.replace("01 03", "01 04")
        with self.assertRaisesRegex(ValueError, "error"):
            check_markers(bad, write_protect=True)

    def test_parse_markers(self) -> None:
        markers = parse_markers("F3C0: 00 00 00 00 5A\n")
        self.assertEqual(markers[0xF3C4], 0x5A)


class DiskWriteImageTests(unittest.TestCase):
    def test_pattern_sector_is_accepted(self) -> None:
        check_image_written(self._image(PATTERN))

    def test_wrong_pattern_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "sector 2"):
            check_image_written(self._image(bytes([0xAA]) * 512))

    def _image(self, sector: bytes) -> pathlib.Path:
        import tempfile

        handle = tempfile.NamedTemporaryFile(delete=False, suffix=".dsk")
        handle.write(bytes([0xE5]) * 1024 + sector)
        handle.close()
        self.addCleanup(lambda: pathlib.Path(handle.name).unlink())
        return pathlib.Path(handle.name)


if __name__ == "__main__":
    unittest.main()
