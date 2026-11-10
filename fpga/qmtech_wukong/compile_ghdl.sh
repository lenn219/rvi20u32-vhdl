#!/usr/bin/env bash
# Analyze Wukong FPGA RTL with GHDL (no Vivado required).
# Exits non-zero on any analysis error.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

# Dependency order (packages → leaves → cpu_top → board_top)
files=(
  "$ROOT/rtl/pkg/rv32_pkg.vhd"
  "$ROOT/rtl/core/alu.vhd"
  "$ROOT/rtl/core/csr_file.vhd"
  "$ROOT/rtl/core/decode.vhd"
  "$ROOT/rtl/core/forward_unit.vhd"
  "$ROOT/rtl/core/hazard_unit.vhd"
  "$ROOT/rtl/core/regfile.vhd"
  "$ROOT/rtl/mem/imem.vhd"
  "$ROOT/rtl/mem/dmem.vhd"
  "$ROOT/rtl/mmio/mmio_leds.vhd"
  "$ROOT/rtl/mmio/mmio_uart_tx.vhd"
  "$ROOT/rtl/core/cpu_top.vhd"
  "$ROOT/fpga/qmtech_wukong/board_top.vhd"
)

echo "GHDL analyze (VHDL-2008) — Wukong board_top + deps"
ghdl -a --std=08 "${files[@]}"
echo "OK: all files analyzed"
echo "compile_ghdl.sh passed"
