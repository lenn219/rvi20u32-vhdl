# Vivado project — QMTECH Wukong XC7A100T

Portable **TCL-based** project (no checked-in `.xpr`). Recreate it on any PC with Vivado, then Generate Bitstream.

| Item | Value |
|------|--------|
| Part | `xc7a100tfgg676-1` |
| Top | `board_top` |
| Constraints | `../wukong.xdc` |
| Demo | `uart_hello.hex` → loops `Hi` @ **115200 8N1** |
| Generated XPR | `fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr` |

## 1. Create the project

Open a terminal in the **repository root** (`rvi20u32-vhdl`).

### Linux / macOS

```bash
vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
```

### Windows (Vivado Tcl Shell or `cmd`)

```bat
cd C:\path\to\rvi20u32-vhdl
vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
```

Or in the Vivado **Tcl Console** after starting the GUI:

```tcl
cd {C:/path/to/rvi20u32-vhdl}
source fpga/qmtech_wukong/vivado/create_project.tcl
```

## 2. Open in Vivado GUI

**File → Open Project** → select:

```text
fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr
```

Confirm:

- Sources → top = **`board_top`**
- Constraints → **`wukong.xdc`**
- Generics include absolute `IMEM_INIT_HEX=.../uart_hello.hex` and `UART_CLKS_PER_BIT=434`

## 3. Generate Bitstream

In Flow Navigator:

1. **Run Synthesis**
2. **Run Implementation**
3. **Generate Bitstream**

Batch alternative (from repo root):

```bash
vivado -mode batch -source fpga/qmtech_wukong/vivado/build_bitstream.tcl
```

Bitstream path:

```text
fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.runs/impl_1/board_top.bit
```

## 4. Program the FPGA

1. Plug the Wukong **JTAG** USB cable.
2. Vivado → **Open Hardware Manager** → **Open Target** → **Auto Connect**.
3. **Program Device** → select `board_top.bit`.

## 5. Open serial (UART demo)

1. Plug the board **USB-UART** (may be a second USB connector).
2. Port settings: **115200**, **8N1**, no flow control.
3. Examples:

```bash
# Linux
picocom -b 115200 /dev/ttyUSB0
# or: screen /dev/ttyUSB0 115200

# Windows: use PuTTY / Tera Term on COMx @ 115200
```

Press/release **Key1** (reset) if needed. You should see repeating:

```text
Hi
Hi
…
```

LED0 (active-low) lights while the CPU is out of reset; LED1 lights only if halted (should stay off for this looping demo).

## Files in this folder

| File | Role |
|------|------|
| `create_project.tcl` | Create/recreate the `.xpr` |
| `build_bitstream.tcl` | Optional batch synth→bit |
| `files.tcl` | Explicit RTL / XDC list |
| `uart_hello.hex` | Local copy of the demo image |
| `proj/` | Generated project (gitignored) |

## Notes

- Re-run `create_project.tcl` after pulling RTL changes (it uses `-force`).
- V3 boards: swap LED pins in `../wukong.xdc` (see comments there).
- This flow does **not** require checking in binary `.xpr` files.
