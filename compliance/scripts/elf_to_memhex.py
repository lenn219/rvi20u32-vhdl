#!/usr/bin/env python3
"""Flatten PT_LOAD segments of an arch-test ELF into ram.hex + meta.json."""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

from elftools.elf.elffile import ELFFile

RAM_BASE = 0x80000000


def words_from_bytes(data: bytes) -> list[str]:
    if len(data) % 4:
        data += b"\x00" * (4 - len(data) % 4)
    out = []
    for i in range(0, len(data), 4):
        (w,) = struct.unpack("<I", data[i : i + 4])
        out.append(f"{w:08x}")
    return out


def main() -> None:
    elf_path = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    with elf_path.open("rb") as f:
        elf = ELFFile(f)
        symbols = {}
        symtab = elf.get_section_by_name(".symtab")
        if symtab is not None:
            for s in symtab.iter_symbols():
                symbols[s.name] = s["st_value"]

        ram = bytearray()
        for seg in elf.iter_segments():
            if seg["p_type"] != "PT_LOAD":
                continue
            addr = seg["p_vaddr"]
            data = seg.data()
            if addr < RAM_BASE:
                raise SystemExit(f"unexpected load address {addr:#x}")
            off = addr - RAM_BASE
            end = off + len(data)
            if end > len(ram):
                ram.extend(b"\x00" * (end - len(ram)))
            ram[off : off + len(data)] = data

    (out_dir / "ram.hex").write_text("\n".join(words_from_bytes(bytes(ram))) + "\n")
    meta = {
        "ram_base": RAM_BASE,
        "begin_signature": symbols.get("begin_signature"),
        "end_signature": symbols.get("end_signature"),
        "tohost": symbols.get("tohost"),
        "entry": symbols.get("rvtest_entry_point", RAM_BASE),
        "ram_bytes": len(ram),
    }
    (out_dir / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    print(json.dumps(meta))


if __name__ == "__main__":
    main()
