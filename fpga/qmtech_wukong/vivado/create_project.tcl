# =============================================================================
# Create a reproducible Vivado project for QMTECH Wukong XC7A100T
# =============================================================================
#
# From the repository root (Windows or Linux):
#
#   vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
#
# Or inside the Vivado TCL Console:
#
#   cd <path-to-repo>
#   source fpga/qmtech_wukong/vivado/create_project.tcl
#
# Then open:
#   fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr
#
# Part: xc7a100tfgg676-1  |  Top: board_top  |  Demo: uart_hello @ 115200 8N1
# =============================================================================

set script_dir [file normalize [file dirname [info script]]]
set repo_root  [file normalize [file join $script_dir ../../..]]

# Generated project lives next to these scripts (gitignored)
set proj_dir  [file join $script_dir proj]
set proj_name rvi20u32_wukong
set part      xc7a100tfgg676-1

source [file join $script_dir files.tcl]

puts "============================================================"
puts " repo_root : $repo_root"
puts " proj_dir  : $proj_dir"
puts " part      : $part"
puts "============================================================"

file mkdir $proj_dir

# Close any open project so -force recreate is clean
catch {close_project}

create_project $proj_name $proj_dir -part $part -force

set_property target_language VHDL [current_project]
set_property default_lib work [current_project]
set_property simulator_language Mixed [current_project]

# ----- VHDL sources (explicit list) -----
set abs_sources {}
foreach rel $::wukong_vhdl_sources {
  set f [file join $repo_root $rel]
  if {![file exists $f]} {
    error "Missing VHDL source: $f"
  }
  lappend abs_sources $f
}
add_files -fileset sources_1 $abs_sources
set_property file_type {VHDL 2008} [get_files -of_objects [get_filesets sources_1] *.vhd]

# ----- Constraints -----
foreach rel $::wukong_xdc_files {
  set f [file join $repo_root $rel]
  if {![file exists $f]} {
    error "Missing XDC: $f"
  }
  add_files -fileset constrs_1 $f
}

# ----- UART demo hex (reference copy only; IMEM uses embedded array in imem.vhd) -----
set hex_src [file join $repo_root $::wukong_hex_relpath]
if {![file exists $hex_src]} {
  error "Missing hex: $hex_src"
}
set hex_local [file join $script_dir uart_hello.hex]
file copy -force $hex_src $hex_local
set hex_proj [file join $proj_dir uart_hello.hex]
file copy -force $hex_src $hex_proj
add_files -fileset sources_1 $hex_proj
set_property file_type {Memory Initialization Files} [get_files $hex_proj]

# Embedded boot token "uart_hello" is a constant array inside rtl/mem/imem.vhd
set_property generic {IMEM_INIT_HEX=uart_hello UART_CLKS_PER_BIT=434} [get_filesets sources_1]

set_property top board_top [current_fileset]
update_compile_order -fileset sources_1

# Helpful project properties
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

set xpr [file join $proj_dir ${proj_name}.xpr]
puts ""
puts "Project created successfully."
puts "  XPR : $xpr"
puts "  TOP : board_top"
puts "  IMEM: embedded uart_hello inside imem.vhd ; ref copy $hex_proj"
puts ""
puts "Next steps:"
puts "  1. Open $xpr in Vivado  (or leave this batch open)"
puts "  2. Flow Navigator → Generate Bitstream"
puts "  3. Program device; open serial 115200 8N1"
puts ""
puts "Optional batch bitstream:"
puts "  vivado -mode batch -source fpga/qmtech_wukong/vivado/build_bitstream.tcl"
puts "============================================================"
