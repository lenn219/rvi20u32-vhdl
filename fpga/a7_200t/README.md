# FPGA target: Artix-7 XC7A200T

- **CPU clock:** 50 MHz on `clk` (provide via board oscillator + MMCM/divider).
- **I/O:** `leds[7:0]`, `uart_tx`, `rst_btn` (active-high).
- **XDC / board SKU:** deferred — add pin constraints when the carrier is chosen.
- **Program image:** initialize IMEM BRAM/COE for bitstream builds (sim loads via `imem_we`).

`fpga_top.vhd` is synthesizable without board pins; wire an XDC later.
