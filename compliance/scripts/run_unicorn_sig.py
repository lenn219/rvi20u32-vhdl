#!/usr/bin/env python3
"""Run an arch-test ELF on Unicorn (RV32I) and dump begin_signature..end_signature."""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

from elftools.elf.elffile import ELFFile
from unicorn import Uc, UcError, UC_ARCH_RISCV, UC_MODE_RISCV32, UC_HOOK_MEM_WRITE, UC_MEM_WRITE
from unicorn.riscv_const import UC_RISCV_REG_PC

RAM_BASE = 0x80000000
RAM_SIZE = 0x100000


def main() -> None:
    elf_path = Path(sys.argv[1])
    out_sig = Path(sys.argv[2])
    meta_path = elf_path.parent / "meta.json"
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}

    mu = Uc(UC_ARCH_RISCV, UC_MODE_RISCV32)
    mu.mem_map(RAM_BASE, RAM_SIZE)

    with elf_path.open("rb") as f:
        elf = ELFFile(f)
        symbols = {
            s.name: s["st_value"]
            for s in elf.get_section_by_name(".symtab").iter_symbols()
        }
        for seg in elf.iter_segments():
            if seg["p_type"] == "PT_LOAD":
                mu.mem_write(seg["p_vaddr"], seg.data())

    tohost = symbols["tohost"]
    begin_sig = symbols["begin_signature"]
    end_sig = symbols["end_signature"]
    entry = symbols.get("rvtest_entry_point", RAM_BASE)

    halt = {"v": 0}

    def on_write(uc, access, address, size, value, user):
        if address == tohost and access == UC_MEM_WRITE and value != 0:
            halt["v"] = value
            uc.emu_stop()

    mu.hook_add(UC_HOOK_MEM_WRITE, on_write)
    try:
        mu.emu_start(entry, RAM_BASE + RAM_SIZE, timeout=30_000_000)
    except UcError as e:
        print(f"unicorn error: {e} pc={mu.reg_read(UC_RISCV_REG_PC):#x}", file=sys.stderr)
        sys.exit(2)

    if halt["v"] == 0:
        print("did not hit tohost", file=sys.stderr)
        sys.exit(3)

    sig = mu.mem_read(begin_sig, end_sig - begin_sig)
    lines = []
    for i in range(0, len(sig), 4):
        (w,) = struct.unpack("<I", sig[i : i + 4])
        lines.append(f"{w:08x}")
    out_sig.write_text("\n".join(lines) + "\n")
    print(f"wrote {out_sig} ({len(lines)} words) tohost={halt['v']}")


if __name__ == "__main__":
    main()
