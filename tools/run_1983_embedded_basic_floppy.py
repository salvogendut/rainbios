#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Exercise embedded BASIC program SAVE/CHAIN on a persistent FAT12 disk."""

from __future__ import annotations

import argparse
import hashlib
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

try:
    from tools.run_1983_disk_fswrite import fat12_entry
except ModuleNotFoundError:
    from run_1983_disk_fswrite import fat12_entry


RAM_RE = re.compile(r"^([0-9A-F]{4}):(.*)$", re.MULTILINE)
FAT_NAME = b"TEST    BBC"
SAVE_PROGRAM = '10 ?&E000=&5A\n20 ?&E001=&A5\nSAVE "A:TEST"\n'
CHAIN_PROGRAM = 'CHAIN "A:TEST"\n'


def ram_bytes(text: str, start: int, count: int) -> bytes:
    values: dict[int, int] = {}
    for match in RAM_RE.finditer(text):
        address = int(match.group(1), 16)
        for index, token in enumerate(match.group(2).split()):
            values[address + index] = int(token, 16)
    try:
        return bytes(values[address] for address in range(start, start + count))
    except KeyError as error:
        raise ValueError("1983 did not emit the requested RAM marker") from error


def read_fat12_file(image: bytes, name: bytes) -> tuple[bytes, list[int]]:
    if len(name) != 11:
        raise ValueError("FAT name must contain exactly 11 bytes")
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
        raise ValueError("unexpected FAT12 geometry")
    fat_start = reserved * sector_size
    fat_size = fat_sectors * sector_size
    fat = image[fat_start : fat_start + fat_size]
    if fat != image[fat_start + fat_size : fat_start + 2 * fat_size]:
        raise ValueError("the FAT copies differ")
    root_start = (reserved + fat_count * fat_sectors) * sector_size
    root_size = root_entries * 32
    root = image[root_start : root_start + root_size]
    entries = []
    for offset in range(0, root_size, 32):
        entry = root[offset : offset + 32]
        if entry[0] == 0:
            break
        if entry[0] != 0xE5 and entry[11] != 0x0F and entry[:11] == name:
            entries.append(entry)
    if len(entries) != 1:
        raise ValueError(f"expected one {name!r} entry, found {len(entries)}")
    entry = entries[0]
    size = int.from_bytes(entry[28:32], "little")
    cluster = int.from_bytes(entry[26:28], "little")
    chain: list[int] = []
    seen: set[int] = set()
    content = bytearray()
    root_sectors = (root_size + sector_size - 1) // sector_size
    first_data = reserved + fat_count * fat_sectors + root_sectors
    while cluster < 0xFF8:
        if cluster < 2 or cluster in seen:
            raise ValueError(f"invalid FAT chain at {cluster:#x}")
        seen.add(cluster)
        chain.append(cluster)
        start = (first_data + (cluster - 2) * sectors_per_cluster) * sector_size
        content.extend(image[start : start + sectors_per_cluster * sector_size])
        cluster = fat12_entry(fat, cluster)
    if not size or size > len(content):
        raise ValueError(f"invalid saved file size {size}")
    return bytes(content[:size]), chain


def run_1983(
    arguments: argparse.Namespace,
    *,
    paste: str,
    disk: pathlib.Path | None,
    floppy_mode: str = "read-write",
    dump_ram: str | None = None,
    screenshot: pathlib.Path | None = None,
) -> str:
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
        "--headless",
        "--unthrottled",
        "--paste-at",
        "300",
        "--paste-text",
        paste,
        "--exit-after",
        "900",
        "--dump-screen-text",
        "900",
        "--dump-state",
    ]
    if disk is not None:
        command.extend(
            ["--disk-a", str(disk), "--floppy-mode", floppy_mode]
        )
    if dump_ram is not None:
        command.extend(["--dump-ram", dump_ram])
    if screenshot is not None:
        command.extend(["--screenshot", str(screenshot)])
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    sys.stdout.write(result.stdout)
    if result.returncode:
        raise RuntimeError(f"1983 exited with status {result.returncode}")
    return result.stdout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--emulator", required=True)
    parser.add_argument("--models", type=pathlib.Path, required=True)
    parser.add_argument("--bios", type=pathlib.Path, required=True)
    parser.add_argument("--disk-rom", type=pathlib.Path, required=True)
    parser.add_argument("--blank-disk", type=pathlib.Path, required=True)
    parser.add_argument("--screenshot", type=pathlib.Path, required=True)
    arguments = parser.parse_args()

    try:
        with tempfile.TemporaryDirectory() as directory:
            working = pathlib.Path(directory) / "basic-programs.dsk"
            shutil.copy2(arguments.blank_disk, working)
            if working.read_bytes()[:3] != bytes(3):
                raise ValueError("blank data disk is unexpectedly bootable")

            save_output = run_1983(arguments, paste=SAVE_PROGRAM, disk=working)
            if "Disk " in save_output or "No disk" in save_output:
                raise ValueError("SAVE reported a disk error")
            saved_image = working.read_bytes()
            saved_program, chain = read_fat12_file(saved_image, FAT_NAME)

            load_output = run_1983(
                arguments,
                paste=CHAIN_PROGRAM,
                disk=working,
                dump_ram="0xE000:2",
                screenshot=arguments.screenshot,
            )
            if ram_bytes(load_output, 0xE000, 2) != b"\x5A\xA5":
                raise ValueError("CHAIN did not execute the persisted program")
            if working.read_bytes() != saved_image:
                raise ValueError("loading the program changed the disk image")

            read_only_before = hashlib.sha256(saved_image).digest()
            read_only_output = run_1983(
                arguments,
                paste='SAVE "A:READONLY"\n',
                disk=working,
                floppy_mode="read-only",
            )
            if "Disk write protected" not in read_only_output:
                raise ValueError("read-only SAVE did not report write protection")
            if hashlib.sha256(working.read_bytes()).digest() != read_only_before:
                raise ValueError("read-only SAVE changed the disk image")

            no_media_output = run_1983(
                arguments,
                paste='SAVE "A:NODISK"\n',
                disk=None,
            )
            if "No disk" not in no_media_output:
                raise ValueError("SAVE without media did not report No disk")
    except (OSError, RuntimeError, ValueError) as error:
        print(f"error: embedded BASIC floppy validation failed: {error}", file=sys.stderr)
        return 1

    print(
        "validated embedded BASIC FAT12 storage in 1983: "
        f"saved {len(saved_program)} bytes via clusters {chain}, "
        "CHAIN survived restart, read-only/no-media errors were explicit"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
