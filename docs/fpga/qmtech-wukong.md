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
| **CPU clock** | **50 MHz** (board oscillator; single domain) |
| USB-UART | TX `E3`, RX `F3`, **9600 8N1** |
| tty | usually **`/dev/ttyUSB0`** (mini-USB bridge; JTAG is separate) |
| LEDs | D1=DONE, D4=3V3; D5 soft blink ~1 s; D6 HW heartbeat ~1 Hz |
| Demo | Embedded `uart_hello` → LED0 + UART `Hi` |

```bash
picocom -b 9600 -f n /dev/ttyUSB0
```

**Timing note:** Combo IMEM/DMEM may still show WNS violations at 50 MHz; for UART bring-up that is OK. Sync BRAM is the proper long-term fix.
