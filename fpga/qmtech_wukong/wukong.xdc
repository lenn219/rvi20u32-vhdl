## QMTECH Wukong Artix-7 XC7A100T (FGG676)
## Default: board revision V2 pinout (clk M21, LEDs V16/V17, reset M6).
## Part suggestion: xc7a100tfgg676-1 (also works as -2).
##
## Sources cross-checked against:
##   - litex-hub/litex-boards platforms/qmtech_wukong.py (_io_v2 + _io_common)
##   - community boards using FTDI/CP2102 USB-UART on E3/F3
##
## V3 note: user LEDs move to G21/G20 — uncomment the V3 LED block if needed.
## V1 note: clk is M22, reset J8, LEDs J6/H6 — different XDC required.

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# -----------------------------------------------------------------------------
# 50 MHz system clock (onboard oscillator)
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]
create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]

# -----------------------------------------------------------------------------
# Reset — Key1, active-low (cpu_reset_n)
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN M6 IOSTANDARD LVCMOS33} [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]
set_false_path -from [get_ports rst_n]

# -----------------------------------------------------------------------------
# User LEDs (V2) — active-low
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[1]}]
# V3 LEDs (uncomment and comment V2 pins above if your silkscreen/rev is V3):
# set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
# set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[1]}]
set_false_path -to [get_ports {led[*]}]

# -----------------------------------------------------------------------------
# Onboard USB-UART (shared across Wukong revisions)
# LiteX "serial.tx" = FPGA transmit → host  => our uart_tx on E3
# LiteX "serial.rx" = FPGA receive  ← host  => our uart_rx on F3
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_false_path -to [get_ports uart_tx]
set_false_path -from [get_ports uart_rx]
