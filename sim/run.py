#!/usr/bin/env python3
"""VUnit entry point for rvi20u32-vhdl."""
from pathlib import Path
from vunit import VUnit

ROOT = Path(__file__).resolve().parents[1]
import json

vu = VUnit.from_argv()
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files(str(ROOT / "rtl" / "pkg" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "core" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "mem" / "*.vhd"))
lib.add_source_files(str(ROOT / "rtl" / "mmio" / "*.vhd"))
lib.add_source_files(str(ROOT / "tb" / "tb_*.vhd"))


def wire_arch_tb(tb_name: str, work_name: str) -> None:
    work = ROOT / "compliance" / "work" / work_name
    if not ((work / "ram.hex").exists() and (work / "ref.signature").exists()):
        return
    meta = json.loads((work / "meta.json").read_text())
    tb = lib.test_bench(tb_name)
    tb.set_generic("ram_hex", str(work / "ram.hex"))
    tb.set_generic("ref_sig", str(work / "ref.signature"))
    tb.set_generic("tohost_hex", f"{int(meta['tohost']):08X}")
    tb.set_generic("begin_hex", f"{int(meta['begin_signature']):08X}")
    tb.set_generic("end_hex", f"{int(meta['end_signature']):08X}")


wire_arch_tb("tb_arch_addi", "addi-01")
wire_arch_tb("tb_arch_mul", "mul-01")


def wire_configs(tb_name: str, work_names: tuple[str, ...]) -> None:
    tb = lib.test_bench(tb_name)
    for work_name in work_names:
        work = ROOT / "compliance" / "work" / work_name
        if not ((work / "ram.hex").exists() and (work / "ref.signature").exists()):
            continue
        meta = json.loads((work / "meta.json").read_text())
        tb.add_config(
            name=work_name.replace("-", "_"),
            generics=dict(
                ram_hex=str(work / "ram.hex"),
                ref_sig=str(work / "ref.signature"),
                tohost_hex=f"{int(meta['tohost']):08X}",
                begin_hex=f"{int(meta['begin_signature']):08X}",
                end_hex=f"{int(meta['end_signature']):08X}",
            ),
        )


wire_configs(
    "tb_arch_m",
    (
        "mul-01",
        "mulh-01",
        "mulhsu-01",
        "mulhu-01",
        "div-01",
        "divu-01",
        "rem-01",
        "remu-01",
    ),
)
wire_configs("tb_arch_privilege", ("ecall", "ebreak"))

vu.main()
