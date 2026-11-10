# QMTECH Wukong (XC7A100T) bring-up

Board class: **QMTECH Wukong / XC7A100T–200T Wukong**. This package targets **XC7A100T FGG676** with the **onboard USB-UART**.

## Pin assumptions (document carefully)

| Signal | Direction | Pin | Notes |
|--------|-----------|-----|-------|
| `clk_50mhz` | in | **M21** | 50 MHz oscillator (V2/V3). V1 uses **M22**. |
| `rst_n` | in | **M6** | Key1, **active-low** (V2/V3). V1 uses **J8**. |
| `led[0]` | out | **V16** | User LED0, **active-low** (V2). V3: **G21**. |
| `led[1]` | out | **V17** | User LED1, **active-low** (V2). V3: **G20**. |
| `uart_tx` | out | **E3** | FPGA → USB-UART (LiteX `serial.tx`) |
| `uart_rx` | in | **F3** | USB-UART → FPGA (LiteX `serial.rx`, unused in v1) |

Cross-check: [litex-boards `qmtech_wukong.py`](https://github.com/litex-hub/litex-boards/blob/master/litex_boards/platforms/qmtech_wukong.py).  
If LEDs do not light as expected on a **V3** board, switch the LED lines in `wukong.xdc` to the commented G21/G20 pair.

**Part:** `xc7a100tfgg676-1` (safer default; `-2` also used in the wild).  
**Baud:** 115200 8N1 (`UART_CLKS_PER_BIT=434` at 50 MHz).

## What the demo does

`board_top` preloads IMEM from `sw/hex/uart_hello.hex` and loops printing:

```text
Hi
Hi
…
```

over the USB-UART (`\r\n` terminated). LED0 stays lit while out of reset; LED1 lights only if the core halts (should stay off).

## Build (Vivado)

From the **repo root** (Vivado 2020.1+ typical):

```bash
vivado -mode batch -source fpga/qmtech_wukong/create_vivado_project.tcl
```

Then either finish in the GUI (`build/wukong/rvi20u32_wukong.xpr`) or uncomment the `launch_runs` lines at the bottom of the TCL to write a bitstream in batch mode.

Manual GUI flow:

1. Create project → part **xc7a100tfgg676-1**
2. Add all `rtl/**/*.vhd` + `fpga/qmtech_wukong/board_top.vhd`
3. Add `fpga/qmtech_wukong/wukong.xdc`
4. Copy `sw/hex/uart_hello.hex` into the project run directory (or set generic `IMEM_INIT_HEX` to an absolute path)
5. Set top = `board_top`
6. Generate Bitstream

Bitstream path (batch default layout):  
`build/wukong/rvi20u32_wukong.runs/impl_1/board_top.bit`

## Program

```bash
# JTAG (onboard FT2232/USB-JTAG on many Wukong boards)
vivado -mode tcl
# open_hw_manager; connect_hw_server; open_hw_target
# set_property PROGRAM.FILE {.../board_top.bit} [current_hw_device]
# program_hw_devices [current_hw_device]
```

Or use Vivado Hardware Manager GUI → Program Device.

This repo **does not** claim a bitstream was programmed onto physical hardware from CI.

## Open serial

1. Plug the Wukong **USB-UART** cable (separate from JTAG on some kits — use the UART port / bridge).
2. Find the device (`/dev/ttyUSB*`, `/dev/ttyACM*`, or COMx on Windows).
3. Open **115200 8N1**:

```bash
# Linux example
picocom -b 115200 /dev/ttyUSB0
# or:  screen /dev/ttyUSB0 115200
```

Press/release **Key1** (reset) if needed; you should see repeating `Hi` lines.

## Files

| File | Role |
|------|------|
| `board_top.vhd` | Board wrapper → `cpu_top` + LED polarity |
| `wukong.xdc` | Vivado constraints |
| `create_vivado_project.tcl` | Project scaffold |
| `../../sw/hex/uart_hello.hex` | Looping UART demo image |
