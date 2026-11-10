# Create a Vivado project for QMTECH Wukong XC7A100T and build a bitstream.
# Usage (from repo root):
#   vivado -mode batch -source fpga/qmtech_wukong/create_vivado_project.tcl
#
# Or open GUI after project creation and run Synthesis → Implementation → Bitstream.

set repo_root [file normalize [file join [file dirname [info script]] ../..]]
set proj_dir  [file join $repo_root build/wukong]
set proj_name rvi20u32_wukong

file mkdir $proj_dir
create_project $proj_name $proj_dir -part xc7a100tfgg676-1 -force

set_property target_language VHDL [current_project]
set_property default_lib work [current_project]

# RTL
add_files -fileset sources_1 [glob -nocomplain \
  [file join $repo_root rtl/pkg/*.vhd] \
  [file join $repo_root rtl/core/*.vhd] \
  [file join $repo_root rtl/mem/*.vhd] \
  [file join $repo_root rtl/mmio/*.vhd] \
  [file join $repo_root fpga/qmtech_wukong/board_top.vhd]]

# IMEM init hex (copy beside run for relative generic path)
set hex_src [file join $repo_root sw/hex/uart_hello.hex]
set hex_dst [file join $proj_dir uart_hello.hex]
file copy -force $hex_src $hex_dst
add_files -fileset sources_1 $hex_dst

# Constraints
add_files -fileset constrs_1 [file join $repo_root fpga/qmtech_wukong/wukong.xdc]

set_property top board_top [current_fileset]
update_compile_order -fileset sources_1

# Point elaboration at the copied hex (generic default is uart_hello.hex)
set_property generic {IMEM_INIT_HEX=uart_hello.hex UART_CLKS_PER_BIT=434} [get_filesets sources_1]

puts "Project created at $proj_dir"
puts "Next: launch_runs synth_1; wait_on_run synth_1; ..."
puts "Or in GUI: Open Project → $proj_dir/$proj_name.xpr"

# Optional non-interactive build (comment out to stop after project create):
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# puts "Bitstream: [file join $proj_dir $proj_name.runs/impl_1/board_top.bit]"
