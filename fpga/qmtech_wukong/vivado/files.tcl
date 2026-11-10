# Explicit source list for the Wukong FPGA build (sourced by create_project.tcl).
# Paths are relative to the repository root ($repo_root).

set ::wukong_vhdl_sources [list \
  rtl/pkg/rv32_pkg.vhd \
  rtl/core/alu.vhd \
  rtl/core/csr_file.vhd \
  rtl/core/decode.vhd \
  rtl/core/forward_unit.vhd \
  rtl/core/hazard_unit.vhd \
  rtl/core/regfile.vhd \
  rtl/core/cpu_top.vhd \
  rtl/mem/imem.vhd \
  rtl/mem/dmem.vhd \
  rtl/mmio/mmio_leds.vhd \
  rtl/mmio/mmio_uart_tx.vhd \
  fpga/qmtech_wukong/board_top.vhd \
]

# Compliance / sim-only RTL intentionally omitted:
#   rtl/core/compliance_soc.vhd, rtl/mem/unified_ram.vhd

set ::wukong_xdc_files [list \
  fpga/qmtech_wukong/wukong.xdc \
]

# UART demo image (also copied into the generated project dir)
set ::wukong_hex_relpath sw/hex/uart_hello.hex
