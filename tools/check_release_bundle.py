#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate a RainBIOS release bundle against the freshly built artifacts."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path


PRODUCTION_ROMS = [
    "rainbios_msx1.rom",
    "rainbios_msx2.rom",
    "rainbios_msx2_sub.rom",
    "rainbios_nms8250_disk.rom",
]

TRACKED_TEXTS = [
    "LICENSE",
    "THIRD_PARTY_NOTICES.md",
    "components.json",
    "LICENSES/ZX0.txt",
    "LICENSES/BBCBASIC-Z80.txt",
    "LICENSES/BBCBASIC-MSX-BSD-3-Clause.txt",
    "LICENSES/CC0-1.0.txt",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--version", required=True)
    arguments = parser.parse_args()
    bundle = arguments.bundle
    root = arguments.root

    errors: list[str] = []

    if not bundle.is_dir():
        print(f"error: bundle missing: {bundle}", file=__import__("sys").stderr)
        return 1

    for name in PRODUCTION_ROMS:
        if not (bundle / name).is_file():
            errors.append(f"bundle missing ROM: {name}")

    for relative in TRACKED_TEXTS:
        if not (bundle / relative).is_file():
            errors.append(f"bundle missing tracked text: {relative}")

    if not (bundle / "SHA256SUMS").is_file():
        errors.append("bundle missing SHA256SUMS")
    else:
        for line in (bundle / "SHA256SUMS").read_text().splitlines():
            digest, separator, name = line.partition("  ")
            if not separator or name not in PRODUCTION_ROMS:
                errors.append(f"unexpected SHA256SUMS line: {line!r}")
                continue
            actual = sha256(bundle / name)
            if actual != digest:
                errors.append(f"SHA256SUMS mismatch for {name}")

    if not (bundle / "RELEASE-NOTES.md").is_file():
        errors.append("bundle missing RELEASE-NOTES.md")
    else:
        notes = (bundle / "RELEASE-NOTES.md").read_text()
        if arguments.version not in notes:
            errors.append("RELEASE-NOTES.md does not name the version")

    if errors:
        print("error: invalid release bundle:\n  " + "\n  ".join(errors),
              file=__import__("sys").stderr)
        return 1

    print(
        f"validated RainBIOS release bundle {arguments.version}: "
        f"{len(PRODUCTION_ROMS)} ROMs, {len(TRACKED_TEXTS)} tracked texts, "
        f"SHA256SUMS consistent"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
