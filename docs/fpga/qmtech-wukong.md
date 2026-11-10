# FPGA: QMTECH Wukong

**Open / build Vivado project on your PC:**

[`fpga/qmtech_wukong/vivado/README.md`](../../fpga/qmtech_wukong/vivado/README.md)

```bash
vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
# Open: fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr
```

Board notes + pins + UART tty selection: [`fpga/qmtech_wukong/README.md`](../../fpga/qmtech_wukong/README.md)

| Item | Value |
|------|--------|
| Part | `xc7a100tfgg676-1` |
| Clock | **50 MHz** (`M21` on V2/V3) |
| USB-UART | TX `E3`, RX `F3`, **115200 8N1** — usually **`/dev/ttyUSB0`** (only ttyUSB) |
| JTAG | Separate cable — not the UART tty |
| LEDs | D1=DONE, D4=3V3 (always on); D5/D6 user (V2:`V16/V17`, V3:`G21/G20`, both driven) |
| Demo | Embedded `uart_hello` — LED0 ~1 s soft blink, LED1 ~1 Hz HW heartbeat, UART `Hi` |

```bash
picocom -b 115200 -f n /dev/ttyUSB0
```
