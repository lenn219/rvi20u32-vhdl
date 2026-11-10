# QMTECH Wukong (XC7A100T) bring-up

Board class: **QMTECH Wukong / XC7A100T–200T Wukong**. Targets **XC7A100T FGG676** with the **onboard USB-UART**.

## Vivado project (start here on your PC)

**Portable TCL project** (recommended):

→ **[`vivado/README.md`](vivado/README.md)**

```bash
# from repo root
vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
# then Open Project:
#   fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr
```

## Pin assumptions (V2 default)

| Signal | Direction | Pin | Notes |
|--------|-----------|-----|-------|
| `clk_50mhz` | in | **M21** | 50 MHz oscillator (V2/V3). V1 uses **M22**. |
| `rst_n` | in | **M6** | Key1, **active-low** (V2/V3). V1 uses **J8**. |
| `led[0]` | out | **V16** | User LED0, **active-low** (V2). V3: **G21**. |
| `led[1]` | out | **V17** | User LED1, **active-low** (V2). V3: **G20**. |
| `uart_tx` | out | **E3** | FPGA → USB-UART (LiteX `serial.tx`) |
| `uart_rx` | in | **F3** | USB-UART → FPGA (LiteX `serial.rx`, unused in v1) |

Cross-check: [litex-boards `qmtech_wukong.py`](https://github.com/litex-hub/litex-boards/blob/master/litex_boards/platforms/qmtech_wukong.py).

**Part:** `xc7a100tfgg676-1`  
**Baud:** 115200 8N1 (`UART_CLKS_PER_BIT=434` at **50 MHz** CPU clock — unchanged)

## Demo behaviour

`board_top` preloads IMEM from `sw/hex/uart_hello.hex` and loops:

1. Toggle LED0 via MMIO (`0x20000000`)
2. Software delay ≈ **1.0 s** half-period (≈ **2.0 s** full blink) at 50 MHz  
   (countdown `12_500_000` × ~4 cycles/iter)
3. Print `Hi\r\n` on UART
4. Repeat

CPU clock stays **50 MHz** so UART baud math stays `50e6/115200 ≈ 434`. No clock divider.

## Quick program + serial

1. Generate Bitstream in Vivado (see `vivado/README.md`).
2. Hardware Manager → Program `board_top.bit`.
3. Serial: **115200 8N1** on the USB-UART port (`picocom -b 115200 /dev/ttyUSB0` or PuTTY COMx).

## Layout

| Path | Role |
|------|------|
| `board_top.vhd` | Board wrapper |
| `wukong.xdc` | Constraints |
| `vivado/` | **Openable Vivado project TCL** |
| `../../sw/hex/uart_hello.hex` | Demo image |
