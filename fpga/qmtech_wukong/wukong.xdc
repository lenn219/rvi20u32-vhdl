## QMTECH Wukong Artix-7 XC7A100T (FGG676)
## Pins cross-checked against:
##   - ChinaQMTECH schematics V2 (2021-04) / V3 (2024-01)
##   - Official QMTECH Test01_led_key + Test05_usb_uart demos
##   - litex-hub/litex-boards platforms/qmtech_wukong.py (_io_v1/v2/v3 + _io_common)
##
## Silk LEDs (not all are FPGA user LEDs):
##   D1 = DONE (config complete) — always ON after successful program
##   D4 = 3.3 V rail indicator — always ON when board powered
##   D5 = LED0 (user), D6 = LED1 (user) — active-low
##
## USB:
##   Mini-USB = onboard UART bridge only (CP2102 on V2, CH340N on V3).
##   That is typically the single /dev/ttyUSB0. JTAG is a separate cable
##   (Platform Cable / compatible) and does NOT create ttyUSB for UART.

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# -----------------------------------------------------------------------------
# 50 MHz system clock (onboard oscillator) — V2/V3: M21 (V1 was M22)
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]
create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]

# -----------------------------------------------------------------------------
# Keys — active-low (either resets the design)
#   Key0 = H7 (QMTECH demo reset), Key1 = M6 (LiteX cpu_reset_n)
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN H7 IOSTANDARD LVCMOS33} [get_ports key0_n]
set_property -dict {PACKAGE_PIN M6 IOSTANDARD LVCMOS33} [get_ports key1_n]
set_property PULLUP true [get_ports key0_n]
set_property PULLUP true [get_ports key1_n]
set_false_path -from [get_ports key0_n]
set_false_path -from [get_ports key1_n]

# -----------------------------------------------------------------------------
# User LEDs — active-low. Drive BOTH rev pin pairs (harmless on the unused pair).
#   V2: LED0/LED1 = V16 / V17
#   V3: LED0/LED1 = G21 / G20   (official demo: led[0]=G21, led[1]=G20)
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v2[0]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v2[1]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v3[0]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v3[1]}]
set_false_path -to [get_ports {led_v2[*]}]
set_false_path -to [get_ports {led_v3[*]}]

# -----------------------------------------------------------------------------
# Onboard USB-UART (same pins V1/V2/V3)
#   FPGA uart_tx (E3) → bridge RXD
#   FPGA uart_rx (F3) ← bridge TXD
# Matches LiteX serial.{tx,rx} and QMTECH Test05 uart_{tx,rx}.
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property PULLUP true [get_ports uart_rx]
set_false_path -to [get_ports uart_tx]
set_false_path -from [get_ports uart_rx]
