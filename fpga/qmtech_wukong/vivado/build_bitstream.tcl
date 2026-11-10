# Build bitstream for an existing (or freshly created) Wukong project.
#
#   vivado -mode batch -source fpga/qmtech_wukong/vivado/build_bitstream.tcl
#
# Creates the project if missing, then runs synth → impl → bitstream.

set script_dir [file normalize [file dirname [info script]]]
set proj_dir   [file join $script_dir proj]
set proj_name  rvi20u32_wukong
set xpr        [file join $proj_dir ${proj_name}.xpr]

if {![file exists $xpr]} {
  puts "No project yet — running create_project.tcl first..."
  source [file join $script_dir create_project.tcl]
}

open_project $xpr

reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set status [get_property STATUS [get_runs impl_1]]
puts "impl_1 STATUS = $status"
if {[string match "*Complete*" $status] == 0 && [string match "*write_bitstream*" $status] == 0} {
  # STATUS often ends with "write_bitstream Complete!" when OK
  if {![string match -nocase "*complete*" $status]} {
    error "Implementation/bitstream failed: $status"
  }
}

set bit [file join $proj_dir ${proj_name}.runs/impl_1/board_top.bit]
set bin [file join $proj_dir ${proj_name}.runs/impl_1/board_top.bin]
puts "Bitstream: $bit"
if {[file exists $bin]} {
  puts "Bin file : $bin"
}
puts "Done."
