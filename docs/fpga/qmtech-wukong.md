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
| Board oscillator | **50 MHz** (`M21`) |
| **CPU / UART clock** | **5 MHz** (÷10 in `board_top`) — required for timing with combo IMEM/DMEM |
| USB-UART | TX `E3`, RX `F3`, **9600 8N1**, `UART_CLKS_PER_BIT=521` |
| tty | usually **`/dev/ttyUSB0`** (mini-USB bridge; JTAG is separate) |
| LEDs | D1=DONE, D4=3V3; D5 soft blink ~1 s; D6 HW heartbeat ~1 Hz |
| Demo | Embedded `uart_hello` → LED0 + UART `Hi` |

```bash
picocom -b 9600 -f n /dev/ttyUSB0
```

**Timing note:** Closing 50 MHz with combinational IMEM/DMEM failed (~WNS −84 ns). The ÷10 clock is intentional until memories are turned into synchronous BRAM.
