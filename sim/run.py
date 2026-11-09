#!/usr/bin/env python3
"""VUnit entry point for rvi20u32-vhdl."""
from pathlib import Path
from vunit import VUnit

ROOT = Path(__file__).resolve().parents[1]

vu = VUnit.from_argv()
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files(str(ROOT / "rtl" / "pkg" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "core" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "mem" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "mmio" / "*.vhd"))
lib.add_source_files(str(ROOT / "tb" / "tb_*.vhd"))

vu.main()
