#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Validate the openMSX BBC BASIC cassette SAVE probe."""

from __future__ import annotations

import argparse
import itertools
import pathlib
import statistics
import wave


def validate_report(text: str) -> dict[str, str]:
    values = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if separator:
            values[key] = value
    if values.get("STATUS") != "SUCCESS":
        raise ValueError(f"cassette SAVE did not succeed: {values.get('STATUS')!r}")
    if values.get("PC") != "4400" or values.get("MARKER") != "5A":
        raise ValueError("cassette SAVE success marker is missing")
    try:
        size = int(values["TAPE_SIZE"])
    except (KeyError, ValueError) as error:
        raise ValueError("missing cassette recording size") from error
    if size < 1024:
        raise ValueError(f"cassette recording is unexpectedly small: {size}")
    return values


def decode_recording(path: pathlib.Path, byte_count: int = 16) -> bytes:
    with wave.open(str(path), "rb") as recording:
        if (
            recording.getnchannels() != 1
            or recording.getsampwidth() != 1
            or recording.getframerate() != 44100
        ):
            raise ValueError("cassette recording is not 44.1 kHz, 8-bit mono")
        samples = recording.readframes(recording.getnframes())
    runs = [
        len(list(group))
        for _, group in itertools.groupby(sample >= 128 for sample in samples)
    ]
    if len(runs) < 100:
        raise ValueError("cassette recording has too few waveform transitions")
    short_period = statistics.median(runs)
    long_threshold = short_period * 1.6
    try:
        position = next(
            index
            for index, length in enumerate(runs)
            if index > 100 and length >= long_threshold
        )
    except StopIteration as error:
        raise ValueError("cassette recording has no framed data") from error

    def read_bit() -> int:
        nonlocal position
        long_bit = runs[position] >= long_threshold
        transition_count = 2 if long_bit else 4
        intervals = runs[position : position + transition_count]
        if len(intervals) != transition_count:
            raise ValueError("cassette recording ends inside a bit")
        if any((length >= long_threshold) != long_bit for length in intervals):
            raise ValueError("cassette recording has an invalid FSK bit")
        position += transition_count
        return 0 if long_bit else 1

    decoded = bytearray()
    for _ in range(byte_count):
        if read_bit() != 0:
            raise ValueError("cassette byte has no start bit")
        value = sum(read_bit() << bit for bit in range(8))
        if read_bit() != 1 or read_bit() != 1:
            raise ValueError("cassette byte has invalid stop bits")
        decoded.append(value)
    return bytes(decoded)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--tape", type=pathlib.Path, required=True)
    arguments = parser.parse_args()
    try:
        values = validate_report(arguments.report.read_text(encoding="utf-8"))
        decoded = decode_recording(arguments.tape)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    expected = bytes([0xD0] * 10) + b"SAVET "
    if decoded != expected:
        parser.error(
            "cassette recording header mismatch: "
            f"{decoded.hex(' ')} != {expected.hex(' ')}"
        )
    print(
        "validated BBC BASIC cassette SAVE in openMSX: "
        f"{values['TAPE_SIZE']} byte recording, D0/SAVET header decoded"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
