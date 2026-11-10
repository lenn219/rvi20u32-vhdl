# FPGA: QMTECH Wukong

**Open / build Vivado project on your PC:**

[`fpga/qmtech_wukong/vivado/README.md`](../../fpga/qmtech_wukong/vivado/README.md)

```bash
vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
# Open: fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr
```

Board notes + pins: [`fpga/qmtech_wukong/README.md`](../../fpga/qmtech_wukong/README.md)

| Item | Value |
|------|--------|
| Part | `xc7a100tfgg676-1` |
| Clock | **50 MHz** (`M21` on V2/V3) |
| USB-UART | TX `E3`, RX `F3`, **115200 8N1** |
| Demo | `sw/hex/uart_hello.hex` (loops `Hi`) |
