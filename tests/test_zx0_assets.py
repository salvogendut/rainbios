# SPDX-License-Identifier: BSD-3-Clause

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "build" / "logo"
COMPRESSED_ASSETS = (
    "options_name_ready",
    "options_name_missing",
    "options_color",
    "logo_pattern",
    "logo_name",
    "logo_color",
)


def decompress_zx0(data: bytes) -> bytes:
    """Decode the forward ZX0 v2 stream emitted by the vendored tool."""

    input_index = 0
    bit_mask = 0
    bit_value = 0
    backtrack = False
    last_byte = 0
    output = bytearray()

    def read_byte() -> int:
        nonlocal input_index, last_byte
        if input_index >= len(data):
            raise ValueError("truncated ZX0 stream")
        last_byte = data[input_index]
        input_index += 1
        return last_byte

    def read_bit() -> int:
        nonlocal bit_mask, bit_value, backtrack
        if backtrack:
            backtrack = False
            return last_byte & 1
        bit_mask >>= 1
        if not bit_mask:
            bit_mask = 0x80
            bit_value = read_byte()
        return int(bool(bit_value & bit_mask))

    def read_elias(inverted: bool = False) -> int:
        value = 1
        while not read_bit():
            value = (value << 1) | (read_bit() ^ int(inverted))
        return value

    last_offset = 1
    while True:
        literal_length = read_elias()
        for _ in range(literal_length):
            output.append(read_byte())

        if not read_bit():
            length = read_elias()
            for _ in range(length):
                output.append(output[-last_offset])
            if not read_bit():
                continue

        while True:
            offset_msb = read_elias(inverted=True)
            if offset_msb == 256:
                if input_index != len(data):
                    raise ValueError("trailing bytes in ZX0 stream")
                return bytes(output)
            last_offset = offset_msb * 128 - (read_byte() >> 1)
            backtrack = True
            length = read_elias() + 1
            if last_offset > len(output):
                raise ValueError("invalid ZX0 offset")
            for _ in range(length):
                output.append(output[-last_offset])
            if not read_bit():
                break


class Zx0AssetTest(unittest.TestCase):
    def test_every_compressed_asset_round_trips_exactly(self):
        for name in COMPRESSED_ASSETS:
            with self.subTest(asset=name):
                compressed = (ASSET_DIR / f"{name}.zx0").read_bytes()
                expected = (ASSET_DIR / f"{name}.bin").read_bytes()
                self.assertEqual(decompress_zx0(compressed), expected)


if __name__ == "__main__":
    unittest.main()
