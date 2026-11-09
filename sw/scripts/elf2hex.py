#!/usr/bin/env python3
"""Convert a flat binary (or ELF .text dump) to word-oriented hex for IMEM init."""
from __future__ import annotations

import argparse
from pathlib import Path


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("binary", type=Path, help="Flat little-endian machine code")
    p.add_argument("-o", "--output", type=Path, required=True)
    p.add_argument("--pad-words", type=int, default=0, help="Pad with zeros to N words")
    args = p.parse_args()

    data = args.binary.read_bytes()
    if len(data) % 4:
        data += b"\x00" * (4 - len(data) % 4)

    words = []
    for i in range(0, len(data), 4):
        w = int.from_bytes(data[i : i + 4], "little")
        words.append(f"{w:08x}")

    if args.pad_words > len(words):
        words.extend(["00000000"] * (args.pad_words - len(words)))

    args.output.write_text("\n".join(words) + "\n")
    print(f"Wrote {len(words)} words -> {args.output}")


if __name__ == "__main__":
    main()
