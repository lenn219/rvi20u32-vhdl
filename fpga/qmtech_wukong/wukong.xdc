################################################################################
# QMTECH Wukong — Artix-7 XC7A100T FGG676
# Full constraints for board_top (this design) + verified pin reference.
#
# Default target: board revision **V2 / V3** (clk M21). V1 differs (see bottom).
# Part suggestion: xc7a100tfgg676-1
#
# Cross-checked against (all agree on UART E3/F3 and V2/V3 clk M21):
#   1) ChinaQMTECH schematics
#        V2: QMTECH-XC7A100T_200T-Wukong-Board-V02-20210426.pdf
#        V3: QMTECH-XC7A100T_200T-Wukong-Board-V03-20240121.pdf
#   2) Official QMTECH Vivado demos
#        V2 Test01_led_key  → clk M21, rst H7, LED V17/V16
#        V2 Test05_usb_uart → uart_tx E3, uart_rx F3, clk M21, rst H7
#        V3 Test01_led_key  → clk M21, rst H7, LED G21/G20
#   3) litex-hub/litex-boards platforms/qmtech_wukong.py
#        _io_v2 / _io_v3 / _io_common
#
# Silk LEDs (NOT all are FPGA user LEDs):
#   D1 = DONE          — always ON after successful configuration
#   D4 = 3V3 rail      — always ON when board is powered
#   D5 = user LED0     — active-low (FPGA sinks)
#   D6 = user LED1     — active-low (FPGA sinks)
#
# USB:
#   Mini-USB = UART bridge only (CP2102 on V2, CH340N on V3) → /dev/ttyUSB0
#   JTAG     = separate Platform Cable (not the UART tty)
#
# board_top ports constrained below:
#   clk_50mhz, key0_n, key1_n, led_v2[1:0], led_v3[1:0], uart_tx, uart_rx
################################################################################

# =============================================================================
# Bitstream / configuration
# =============================================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
# Quad SPI flash boot (Micron / Winbond on board). Safe default for Wukong.
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

# =============================================================================
# Clock — 50 MHz oscillator
#   V2/V3: M21  (bank 14, MRCC — dedicated clock route OK; do NOT set
#                CLOCK_DEDICATED_ROUTE FALSE)
#   V1:    M22  (see V1 appendix; needs CLOCK_DEDICATED_ROUTE FALSE)
# =============================================================================
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]
create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]

# Single clock domain in board_top: CPU + UART @ 50 MHz.
# UART baud: CLKS_PER_BIT = round(50e6/9600) = 5208.

# =============================================================================
# User keys — active-low (pressed = 0)
#   Key0 = H7   (QMTECH demos use this as sys_rst_n; LiteX "user_btn")
#   Key1 = M6   (LiteX "cpu_reset_n" on V2/V3)
# board_top ORs both into async reset.
# =============================================================================
set_property -dict {PACKAGE_PIN H7 IOSTANDARD LVCMOS33} [get_ports key0_n]
set_property -dict {PACKAGE_PIN M6 IOSTANDARD LVCMOS33} [get_ports key1_n]
set_property PULLUP true [get_ports key0_n]
set_property PULLUP true [get_ports key1_n]
set_false_path -from [get_ports {key0_n key1_n}]

# =============================================================================
# User LEDs — active-low (drive 0 = LED on)
#
#   This design drives BOTH revision pin pairs from the same logic so either
#   V2 or V3 board lights D5/D6. Unused pair is harmless (header/unconnected).
#
#   Mapping (matches LiteX user_led indices):
#     led_v2[0] = V16 = LED0 (D5) on V2
#     led_v2[1] = V17 = LED1 (D6) on V2
#     led_v3[0] = G21 = LED0 (D5) on V3
#     led_v3[1] = G20 = LED1 (D6) on V3
#
#   Note: QMTECH Test01 vector indexing is swapped vs LiteX
#   (their led_1[0]=V17, led_1[1]=V16) — same two pins, opposite index names.
# =============================================================================
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v2[0]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v2[1]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v3[0]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v3[1]}]
set_false_path -to [get_ports {led_v2[*] led_v3[*]}]

# =============================================================================
# Onboard USB-UART (identical V1/V2/V3)
#   FPGA uart_tx  E3  →  bridge RXD   (host receives)
#   FPGA uart_rx  F3  ←  bridge TXD   (host transmits)
# Matches LiteX serial.{tx,rx} and QMTECH Test05 uart_{tx,rx}.
# Idle = high, 8N1, board_top default 9600 (CLKS_PER_BIT=5208 @ 50 MHz).
# =============================================================================
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property PULLUP true [get_ports uart_rx]
set_false_path -to   [get_ports uart_tx]
set_false_path -from [get_ports uart_rx]

################################################################################
# REFERENCE ONLY — not ports of board_top (do not uncomment unless you add RTL)
################################################################################
#
# --- V1 differences (legacy) ---
#   clk50        M22     (set CLOCK_DEDICATED_ROUTE FALSE on that net)
#   cpu_reset_n  J8      (also SD CMD on later revs — V1 only)
#   user_led0    J6
#   user_led1    H6
#
# --- SPI flash (config; bitstream SPI_BUSWIDTH 4 already set) ---
#   cs_n  P18
#   clk   H13
#   mosi  R14
#   miso  R15
#   wp    P14
#   hold  N14
#
# --- microSD (V2/V3) ---
#   data  M5 M7 H6 J6
#   cmd   J8
#   clk   L4
#   cd    N6
#
# --- PMOD / headers (LiteX connector names) ---
#   j10 (PMOD): D5 G5 G7 G8 E5 E6 D6 G6
#   j11 (PMOD): H4 F4 A4 A5 J4 G4 B4 B5
#   j12:        AB26 AC26 … (see LiteX qmtech_wukong.py)
#   jp2:        H21 H22 K21 J21 … G20 G21 … (V3 LEDs moved onto former JP2 nets)
#   jp3:        AF7 AE7 …
#
# --- Ethernet PHY / HDMI / DDR3 ---
#   See LiteX qmtech_wukong.py _io_common (large pin lists). Not used by this SoC.
#
################################################################################
