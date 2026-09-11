#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Boot the production NMS 8250 disk ROM in 1983 with the FS.WRITE fixture
and validate file creation on a FAT12 disk."""

from __future__ import annotations

import argparse
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)

M_CARRY = 0xF3D0
M_ERROR = 0xF3D1
M_PASS = 0xF3D5
WRITTEN_NAME = b"MINI    TXT"
WRITTEN_SIZE = 2500
WRITTEN_VALUE = 0xCD


def fat12_entry(fat: bytes, cluster: int) -> int:
    offset = cluster + cluster // 2
    word = int.from_bytes(fat[offset : offset + 2], "little")
    return (word >> 4 if cluster & 1 else word) & 0xFFF


def validate_written_image(image: bytes) -> list[int]:
    if len(image) != 720 * 1024:
        raise ValueError(f"disk size is {len(image)}, expected 737280")
    sector_size = int.from_bytes(image[11:13], "little")
    sectors_per_cluster = image[13]
    reserved = int.from_bytes(image[14:16], "little")
    fat_count = image[16]
    root_entries = int.from_bytes(image[17:19], "little")
    fat_sectors = int.from_bytes(image[22:24], "little")
    if (sector_size, sectors_per_cluster, fat_count, fat_sectors) != (
        512,
        2,
        2,
        3,
    ):
        raise ValueError("unexpected FAT12 geometry after write")

    fat_bytes = fat_sectors * sector_size
    fat_start = reserved * sector_size
    fat = image[fat_start : fat_start + fat_bytes]
    second_fat = image[fat_start + fat_bytes : fat_start + 2 * fat_bytes]
    if fat != second_fat:
        raise ValueError("the two FAT copies differ")

    root_start = (reserved + fat_count * fat_sectors) * sector_size
    root_size = root_entries * 32
    root = image[root_start : root_start + root_size]
    matches = []
    for offset in range(0, len(root), 32):
        entry = root[offset : offset + 32]
        if entry[0] == 0:
            break
        if entry[0] == 0xE5 or entry[11] == 0x0F:
            continue
        if entry[:11] == WRITTEN_NAME:
            matches.append(entry)
    if len(matches) != 1:
        raise ValueError(f"expected one MINI.TXT entry, found {len(matches)}")
    entry = matches[0]
    if entry[11] & 0x18:
        raise ValueError("MINI.TXT is not a regular file")
    size = int.from_bytes(entry[28:32], "little")
    if size != WRITTEN_SIZE:
        raise ValueError(f"MINI.TXT size is {size}, expected {WRITTEN_SIZE}")

    cluster = int.from_bytes(entry[26:28], "little")
    chain: list[int] = []
    seen: set[int] = set()
    while cluster < 0xFF8:
        if cluster < 2 or cluster in seen:
            raise ValueError(f"invalid FAT chain at cluster {cluster:#x}")
        seen.add(cluster)
        chain.append(cluster)
        cluster = fat12_entry(fat, cluster)
    expected_clusters = (
        WRITTEN_SIZE + sector_size * sectors_per_cluster - 1
    ) // (sector_size * sectors_per_cluster)
    if len(chain) != expected_clusters:
        raise ValueError(
            f"MINI.TXT uses {len(chain)} clusters, expected {expected_clusters}"
        )

    root_sectors = (root_size + sector_size - 1) // sector_size
    first_data = reserved + fat_count * fat_sectors + root_sectors
    content = bytearray()
    for item in chain:
        start = (first_data + (item - 2) * sectors_per_cluster) * sector_size
        length = sectors_per_cluster * sector_size
        content.extend(image[start : start + length])
    expected = bytes((WRITTEN_VALUE,)) * WRITTEN_SIZE
    if bytes(content[:WRITTEN_SIZE]) != expected:
        raise ValueError("MINI.TXT does not contain the replacement data")

    # The deterministic fixture allocates 5-7 for the first version and 8-10
    # for its replacement. The old chain must have been reclaimed.
    if any(fat12_entry(fat, item) != 0 for item in (5, 6, 7)):
        raise ValueError("the replaced file's old FAT chain was not reclaimed")
    return chain


def parse_markers(text: str) -> dict[int, int]:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    return values


def check_markers(text: str) -> None:
    markers = parse_markers(text)
    if markers.get(M_PASS) != 0x5A:
        raise ValueError(
            f"FS.WRITE fixture did not reach pass label "
            f"(pass={markers.get(M_PASS)!r})"
        )
    if markers.get(M_CARRY) != 0x00:
        raise ValueError(
            f"FS.WRITE carry={markers.get(M_CARRY)!r}, expected 0"
        )
    if markers.get(M_ERROR) != 0x00:
        raise ValueError(
            f"FS.WRITE error={markers.get(M_ERROR)!r}, expected 0"
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--disk-rom", type=pathlib.Path, required=True)
    parser.add_argument("--disk-a", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    arguments = parser.parse_args()

    with tempfile.TemporaryDirectory() as directory:
        working = pathlib.Path(directory) / "disk-fswrite.dsk"
        shutil.copy2(arguments.disk_a, working)
        command = [
            arguments.emulator,
            "--config",
            "/dev/null",
            "--models",
            str(arguments.models),
            "--model",
            "nms8250",
            "--region",
            "pal",
            "--bios",
            str(arguments.bios),
            "--disk-rom",
            str(arguments.disk_rom),
            "--disk-a",
            str(working),
            "--floppy-mode",
            "read-write",
            "--headless",
            "--unthrottled",
            "--exit-after",
            "2000",
            "--dump-state",
            "--dump-ram",
            "0xF3D0:0x6",
            "--screenshot",
            str(arguments.screenshot),
        ]
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        sys.stdout.write(result.stdout)
        if result.returncode:
            return result.returncode
        try:
            check_markers(result.stdout)
            chain = validate_written_image(working.read_bytes())
        except ValueError as error:
            print(
                f"error: invalid 1983 FS.WRITE result: {error}",
                file=sys.stderr,
            )
            return 1
    print(
        "validated 1983 FS.WRITE: one replacement file persisted through "
        f"FAT chain {chain}, old chain reclaimed"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
