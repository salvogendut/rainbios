#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Assemble the RainBIOS reproducible release bundle.

Copies the production ROMs, symbol files, the component manifest, and the
license texts into a versioned directory under build/release/, writes a
SHA256SUMS file for the ROMs, and a short RELEASE-NOTES.md. The bundle is
reproducible: it contains only build outputs and tracked source texts, and the
ROM digests are the same whenever the same pinned sources are rebuilt.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import sys


PRODUCTION_ROMS = [
    "rainbios_msx1.rom",
    "rainbios_msx2.rom",
    "rainbios_msx2_sub.rom",
    "rainbios_nms8250_disk.rom",
]

LICENSE_FILES = [
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "components.json",
    "LICENSES/ZX0.txt",
    "LICENSES/BBCBASIC-Z80.txt",
    "LICENSES/BBCBASIC-MSX-BSD-3-Clause.txt",
    "LICENSES/CC0-1.0.txt",
]


def git(repository: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repository), *arguments],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return result.stdout.strip()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version", required=True)
    arguments = parser.parse_args()

    output = arguments.output
    output.mkdir(parents=True, exist_ok=True)

    # Production ROMs and their symbol files.
    for name in PRODUCTION_ROMS:
        rom = arguments.build / name
        if not rom.is_file():
            print(f"error: missing ROM artifact: {rom}", file=__import__("sys").stderr)
            return 1
        shutil.copy2(rom, output / name)
        symbol = rom.with_suffix(".sym")
        if symbol.is_file():
            shutil.copy2(symbol, output / symbol.name)

    # Tracked texts: component manifest, notices, and license texts.
    for relative in LICENSE_FILES:
        source = arguments.root / relative
        if not source.is_file():
            print(
                f"error: missing tracked text: {source}",
                file=__import__("sys").stderr,
            )
            return 1
        destination = output / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)

    # SPDX 2.3 JSON document.
    spdx = output / "rainbios.spdx.json"
    namespace = (
        f"https://github.com/salvogendut/rainbios/releases/download/"
        f"{arguments.version}/spdx.json"
    )
    result = subprocess.run(
        [
            sys.executable,
            str(arguments.root / "tools" / "export_spdx.py"),
            "--root",
            str(arguments.root),
            "--build",
            str(arguments.build),
            "--output",
            str(spdx),
            "--namespace",
            namespace,
            "--roms",
            *PRODUCTION_ROMS,
        ],
        check=True,
    )
    if result.returncode:
        print("error: SPDX export failed", file=sys.stderr)
        return 1

    # SHA256SUMS for the ROMs.
    checksums = output / "SHA256SUMS"
    with checksums.open("w", encoding="utf-8") as handle:
        for name in PRODUCTION_ROMS:
            digest = sha256(output / name)
            handle.write(f"{digest}  {name}\n")

    # Release notes.
    commit = git(arguments.root, "rev-parse", "HEAD")
    notes = output / "RELEASE-NOTES.md"
    notes.write_text(
        f"# RainBIOS {arguments.version}\n\n"
        f"- Source commit: `{commit}`\n"
        f"- Component manifest: see `components.json` and `THIRD_PARTY_NOTICES.md`.\n"
        f"- Compatibility results: see `docs/CARTRIDGE_COMPATIBILITY.md`.\n"
        f"- ROM digests: see `SHA256SUMS`.\n"
        f"- Branding note: the BBC BASIC name is used under the pinned "
        f"upstream license; public distribution is gated on permission or a "
        f"rename (see `docs/EMBEDDED_BASIC.md`).\n",
        encoding="utf-8",
    )

    print(
        f"assembled release bundle {arguments.version} in {output}\n"
        f"  commit {commit}\n"
        f"  {len(PRODUCTION_ROMS)} ROMs, "
        f"{len(list(output.glob('*.sym')))} symbol files, "
        f"{len(LICENSE_FILES)} tracked texts"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
