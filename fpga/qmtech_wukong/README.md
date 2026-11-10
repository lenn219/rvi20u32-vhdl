# QMTECH Wukong (XC7A100T) bring-up

Board class: **QMTECH Wukong / XC7A100T–200T**. Targets **XC7A100T FGG676** with the **onboard USB-UART**.

## Vivado project (start here on your PC)

→ **[`vivado/README.md`](vivado/README.md)**

```bash
# from repo root
vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
# then Open Project:
#   fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr
```

## Silk LEDs vs FPGA user LEDs

| Silk | Meaning | Expected after program |
|------|---------|------------------------|
| **D1** | FPGA **DONE** | **Always ON** (config OK) — not a user LED |
| **D4** | **3.3 V** rail | **Always ON** when powered — not a user LED |
| **D5** | User **LED0** | Soft blink ~1 s on / ~1 s off (CPU MMIO) |
| **D6** | User **LED1** | HW heartbeat ~1 Hz (clock alive) |

If D1+D4 are on but D5/D6 never move, the bitstream did not reach the user-LED pins or the design is stuck — rebuild with this tree (embedded IMEM + both V2/V3 LED pin pairs).

## Pin map (verified V2 + V3)

| Signal | Direction | Pin | Notes |
|--------|-----------|-----|-------|
| `clk_50mhz` | in | **M21** | 50 MHz (V2/V3). V1 was M22. |
| `key0_n` | in | **H7** | Key0, active-low (QMTECH demo reset) |
| `key1_n` | in | **M6** | Key1, active-low (LiteX reset) |
| `led_v2[0]` | out | **V16** | LED0 on **V2**, active-low |
| `led_v2[1]` | out | **V17** | LED1 on **V2**, active-low |
| `led_v3[0]` | out | **G21** | LED0 on **V3**, active-low |
| `led_v3[1]` | out | **G20** | LED1 on **V3**, active-low |
| `uart_tx` | out | **E3** | FPGA → bridge RXD |
| `uart_rx` | in | **F3** | bridge TXD → FPGA |

Sources: ChinaQMTECH schematics V2/V3, official Test01/Test05 demos, LiteX `qmtech_wukong.py`.

**Part:** `xc7a100tfgg676-1`  
**Baud:** 115200 8N1 (`UART_CLKS_PER_BIT=434` @ **50 MHz**)

## Which `/dev/ttyUSBx` is UART?

On Wukong, **JTAG and UART are separate**:

| Connector | Chip | Linux device |
|-----------|------|--------------|
| **Mini-USB** (onboard) | **CP2102** (V2) or **CH340N** (V3) | **`/dev/ttyUSB0`** (often the *only* ttyUSB) |
| **JTAG header** | Platform Cable / clone | **Not** a UART tty — Vivado Hardware Manager |

This setup with a **single** `/dev/ttyUSB0` (`root:dialout`) is normal: that node **is** the FPGA UART bridge. Add your user to `dialout` if needed (`sudo usermod -aG dialout $USER`, then re-login).

Identify the bridge:

```bash
ls -l /dev/ttyUSB* /dev/serial/by-id/ 2>/dev/null
# CP210x → Silicon Labs; CH340 → 1a86:…
```

## Demo behaviour

IMEM is preloaded from the **embedded** `uart_hello` image (constant array inside `rtl/mem/imem.vhd`, from `sw/hex/uart_hello.hex`):

1. Toggle LED0 via MMIO (`0x20000000`)
2. Software delay ≈ **1.0 s** half-period at 50 MHz
3. Print `Hi\r\n` on UART
4. Repeat

LED1 toggles from a hardware counter (~1 Hz) independent of the CPU.

## Bring-up checklist

1. Power board — **D4** on.
2. Program `board_top.bit` via JTAG — **D1** on.
3. Confirm **D6** heartbeats ~1 Hz (clock + bitstream alive).
4. Confirm **D5** soft-blinks ~1 s half (CPU running demo).
5. Serial:

```bash
picocom -b 115200 -f n /dev/ttyUSB0
```

Expect repeating `Hi` once per LED0 half-period. Press **Key0** or **Key1** to reset.

6. If no UART but D6 blinks: check baud **115200 8N1**, correct tty, and that mini-USB is plugged.
7. If neither D5 nor D6 blink: bitstream/clock/pin issue — re-run `create_project.tcl` from this commit and rebuild.

## Layout

| Path | Role |
|------|------|
| `board_top.vhd` | Board wrapper |
| `wukong.xdc` | Constraints (V2+V3 LEDs, both keys) |
| `vivado/` | Openable Vivado project TCL |
| `../../sw/hex/uart_hello.hex` | Demo source image |
| `../../rtl/mem/imem.vhd` | Contains embedded `uart_hello` boot image |
