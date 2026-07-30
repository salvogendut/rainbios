#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Parse and validate a RainBIOS payload descriptor."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import pathlib
import struct


DESCRIPTOR_SIZE = 16
MAGIC = b"RBP1"
VERSION = 1
TYPE_BASIC = 1
KNOWN_SERVICES = 0x0F
STRUCT = struct.Struct("<4sBBBBHHHBB")


@dataclass(frozen=True)
class PayloadDescriptor:
    version: int
    length: int
    payload_type: int
    required_services: int
    entry: int
    ram_start: int
    ram_end: int
    ram_pages: int


def parse_descriptor(data: bytes) -> PayloadDescriptor:
    if len(data) != DESCRIPTOR_SIZE:
        raise ValueError(f"descriptor is {len(data)} bytes, expected 16")
    (
        magic,
        version,
        length,
        payload_type,
        required_services,
        entry,
        ram_start,
        ram_end,
        ram_pages,
        _checksum,
    ) = STRUCT.unpack(data)
    if magic != MAGIC:
        raise ValueError(f"invalid descriptor magic: {magic!r}")
    if version != VERSION or length != DESCRIPTOR_SIZE:
        raise ValueError(
            f"unsupported descriptor version/length: {version}/{length}"
        )
    if sum(data) & 0xFF:
        raise ValueError("descriptor checksum is not zero")
    if payload_type != TYPE_BASIC:
        raise ValueError(f"unsupported payload type: {payload_type}")
    if required_services & ~KNOWN_SERVICES:
        raise ValueError("descriptor requests unknown firmware services")
    if not 0x4000 <= entry < 0x8000:
        raise ValueError(f"entry is outside page-1 ROM: {entry:#06x}")
    if ram_start != 0x8000 or not ram_start < ram_end <= 0xF380:
        raise ValueError("unsupported payload RAM window")
    if ram_pages != 2:
        raise ValueError("v1 payload must require two contiguous RAM pages")
    return PayloadDescriptor(
        version=version,
        length=length,
        payload_type=payload_type,
        required_services=required_services,
        entry=entry,
        ram_start=ram_start,
        ram_end=ram_end,
        ram_pages=ram_pages,
    )


def descriptor_from_rom(rom: bytes) -> PayloadDescriptor:
    if len(rom) != 0x4000:
        raise ValueError(f"payload ROM is {len(rom)} bytes, expected 16384")
    return parse_descriptor(rom[-DESCRIPTOR_SIZE:])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=pathlib.Path)
    arguments = parser.parse_args()
    try:
        descriptor = descriptor_from_rom(arguments.rom.read_bytes())
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(
        "validated RainBIOS payload descriptor: "
        f"type={descriptor.payload_type}, entry={descriptor.entry:#06x}, "
        f"RAM={descriptor.ram_start:#06x}-{descriptor.ram_end:#06x}, "
        f"services={descriptor.required_services:#04x}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
