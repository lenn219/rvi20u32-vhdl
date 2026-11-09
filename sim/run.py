#!/usr/bin/env python3
"""VUnit entry point for rvi20u32-vhdl."""
from pathlib import Path
from vunit import VUnit

ROOT = Path(__file__).resolve().parents[1]
ADDI_WORK = ROOT / "compliance" / "work" / "addi-01"

vu = VUnit.from_argv()
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files(str(ROOT / "rtl" / "pkg" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "core" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "mem" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "mmio" / "*.vhd"))
lib.add_source_files(str(ROOT / "tb" / "tb_*.vhd"))

# Point arch-test TB at absolute build artifacts when present
addi_tb = lib.test_bench("tb_arch_addi")
if (ADDI_WORK / "ram.hex").exists() and (ADDI_WORK / "ref.signature").exists():
    import json

    meta = json.loads((ADDI_WORK / "meta.json").read_text())
    addi_tb.set_generic("ram_hex", str(ADDI_WORK / "ram.hex"))
    addi_tb.set_generic("ref_sig", str(ADDI_WORK / "ref.signature"))
    addi_tb.set_generic("tohost_hex", f"{int(meta['tohost']):08X}")
    addi_tb.set_generic("begin_hex", f"{int(meta['begin_signature']):08X}")
    addi_tb.set_generic("end_hex", f"{int(meta['end_signature']):08X}")

vu.main()
