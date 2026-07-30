#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Verify a BBC BASIC sibling checkout against RainBIOS's dependency lock."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
LOCK_PATH = ROOT / "deps" / "bbcbasic-z80-msx.lock.json"


def git(repository: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repository), *arguments],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return result.stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", type=Path, required=True)
    arguments = parser.parse_args()
    repository = arguments.repository.resolve()
    lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))

    checks = {
        "revision": git(repository, "rev-parse", "HEAD"),
        "upstream_tip": git(
            repository,
            "rev-parse",
            f"{lock['upstream_tag']}^{{commit}}",
        ),
        "upstream_tree": git(
            repository,
            "rev-parse",
            f"{lock['upstream_tag']}^{{tree}}",
        ),
    }
    failures = [
        f"{field}: found {actual}, expected {lock[field]}"
        for field, actual in checks.items()
        if actual != lock[field]
    ]

    if failures:
        for failure in failures:
            print(f"error: {failure}", file=sys.stderr)
        return 1

    print(
        "verified BBC BASIC dependency "
        f"{lock['revision'][:12]} and tree {lock['upstream_tree']}"
    )
    if lock["artifact"] is None:
        print("MSX payload artifact: not available yet")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, subprocess.CalledProcessError) as error:
        print(f"dependency check failed: {error}", file=sys.stderr)
        raise SystemExit(1)
