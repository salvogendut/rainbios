#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the openMSX MSX2 SUB-ROM calling report."""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    arguments = parser.parse_args()

    fields: dict[str, str] = {}
    for line in arguments.report.read_text().splitlines():
        key, separator, value = line.partition("=")
        if separator:
            fields[key] = value

    errors: list[str] = []
    expected = {
        "EXBRSA": "83",
        "MARKER_CHKSLZ": "01",
        "MARKER_EXBRSA": "83",
        "MARKER_EXTROM": "A5",
        "MARKER_SUBROM": "5A",
    }
    for key, value in expected.items():
        if fields.get(key) != value:
            errors.append(f"{key}: found {fields.get(key)!r}, expected {value!r}")

    try:
        pc = int(fields["PC"], 16)
    except (KeyError, ValueError) as error:
        errors.append("missing valid PC")
    else:
        # The SUB-ROM spin loop lives in the SUB-ROM's page-0 slot, so the
        # sampled PC must be inside the SUB-ROM range after the SUBROM call.
        if not 0x0120 <= pc < 0x0140:
            errors.append(f"PC {pc:04X} is not inside the SUB-ROM spin routine")

    if errors:
        raise SystemExit("invalid MSX2 SUB-ROM report:\n  " + "\n  ".join(errors))
    print(
        f"validated openMSX MSX2 SUB-ROM: EXBRSA={fields['EXBRSA']}, "
        f"CHKSLZ={fields['MARKER_CHKSLZ']}, EXTROM={fields['MARKER_EXTROM']}, "
        f"SUBROM={fields['MARKER_SUBROM']}, PC={fields['PC']}"
    )


if __name__ == "__main__":
    main()
