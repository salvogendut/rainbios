#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Verify a BBC BASIC sibling checkout against RainBIOS's dependency lock."""

from __future__ import annotations

import argparse
import hashlib
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
    artifact_mode = parser.add_mutually_exclusive_group()
    artifact_mode.add_argument(
        "--require-artifact",
        action="store_true",
        help="fail unless the pinned payload has been built and matches",
    )
    artifact_mode.add_argument(
        "--skip-artifact",
        action="store_true",
        help="verify source identities without inspecting an existing build",
    )
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
    if arguments.skip_artifact:
        return 0

    artifact = lock["artifact"]
    artifact_path = repository / artifact["path"]
    if not artifact_path.is_file():
        if arguments.require_artifact:
            print(f"error: missing payload artifact: {artifact_path}", file=sys.stderr)
            return 1
        print(
            "pinned MSX payload is not built in this checkout; "
            f"expected {artifact['path']}"
        )
        return 0

    payload = artifact_path.read_bytes()
    digest = hashlib.sha256(payload).hexdigest()
    if len(payload) != artifact["size"] or digest != artifact["sha256"]:
        print(
            "error: BBC BASIC payload mismatch: "
            f"{len(payload)} bytes, SHA-256 {digest}",
            file=sys.stderr,
        )
        return 1
    print(f"verified MSX payload {len(payload)} bytes, SHA-256 {digest}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, subprocess.CalledProcessError) as error:
        print(f"dependency check failed: {error}", file=sys.stderr)
        raise SystemExit(1)
