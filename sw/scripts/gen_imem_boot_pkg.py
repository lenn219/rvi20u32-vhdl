#!/usr/bin/env python3
"""Refresh the embedded uart_hello image inside rtl/mem/imem.vhd."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HEX = ROOT / "sw" / "hex" / "uart_hello.hex"
IMEM = ROOT / "rtl" / "mem" / "imem.vhd"


def main() -> None:
    words: list[str] = []
    for line in HEX.read_text().splitlines():
        line = line.strip()
        if len(line) >= 8 and all(c in "0123456789abcdefABCDEF" for c in line[:8]):
            words.append(line[:8].lower())
    if not words:
        raise SystemExit(f"no words in {HEX}")
    while len(words) < 32:
        words.append("00000013")

    body = ",\n".join(f'    {i} => x"{w}"' for i, w in enumerate(words))
    text = IMEM.read_text()
    pat = re.compile(
        r"(-- BEGIN_IMEM_BOOT_IMAGE\n)(.*?)(\n    -- END_IMEM_BOOT_IMAGE)",
        re.S,
    )
    if not pat.search(text):
        raise SystemExit(f"markers missing in {IMEM}")
    # Also keep LEN in sync
    text = re.sub(
        r"constant IMEM_BOOT_LEN : natural := \d+;",
        f"constant IMEM_BOOT_LEN : natural := {len(words)};",
        text,
        count=1,
    )
    text = pat.sub(rf"\1{body}\3", text)
    IMEM.write_text(text)
    print(f"updated {IMEM.relative_to(ROOT)} ({len(words)} words)")


if __name__ == "__main__":
    main()
