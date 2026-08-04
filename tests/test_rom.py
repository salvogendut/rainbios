# SPDX-License-Identifier: BSD-3-Clause

import csv
import os
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ROM_PATH = Path(
    os.environ.get("RAINBIOS_MSX1_ROM", ROOT / "build" / "rainbios_msx1.rom")
)
MSX2_ROM_PATH = Path(
    os.environ.get("RAINBIOS_MSX2_ROM", ROOT / "build" / "rainbios_msx2.rom")
)
BBC_BASIC_ROM_PATH = Path(
    os.environ.get(
        "RAINBIOS_BBC_BASIC_ROM",
        ROOT / "build" / "payload" / "bbcbasic_msx_console.rom",
    )
)
ABI_PATH = ROOT / "docs" / "abi" / "main-bios.csv"


def read_abi():
    with ABI_PATH.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


class MainRomLayoutTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rom = ROM_PATH.read_bytes()
        cls.basic = BBC_BASIC_ROM_PATH.read_bytes()
        cls.abi = read_abi()

    def test_rom_is_exactly_32_kib(self):
        self.assertEqual(len(self.rom), 0x8000)

    def test_reset_starts_with_di_and_absolute_jump(self):
        self.assertEqual(self.rom[0], 0xF3)  # DI
        self.assertEqual(self.rom[1], 0xC3)  # JP nn
        destination = int.from_bytes(self.rom[2:4], "little")
        self.assertGreaterEqual(destination, 0x0200)
        self.assertLess(destination, len(self.rom))

    def test_fixed_metadata(self):
        font = int.from_bytes(self.rom[0x0004:0x0006], "little")
        self.assertGreaterEqual(font, 0x0200)
        self.assertLessEqual(font + 2048, 0x4000)
        self.assertEqual(self.rom[0x0006:0x0008], bytes((0x98, 0x98)))
        self.assertEqual(self.rom[0x002B:0x0030], bytes((0x21, 0x11, 0, 0, 0)))

    def test_every_documented_jump_is_a_jump_into_the_rom(self):
        for row in self.abi:
            if row["kind"] != "jump":
                continue
            if "MSX2 build only" in row["notes"]:
                continue  # fixed entries exist only in the MSX2 ROM build
            address = int(row["address"], 16)
            with self.subTest(name=row["name"], address=row["address"]):
                self.assertEqual(self.rom[address], 0xC3)
                destination = int.from_bytes(
                    self.rom[address + 1 : address + 3], "little"
                )
                self.assertGreaterEqual(destination, 0x0200)
                self.assertLess(destination, len(self.rom))

    def test_msx1_extrom_compatibility_entry_returns(self):
        self.assertEqual(self.rom[0x015F], 0xC9)  # RET

    def test_msx2_subrom_calling_entries_are_jumps(self):
        if not MSX2_ROM_PATH.exists():
            self.skipTest("MSX2 ROM not built")
        rom = MSX2_ROM_PATH.read_bytes()
        self.assertEqual(rom[0x002D], 0x01)  # MSX2 generation byte
        for address in (0x015C, 0x015F, 0x0162):
            with self.subTest(address=hex(address)):
                self.assertEqual(rom[address], 0xC3)
                destination = int.from_bytes(
                    rom[address + 1 : address + 3], "little"
                )
                self.assertGreaterEqual(destination, 0x0200)
                self.assertLess(destination, len(rom))

    def test_primary_slot_register_calls_are_direct(self):
        rslreg = int.from_bytes(self.rom[0x0139:0x013B], "little")
        wslreg = int.from_bytes(self.rom[0x013C:0x013E], "little")
        self.assertEqual(self.rom[rslreg : rslreg + 3], bytes((0xDB, 0xA8, 0xC9)))
        self.assertEqual(self.rom[wslreg : wslreg + 3], bytes((0xD3, 0xA8, 0xC9)))

    def test_nextor_keyboard_layout_compatibility_entry(self):
        filvrm = int.from_bytes(self.rom[0x0057:0x0059], "little")
        self.assertEqual(self.rom[filvrm], 0xC3)  # JP relocated implementation
        self.assertEqual(
            self.rom[0x0D89:0x0D90],
            bytes((0xF5, 0xC5, 0xD5, 0xE5, 0x3E, ord("N"), 0xCD)),
        )
        self.assertEqual(
            self.rom[0x0D92:0x0D97], bytes((0xE1, 0xD1, 0xC1, 0xF1, 0xC9))
        )
        target = int.from_bytes(self.rom[0x0D90:0x0D92], "little")
        self.assertGreaterEqual(target, 0x0200)
        self.assertLess(target, len(self.rom))

    def test_abi_addresses_are_unique_and_ordered(self):
        addresses = [int(row["address"], 16) for row in self.abi]
        self.assertEqual(addresses, sorted(addresses))
        self.assertEqual(len(addresses), len(set(addresses)))

    def test_abi_status_vocabulary_is_controlled(self):
        statuses = {row["status"] for row in self.abi}
        self.assertLessEqual(statuses, {"stub", "partial", "implemented"})
        self.assertIn("stub", statuses)

    def test_upper_bank_is_the_source_built_internal_basic_container(self):
        self.assertEqual(len(self.basic), 0x4000)
        self.assertEqual(self.basic[:2], b"AB")
        self.assertEqual(self.rom[0x4000:0x4004], b"RBC1")
        self.assertEqual(self.rom[0x4004:0x4006], b"\x10\x40")
        compressed_size = int.from_bytes(self.rom[0x4006:0x4008], "little")
        self.assertGreater(compressed_size, 0)
        self.assertLessEqual(compressed_size, 0x37F8)
        self.assertNotEqual(
            self.rom[0x4008 : 0x4008 + compressed_size], b"\xFF" * compressed_size
        )
        self.assertEqual(
            self.rom[0x4008 + compressed_size :],
            b"\xFF" * (0x3FF8 - compressed_size),
        )
        self.assertEqual(self.basic[0x3FF0:0x3FF4], b"RBP1")


if __name__ == "__main__":
    unittest.main()
