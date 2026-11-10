################################################################################
# QMTECH Wukong — Artix-7 XC7A100T FGG676 — FULL BOARD XDC
#
# Active section: ports of board_top (this SoC bring-up design).
# Catalog section: every other onboard / header pin as commented constraints.
# Uncomment catalog lines only after you add matching RTL ports — Vivado errors
# on get_ports that do not exist.
#
# Default revision: **V2 / V3** (50 MHz on M21). V1 differences at bottom.
# Part: xc7a100tfgg676-1  (some boards are -2; LiteX defaults to -2)
#
# Cross-checked against:
#   • ChinaQMTECH schematic V02-20210426 / V03-20240121
#   • Official demos: Test01_led_key, Test05_usb_uart, Test06_HDMI_OUT,
#     Test08_GMII_Ethernet, DDR3.ucf
#   • litex-hub/litex-boards platforms/qmtech_wukong.py
#   • DRubioG/XDC_WUKONG_QMTECH (header pin numbers; V1 clock/LED — see notes)
#
# Silk LEDs:
#   D1 = DONE (config)   D4 = 3V3 rail   D5 = user LED0   D6 = user LED1
# Mini-USB = UART bridge only (CP2102 V2 / CH340N V3). JTAG is separate.
################################################################################

# =============================================================================
# Bitstream / configuration  (matches QMTECH Test06 defaults)
# =============================================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]

################################################################################
# ACTIVE — board_top ports (do not comment these out)
################################################################################

# -----------------------------------------------------------------------------
# 50 MHz oscillator — V2/V3: M21 (bank 14 MRCC). Do NOT set
# CLOCK_DEDICATED_ROUTE FALSE here (that is only needed for V1 M22).
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]
create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]
# board_top: CPU + UART @ 50 MHz; UART CLKS_PER_BIT = 5208 → 9600 8N1

# -----------------------------------------------------------------------------
# Keys — active-low (pressed = 0). board_top ORs both into async reset.
#   Key0 H7 = QMTECH demo sys_rst_n / LiteX user_btn
#   Key1 M6 = LiteX cpu_reset_n (V2/V3)
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN H7 IOSTANDARD LVCMOS33} [get_ports key0_n]
set_property -dict {PACKAGE_PIN M6 IOSTANDARD LVCMOS33} [get_ports key1_n]
set_property PULLUP true [get_ports key0_n]
set_property PULLUP true [get_ports key1_n]
set_false_path -from [get_ports {key0_n key1_n}]

# -----------------------------------------------------------------------------
# User LEDs — active-low. Drive BOTH rev pairs so V2 or V3 lights D5/D6.
#   V2: led_v2[0]=V16 (D5), led_v2[1]=V17 (D6)   — LiteX user_led
#   V3: led_v3[0]=G21 (D5), led_v3[1]=G20 (D6)   — LiteX + V3 Test01
# QMTECH Test01 V2 indexes are swapped (led_1[0]=V17, led_1[1]=V16) — same pins.
# WARNING: on V3, G20/G21 are the user LEDs (were JP2 pins 11/12 on V2).
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v2[0]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v2[1]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v3[0]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led_v3[1]}]
set_false_path -to [get_ports {led_v2[*] led_v3[*]}]

# -----------------------------------------------------------------------------
# Onboard USB-UART (same V1/V2/V3) — Test05 + LiteX serial
#   uart_tx E3 → bridge RXD    uart_rx F3 ← bridge TXD
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property PULLUP true [get_ports uart_rx]
set_false_path -to   [get_ports uart_tx]
set_false_path -from [get_ports uart_rx]

################################################################################
# CATALOG — not in board_top. Uncomment + rename ports to match your RTL.
################################################################################

# =============================================================================
# SPI flash (config device; bitstream already SPI×4)
# LiteX: cs_n P18, clk H13, mosi R14, miso R15, wp P14, hold N14
# =============================================================================
#set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports spi_flash_cs_n]
#set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports spi_flash_clk]
#set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports spi_flash_mosi]
#set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports spi_flash_miso]
#set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports spi_flash_wp]
#set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports spi_flash_hold]
## QSPI alias: dq = {mosi, miso, wp, hold} = R14 R15 P14 N14

# =============================================================================
# microSD (V2/V3) — LiteX sdcard mapping
#   data[3:0] = M5 M7 H6 J6   cmd = J8   clk = L4   cd = N6
# =============================================================================
#set_property -dict {PACKAGE_PIN M5 IOSTANDARD LVCMOS33} [get_ports {sd_data[0]}]
#set_property -dict {PACKAGE_PIN M7 IOSTANDARD LVCMOS33} [get_ports {sd_data[1]}]
#set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports {sd_data[2]}]
#set_property -dict {PACKAGE_PIN J6 IOSTANDARD LVCMOS33} [get_ports {sd_data[3]}]
#set_property -dict {PACKAGE_PIN J8 IOSTANDARD LVCMOS33} [get_ports sd_cmd]
#set_property -dict {PACKAGE_PIN L4 IOSTANDARD LVCMOS33} [get_ports sd_clk]
#set_property -dict {PACKAGE_PIN N6 IOSTANDARD LVCMOS33} [get_ports sd_cd]

# =============================================================================
# PMOD J10  (corner) — LiteX "j10": D5 G5 G7 G8 E5 E6 D6 G6
# Header: 1=D5 2=G5 3=G7 4=G8 | 7=E5 8=E6 9=D6 10=G6 | 5,11=GND 6,12=3V3
# =============================================================================
#set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {j10[0]}]
#set_property -dict {PACKAGE_PIN G5 IOSTANDARD LVCMOS33} [get_ports {j10[1]}]
#set_property -dict {PACKAGE_PIN G7 IOSTANDARD LVCMOS33} [get_ports {j10[2]}]
#set_property -dict {PACKAGE_PIN G8 IOSTANDARD LVCMOS33} [get_ports {j10[3]}]
#set_property -dict {PACKAGE_PIN E5 IOSTANDARD LVCMOS33} [get_ports {j10[4]}]
#set_property -dict {PACKAGE_PIN E6 IOSTANDARD LVCMOS33} [get_ports {j10[5]}]
#set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS33} [get_ports {j10[6]}]
#set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports {j10[7]}]

# =============================================================================
# PMOD J11  (middle) — LiteX "j11": H4 F4 A4 A5 J4 G4 B4 B5
# Header: 1=H4 2=F4 3=A4 4=A5 | 7=J4 8=G4 9=B4 10=B5 | 5,11=GND 6,12=3V3
# =============================================================================
#set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {j11[0]}]
#set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports {j11[1]}]
#set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {j11[2]}]
#set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports {j11[3]}]
#set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {j11[4]}]
#set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {j11[5]}]
#set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports {j11[6]}]
#set_property -dict {PACKAGE_PIN B5 IOSTANDARD LVCMOS33} [get_ports {j11[7]}]

# =============================================================================
# JP2  (2×9 camera / GPIO header) — LiteX "jp2"
#   pin3..18: H21 H22 K21 J21 H26 G26 G25 F25 G20 G21 F23 E23 E26 D26 E25 D25
# pin1=3V3 pin2=GND
# V3 NOTE: G20/G21 are USER LEDs — do not also drive them as JP2 GPIO on V3.
# =============================================================================
#set_property -dict {PACKAGE_PIN H21 IOSTANDARD LVCMOS33} [get_ports {jp2[0]}]
#set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS33} [get_ports {jp2[1]}]
#set_property -dict {PACKAGE_PIN K21 IOSTANDARD LVCMOS33} [get_ports {jp2[2]}]
#set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports {jp2[3]}]
#set_property -dict {PACKAGE_PIN H26 IOSTANDARD LVCMOS33} [get_ports {jp2[4]}]
#set_property -dict {PACKAGE_PIN G26 IOSTANDARD LVCMOS33} [get_ports {jp2[5]}]
#set_property -dict {PACKAGE_PIN G25 IOSTANDARD LVCMOS33} [get_ports {jp2[6]}]
#set_property -dict {PACKAGE_PIN F25 IOSTANDARD LVCMOS33} [get_ports {jp2[7]}]
#set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports {jp2[8]}]  ;# V3 = LED1
#set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {jp2[9]}]  ;# V3 = LED0
#set_property -dict {PACKAGE_PIN F23 IOSTANDARD LVCMOS33} [get_ports {jp2[10]}]
#set_property -dict {PACKAGE_PIN E23 IOSTANDARD LVCMOS33} [get_ports {jp2[11]}]
#set_property -dict {PACKAGE_PIN E26 IOSTANDARD LVCMOS33} [get_ports {jp2[12]}]
#set_property -dict {PACKAGE_PIN D26 IOSTANDARD LVCMOS33} [get_ports {jp2[13]}]
#set_property -dict {PACKAGE_PIN E25 IOSTANDARD LVCMOS33} [get_ports {jp2[14]}]
#set_property -dict {PACKAGE_PIN D25 IOSTANDARD LVCMOS33} [get_ports {jp2[15]}]

# =============================================================================
# J12  (2×20 expansion) — LiteX "j12" (pin1=GND pin2=VIN; FPGA from pin3)
#   AB26 AC26 AB24 AC24 AA24 AB25 AA22 AA23
#   Y25  AA25 W25  Y26  Y22  Y23  W21  Y21
#   V26  W26  U25  U26  V24  W24  V23  W23
#   V18  W18  U22  V22  U21  V21  T20  U20
#   T19  U19
# =============================================================================
#set_property -dict {PACKAGE_PIN AB26 IOSTANDARD LVCMOS33} [get_ports {j12[0]}]
#set_property -dict {PACKAGE_PIN AC26 IOSTANDARD LVCMOS33} [get_ports {j12[1]}]
#set_property -dict {PACKAGE_PIN AB24 IOSTANDARD LVCMOS33} [get_ports {j12[2]}]
#set_property -dict {PACKAGE_PIN AC24 IOSTANDARD LVCMOS33} [get_ports {j12[3]}]
#set_property -dict {PACKAGE_PIN AA24 IOSTANDARD LVCMOS33} [get_ports {j12[4]}]
#set_property -dict {PACKAGE_PIN AB25 IOSTANDARD LVCMOS33} [get_ports {j12[5]}]
#set_property -dict {PACKAGE_PIN AA22 IOSTANDARD LVCMOS33} [get_ports {j12[6]}]
#set_property -dict {PACKAGE_PIN AA23 IOSTANDARD LVCMOS33} [get_ports {j12[7]}]
#set_property -dict {PACKAGE_PIN Y25  IOSTANDARD LVCMOS33} [get_ports {j12[8]}]
#set_property -dict {PACKAGE_PIN AA25 IOSTANDARD LVCMOS33} [get_ports {j12[9]}]
#set_property -dict {PACKAGE_PIN W25  IOSTANDARD LVCMOS33} [get_ports {j12[10]}]
#set_property -dict {PACKAGE_PIN Y26  IOSTANDARD LVCMOS33} [get_ports {j12[11]}]
#set_property -dict {PACKAGE_PIN Y22  IOSTANDARD LVCMOS33} [get_ports {j12[12]}]
#set_property -dict {PACKAGE_PIN Y23  IOSTANDARD LVCMOS33} [get_ports {j12[13]}]
#set_property -dict {PACKAGE_PIN W21  IOSTANDARD LVCMOS33} [get_ports {j12[14]}]
#set_property -dict {PACKAGE_PIN Y21  IOSTANDARD LVCMOS33} [get_ports {j12[15]}]
#set_property -dict {PACKAGE_PIN V26  IOSTANDARD LVCMOS33} [get_ports {j12[16]}]
#set_property -dict {PACKAGE_PIN W26  IOSTANDARD LVCMOS33} [get_ports {j12[17]}]
#set_property -dict {PACKAGE_PIN U25  IOSTANDARD LVCMOS33} [get_ports {j12[18]}]
#set_property -dict {PACKAGE_PIN U26  IOSTANDARD LVCMOS33} [get_ports {j12[19]}]
#set_property -dict {PACKAGE_PIN V24  IOSTANDARD LVCMOS33} [get_ports {j12[20]}]
#set_property -dict {PACKAGE_PIN W24  IOSTANDARD LVCMOS33} [get_ports {j12[21]}]
#set_property -dict {PACKAGE_PIN V23  IOSTANDARD LVCMOS33} [get_ports {j12[22]}]
#set_property -dict {PACKAGE_PIN W23  IOSTANDARD LVCMOS33} [get_ports {j12[23]}]
#set_property -dict {PACKAGE_PIN V18  IOSTANDARD LVCMOS33} [get_ports {j12[24]}]
#set_property -dict {PACKAGE_PIN W18  IOSTANDARD LVCMOS33} [get_ports {j12[25]}]
#set_property -dict {PACKAGE_PIN U22  IOSTANDARD LVCMOS33} [get_ports {j12[26]}]
#set_property -dict {PACKAGE_PIN V22  IOSTANDARD LVCMOS33} [get_ports {j12[27]}]
#set_property -dict {PACKAGE_PIN U21  IOSTANDARD LVCMOS33} [get_ports {j12[28]}]
#set_property -dict {PACKAGE_PIN V21  IOSTANDARD LVCMOS33} [get_ports {j12[29]}]
#set_property -dict {PACKAGE_PIN T20  IOSTANDARD LVCMOS33} [get_ports {j12[30]}]
#set_property -dict {PACKAGE_PIN U20  IOSTANDARD LVCMOS33} [get_ports {j12[31]}]
#set_property -dict {PACKAGE_PIN T19  IOSTANDARD LVCMOS33} [get_ports {j12[32]}]
#set_property -dict {PACKAGE_PIN U19  IOSTANDARD LVCMOS33} [get_ports {j12[33]}]

# =============================================================================
# JP3  (MGT / GTP transceiver header) — LiteX "jp3" + onboard 125 MHz MGT clk
# GND on pins 1,2,11,12,15,16,25,26. Use DIFF standards / IBERT for real use.
# =============================================================================
#set_property -dict {PACKAGE_PIN AF7  IOSTANDARD LVCMOS33} [get_ports mgt_txn3]
#set_property -dict {PACKAGE_PIN AE7  IOSTANDARD LVCMOS33} [get_ports mgt_txp3]
#set_property -dict {PACKAGE_PIN AD8  IOSTANDARD LVCMOS33} [get_ports mgt_txn2]
#set_property -dict {PACKAGE_PIN AC8  IOSTANDARD LVCMOS33} [get_ports mgt_txp2]
#set_property -dict {PACKAGE_PIN AF9  IOSTANDARD LVCMOS33} [get_ports mgt_txn1]
#set_property -dict {PACKAGE_PIN AE9  IOSTANDARD LVCMOS33} [get_ports mgt_txp1]
#set_property -dict {PACKAGE_PIN AD10 IOSTANDARD LVCMOS33} [get_ports mgt_txn0]
#set_property -dict {PACKAGE_PIN AC10 IOSTANDARD LVCMOS33} [get_ports mgt_txp0]
#set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports mgt_clk1_n]
#set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS33} [get_ports mgt_clk1_p]
#set_property -dict {PACKAGE_PIN AF11 IOSTANDARD LVCMOS33} [get_ports mgt_rxn3]
#set_property -dict {PACKAGE_PIN AE11 IOSTANDARD LVCMOS33} [get_ports mgt_rxp3]
#set_property -dict {PACKAGE_PIN AD14 IOSTANDARD LVCMOS33} [get_ports mgt_rxn2]
#set_property -dict {PACKAGE_PIN AC14 IOSTANDARD LVCMOS33} [get_ports mgt_rxp2]
#set_property -dict {PACKAGE_PIN AF13 IOSTANDARD LVCMOS33} [get_ports mgt_rxn1]
#set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS33} [get_ports mgt_rxp1]
#set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVCMOS33} [get_ports mgt_rxn0]
#set_property -dict {PACKAGE_PIN AC12 IOSTANDARD LVCMOS33} [get_ports mgt_rxp0]
## Onboard 125 MHz MGT reference (not a header pin)
#set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS33} [get_ports mgt_clk0_n]
#set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS33} [get_ports mgt_clk0_p]
#create_clock -period 8.000 -name mgt_clk0 [get_ports mgt_clk0_p]

# =============================================================================
# HDMI out — official Test06 (TMDS_33). LiteX also has SCL/SDA/HPD/CEC.
# =============================================================================
#set_property -dict {PACKAGE_PIN D4 IOSTANDARD TMDS_33} [get_ports hdmi_clk_p]
#set_property -dict {PACKAGE_PIN C4 IOSTANDARD TMDS_33} [get_ports hdmi_clk_n]
#set_property -dict {PACKAGE_PIN E1 IOSTANDARD TMDS_33} [get_ports {hdmi_data_p[0]}]
#set_property -dict {PACKAGE_PIN D1 IOSTANDARD TMDS_33} [get_ports {hdmi_data_n[0]}]
#set_property -dict {PACKAGE_PIN F2 IOSTANDARD TMDS_33} [get_ports {hdmi_data_p[1]}]
#set_property -dict {PACKAGE_PIN E2 IOSTANDARD TMDS_33} [get_ports {hdmi_data_n[1]}]
#set_property -dict {PACKAGE_PIN G2 IOSTANDARD TMDS_33} [get_ports {hdmi_data_p[2]}]
#set_property -dict {PACKAGE_PIN G1 IOSTANDARD TMDS_33} [get_ports {hdmi_data_n[2]}]
#set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports hdmi_scl]
#set_property -dict {PACKAGE_PIN A2 IOSTANDARD LVCMOS33} [get_ports hdmi_sda]
#set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports hdmi_hpd]
#set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS33} [get_ports hdmi_cec]

# =============================================================================
# GMII Ethernet — official Test08 + LiteX eth / eth_clocks
# =============================================================================
#set_property -dict {PACKAGE_PIN R1 IOSTANDARD LVCMOS33} [get_ports eth_rst_n]
#set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS33} [get_ports eth_mdio]
#set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports eth_mdc]
#set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports eth_gtx_clk]
#set_property -dict {PACKAGE_PIN M2 IOSTANDARD LVCMOS33} [get_ports eth_tx_clk]
#set_property -dict {PACKAGE_PIN T2 IOSTANDARD LVCMOS33} [get_ports eth_tx_en]
#set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports eth_tx_er]
#set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {eth_txd[0]}]
#set_property -dict {PACKAGE_PIN P1 IOSTANDARD LVCMOS33} [get_ports {eth_txd[1]}]
#set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVCMOS33} [get_ports {eth_txd[2]}]
#set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVCMOS33} [get_ports {eth_txd[3]}]
#set_property -dict {PACKAGE_PIN M1 IOSTANDARD LVCMOS33} [get_ports {eth_txd[4]}]
#set_property -dict {PACKAGE_PIN L2 IOSTANDARD LVCMOS33} [get_ports {eth_txd[5]}]
#set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {eth_txd[6]}]
#set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports {eth_txd[7]}]
#set_property -dict {PACKAGE_PIN P4 IOSTANDARD LVCMOS33} [get_ports eth_rx_clk]
#set_property -dict {PACKAGE_PIN L3 IOSTANDARD LVCMOS33} [get_ports eth_rx_dv]
#set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports eth_rx_er]
#set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[0]}]
#set_property -dict {PACKAGE_PIN N3 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[1]}]
#set_property -dict {PACKAGE_PIN N4 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[2]}]
#set_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[3]}]
#set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[4]}]
#set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[5]}]
#set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[6]}]
#set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[7]}]
#set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports eth_col]
#set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports eth_crs]
#create_clock -period 8.000 -name eth_rx_clk [get_ports eth_rx_clk]
#create_clock -period 8.000 -name eth_tx_clk [get_ports eth_tx_clk]

# =============================================================================
# DDR3 (MT41K128M16) — from official DDR3.ucf / LiteX (NOT the broken DRubioG
# DQS section). Prefer MIG-generated XDC when building a real memory design.
# Bank 16 needs: set_property INTERNAL_VREF 0.675 [get_iobanks 16]
# =============================================================================
#set_property INTERNAL_VREF 0.675 [get_iobanks 16]
#set_property -dict {PACKAGE_PIN E17 IOSTANDARD SSTL135} [get_ports {ddr3_addr[0]}]
#set_property -dict {PACKAGE_PIN G17 IOSTANDARD SSTL135} [get_ports {ddr3_addr[1]}]
#set_property -dict {PACKAGE_PIN F17 IOSTANDARD SSTL135} [get_ports {ddr3_addr[2]}]
#set_property -dict {PACKAGE_PIN C17 IOSTANDARD SSTL135} [get_ports {ddr3_addr[3]}]
#set_property -dict {PACKAGE_PIN G16 IOSTANDARD SSTL135} [get_ports {ddr3_addr[4]}]
#set_property -dict {PACKAGE_PIN D16 IOSTANDARD SSTL135} [get_ports {ddr3_addr[5]}]
#set_property -dict {PACKAGE_PIN H16 IOSTANDARD SSTL135} [get_ports {ddr3_addr[6]}]
#set_property -dict {PACKAGE_PIN E16 IOSTANDARD SSTL135} [get_ports {ddr3_addr[7]}]
#set_property -dict {PACKAGE_PIN H14 IOSTANDARD SSTL135} [get_ports {ddr3_addr[8]}]
#set_property -dict {PACKAGE_PIN F15 IOSTANDARD SSTL135} [get_ports {ddr3_addr[9]}]
#set_property -dict {PACKAGE_PIN F20 IOSTANDARD SSTL135} [get_ports {ddr3_addr[10]}]
#set_property -dict {PACKAGE_PIN H15 IOSTANDARD SSTL135} [get_ports {ddr3_addr[11]}]
#set_property -dict {PACKAGE_PIN C18 IOSTANDARD SSTL135} [get_ports {ddr3_addr[12]}]
#set_property -dict {PACKAGE_PIN G15 IOSTANDARD SSTL135} [get_ports {ddr3_addr[13]}]
#set_property -dict {PACKAGE_PIN B17 IOSTANDARD SSTL135} [get_ports {ddr3_ba[0]}]
#set_property -dict {PACKAGE_PIN D18 IOSTANDARD SSTL135} [get_ports {ddr3_ba[1]}]
#set_property -dict {PACKAGE_PIN A17 IOSTANDARD SSTL135} [get_ports {ddr3_ba[2]}]
#set_property -dict {PACKAGE_PIN A19 IOSTANDARD SSTL135} [get_ports ddr3_ras_n]
#set_property -dict {PACKAGE_PIN B19 IOSTANDARD SSTL135} [get_ports ddr3_cas_n]
#set_property -dict {PACKAGE_PIN A18 IOSTANDARD SSTL135} [get_ports ddr3_we_n]
#set_property -dict {PACKAGE_PIN E22 IOSTANDARD SSTL135} [get_ports ddr3_cs_n]  ;# wired on V1; NC on V2 OK
#set_property -dict {PACKAGE_PIN A22 IOSTANDARD SSTL135} [get_ports {ddr3_dm[0]}]
#set_property -dict {PACKAGE_PIN C22 IOSTANDARD SSTL135} [get_ports {ddr3_dm[1]}]
#set_property -dict {PACKAGE_PIN D21 IOSTANDARD SSTL135} [get_ports {ddr3_dq[0]}]
#set_property -dict {PACKAGE_PIN C21 IOSTANDARD SSTL135} [get_ports {ddr3_dq[1]}]
#set_property -dict {PACKAGE_PIN B22 IOSTANDARD SSTL135} [get_ports {ddr3_dq[2]}]
#set_property -dict {PACKAGE_PIN B21 IOSTANDARD SSTL135} [get_ports {ddr3_dq[3]}]
#set_property -dict {PACKAGE_PIN D19 IOSTANDARD SSTL135} [get_ports {ddr3_dq[4]}]
#set_property -dict {PACKAGE_PIN E20 IOSTANDARD SSTL135} [get_ports {ddr3_dq[5]}]
#set_property -dict {PACKAGE_PIN C19 IOSTANDARD SSTL135} [get_ports {ddr3_dq[6]}]
#set_property -dict {PACKAGE_PIN D20 IOSTANDARD SSTL135} [get_ports {ddr3_dq[7]}]
#set_property -dict {PACKAGE_PIN C23 IOSTANDARD SSTL135} [get_ports {ddr3_dq[8]}]
#set_property -dict {PACKAGE_PIN D23 IOSTANDARD SSTL135} [get_ports {ddr3_dq[9]}]
#set_property -dict {PACKAGE_PIN B24 IOSTANDARD SSTL135} [get_ports {ddr3_dq[10]}]
#set_property -dict {PACKAGE_PIN B25 IOSTANDARD SSTL135} [get_ports {ddr3_dq[11]}]
#set_property -dict {PACKAGE_PIN C24 IOSTANDARD SSTL135} [get_ports {ddr3_dq[12]}]
#set_property -dict {PACKAGE_PIN C26 IOSTANDARD SSTL135} [get_ports {ddr3_dq[13]}]
#set_property -dict {PACKAGE_PIN A25 IOSTANDARD SSTL135} [get_ports {ddr3_dq[14]}]
#set_property -dict {PACKAGE_PIN B26 IOSTANDARD SSTL135} [get_ports {ddr3_dq[15]}]
#set_property -dict {PACKAGE_PIN B20 IOSTANDARD DIFF_SSTL135} [get_ports {ddr3_dqs_p[0]}]
#set_property -dict {PACKAGE_PIN A20 IOSTANDARD DIFF_SSTL135} [get_ports {ddr3_dqs_n[0]}]
#set_property -dict {PACKAGE_PIN A23 IOSTANDARD DIFF_SSTL135} [get_ports {ddr3_dqs_p[1]}]
#set_property -dict {PACKAGE_PIN A24 IOSTANDARD DIFF_SSTL135} [get_ports {ddr3_dqs_n[1]}]
#set_property -dict {PACKAGE_PIN F18 IOSTANDARD DIFF_SSTL135} [get_ports {ddr3_ck_p[0]}]
#set_property -dict {PACKAGE_PIN F19 IOSTANDARD DIFF_SSTL135} [get_ports {ddr3_ck_n[0]}]
#set_property -dict {PACKAGE_PIN E18 IOSTANDARD SSTL135} [get_ports {ddr3_cke[0]}]
#set_property -dict {PACKAGE_PIN G19 IOSTANDARD SSTL135} [get_ports {ddr3_odt[0]}]
#set_property -dict {PACKAGE_PIN H17 IOSTANDARD SSTL135} [get_ports ddr3_reset_n]

# =============================================================================
# V1 differences (legacy — replace active clk/LED/key1 if you have V1)
#   clk50 M22 + CLOCK_DEDICATED_ROUTE FALSE
#   cpu_reset_n / Key1 J8   (conflicts with V2/V3 SD CMD)
#   user_led0 J6   user_led1 H6
# =============================================================================
#set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]
#create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_50mhz_IBUF]
#set_property -dict {PACKAGE_PIN J8 IOSTANDARD LVCMOS33} [get_ports key1_n]
#set_property -dict {PACKAGE_PIN J6 IOSTANDARD LVCMOS33} [get_ports {led_v1[0]}]
#set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports {led_v1[1]}]

################################################################################
# End of file
################################################################################
