# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

from pathlib import Path
import unittest

from tools.payload_descriptor import descriptor_from_rom, parse_descriptor


ROOT = Path(__file__).resolve().parents[1]
VALID_PAYLOAD_ROM = ROOT / "build" / "cartridges" / "payload_valid.rom"


BBC_BASIC_DESCRIPTOR = bytes.fromhex(
    "52 42 50 31 01 10 01 1F 10 40 00 80 00 F3 02 F5"
)


class PayloadDescriptorTests(unittest.TestCase):
    def test_bbc_basic_p1_descriptor(self) -> None:
        descriptor = parse_descriptor(BBC_BASIC_DESCRIPTOR)
        self.assertEqual(descriptor.entry, 0x4010)
        self.assertEqual((descriptor.ram_start, descriptor.ram_end), (0x8000, 0xF300))
        self.assertEqual(descriptor.required_services, 0x1F)

    def test_descriptor_is_read_from_rom_tail(self) -> None:
        descriptor = descriptor_from_rom(
            bytes(0x4000 - len(BBC_BASIC_DESCRIPTOR)) + BBC_BASIC_DESCRIPTOR
        )
        self.assertEqual(descriptor.ram_pages, 2)

    def test_checksum_and_unknown_services_are_rejected(self) -> None:
        damaged = bytearray(BBC_BASIC_DESCRIPTOR)
        damaged[8] ^= 1
        with self.assertRaisesRegex(ValueError, "checksum"):
            parse_descriptor(bytes(damaged))

        unknown = bytearray(BBC_BASIC_DESCRIPTOR)
        unknown[7] = 0x9F
        unknown[-1] = (-sum(unknown[:-1])) & 0xFF
        with self.assertRaisesRegex(ValueError, "unknown"):
            parse_descriptor(bytes(unknown))

    def test_unknown_payload_type_is_rejected(self) -> None:
        unknown = bytearray(BBC_BASIC_DESCRIPTOR)
        unknown[6] = 2
        unknown[-1] = (-sum(unknown[:-1])) & 0xFF
        with self.assertRaisesRegex(ValueError, "unsupported payload type"):
            parse_descriptor(bytes(unknown))

    def test_valid_payload_fixture_claims_cleanly(self) -> None:
        rom = VALID_PAYLOAD_ROM.read_bytes()
        descriptor = descriptor_from_rom(rom)
        self.assertEqual(descriptor.entry, 0x4010)
        self.assertEqual((descriptor.ram_start, descriptor.ram_end), (0x8000, 0xC000))
        self.assertEqual(descriptor.ram_pages, 2)


if __name__ == "__main__":
    unittest.main()
