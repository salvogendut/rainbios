#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Create the deterministic cassette used by the RainBIOS tape probe."""

from __future__ import annotations

import argparse
import pathlib


CAS_MARKER = bytes.fromhex("1F A6 DE BA CC 13 7D 74")
PROBE_PAYLOAD = b"RAINTAPE"


def make_image() -> bytes:
    return CAS_MARKER + PROBE_PAYLOAD


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=pathlib.Path)
    arguments = parser.parse_args()
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    image = make_image()
    arguments.output.write_bytes(image)
    print(f"wrote cassette probe image: {arguments.output} ({len(image)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
