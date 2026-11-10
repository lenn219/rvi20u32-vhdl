# Compatibility wrapper — prefer the vivado/ package:
#   vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
#
# This file forwards to that script so older docs still work.

set here [file normalize [file dirname [info script]]]
source [file join $here vivado/create_project.tcl]
