#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate that an openMSX WAV capture contains a non-silent startup jingle."""

from __future__ import annotations

import argparse
from array import array
from pathlib import Path
import sys
import wave


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=Path)
    args = parser.parse_args()

    with wave.open(str(args.capture), "rb") as recording:
        channels = recording.getnchannels()
        sample_width = recording.getsampwidth()
        sample_rate = recording.getframerate()
        frame_count = recording.getnframes()
        frames = recording.readframes(frame_count)

    if sample_width != 2:
        raise SystemExit(f"expected 16-bit PCM, got {sample_width * 8}-bit samples")
    if channels not in (1, 2):
        raise SystemExit(f"expected mono or stereo PCM, got {channels} channels")
    duration = frame_count / sample_rate
    if duration < 0.25:
        raise SystemExit(f"audio capture is too short ({duration:.3f} seconds)")

    samples = array("h")
    samples.frombytes(frames)
    if sys.byteorder != "little":
        samples.byteswap()
    peak = max((abs(sample) for sample in samples), default=0)
    active_samples = sum(abs(sample) >= 64 for sample in samples)
    if peak < 256 or active_samples < sample_rate // 100:
        raise SystemExit(
            "audio capture is effectively silent "
            f"(peak={peak}, active_samples={active_samples})"
        )

    print(
        "validated startup audio: "
        f"{args.capture} ({duration:.3f}s, {sample_rate} Hz, peak={peak})"
    )


if __name__ == "__main__":
    main()
