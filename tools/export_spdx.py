#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Generate an SPDX 2.3 JSON document from the RainBIOS component manifest.

The manifest format in components.json is deliberately chosen to map to SPDX:
each component becomes a Package with its SPDX license expression and, for
external components, the pinned source repository as the download location and
commit as the package version. The document references the packaged ROMs as
files.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path

import sys


SPDX_VERSION = "SPDX-2.3"

LICENSE_ID = {
    "BSD-3-Clause": "BSD-3-Clause",
    "CC0-1.0": "CC0-1.0",
    "Zlib-style": "LicenseRef-RTBBC-Zlib",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def spdx_id(index: int) -> str:
    return f"SPDXRef-Package-{index}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--namespace", required=True)
    parser.add_argument("--roms", nargs="+", required=True)
    arguments = parser.parse_args()
    root = arguments.root

    manifest = json.loads((root / "components.json").read_text())
    document = {
        "SPDXID": "SPDXRef-DOCUMENT",
        "spdxVersion": SPDX_VERSION,
        "creationInfo": {
            "created": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "creators": ["Tool: RainBIOS make_release_bundle.py"],
            "licenseListVersion": "3.24",
        },
        "name": "RainBIOS combined ROM components",
        "dataLicense": "CC0-1.0",
        "documentNamespace": arguments.namespace,
        "packages": [],
        "relationships": [],
        "files": [],
        "hasExtractedLicensingInfos": [],
    }

    # The BBC BASIC core uses the upstream Zlib-style notice, which SPDX does
    # not carry as a standard id; declare it as an extracted license.
    zlib_path = root / "LICENSES" / "BBCBASIC-Z80.txt"
    if zlib_path.is_file():
        document["hasExtractedLicensingInfos"].append({
            "licenseId": "LicenseRef-RTBBC-Zlib",
            "extractedText": zlib_path.read_text(encoding="utf-8").strip(),
            "name": "R. T. Russell Z80 interpreter core notice",
        })

    for index, component in enumerate(manifest["components"]):
        license_id = LICENSE_ID.get(component["license"])
        if not license_id:
            print(
                f"error: unknown license expression "
                f"{component.get('license')!r} for {component.get('id')}",
                file=sys.stderr,
            )
            return 1
        package: dict = {
            "SPDXID": spdx_id(index),
            "name": component["name"],
            "licenseConcluded": license_id,
            "licenseDeclared": license_id,
            "copyrightText": (
                "Copyright (c) 2026, RainBIOS contributors"
                if component["origin"] == "this repository"
                else "NOASSERTION"
            ),
            "downloadLocation": "NOASSERTION",
        }
        identity = component.get("source_identity")
        if identity:
            package["downloadLocation"] = identity["repository"]
            package["packageVersion"] = identity["commit"][:12]
        else:
            package["packageVersion"] = "this-repository"
        document["packages"].append(package)
        document["relationships"].append({
            "spdxElementId": "SPDXRef-DOCUMENT",
            "relationshipType": "DESCRIBES",
            "relatedSpdxElement": spdx_id(index),
        })

    # The packaged production ROMs as files.
    for relative in arguments.roms:
        rom = arguments.build / relative
        if not rom.is_file():
            print(f"error: missing ROM artifact: {rom}", file=sys.stderr)
            return 1
        document["files"].append({
            "SPDXID": f"SPDXRef-File-{relative}",
            "fileName": relative,
            "checksums": [{
                "algorithm": "SHA256",
                "checksumValue": sha256(rom),
            }],
            "licenseConcluded": "BSD-3-Clause",
            "copyrightText": "NOASSERTION",
        })
        document["relationships"].append({
            "spdxElementId": "SPDXRef-DOCUMENT",
            "relationshipType": "DESCRIBES",
            "relatedSpdxElement": f"SPDXRef-File-{relative}",
        })

    output = arguments.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")
    print(
        f"wrote SPDX document {output} with "
        f"{len(document['packages'])} packages and "
        f"{len(document['relationships'])} relationships"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
