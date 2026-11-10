# Vivado project — QMTECH Wukong XC7A100T

Portable **TCL-based** project (no checked-in `.xpr`). Recreate it on any PC with Vivado, then Generate Bitstream.

| Item | Value |
|------|--------|
| Part | `xc7a100tfgg676-1` |
| Top | `board_top` |
| Constraints | `../wukong.xdc` (V2+V3 LED pins, Key0+Key1) |
| Clock | **50 MHz** single domain |
| UART | **9600 8N1**, `UART_CLKS_PER_BIT=5208` |
| Demo | Embedded `uart_hello` → LED0 ~**1 s** soft blink, LED1 ~**1 Hz** heartbeat, UART `Hi` |
| Generated XPR | `fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr` |

## 1. Create the project

Open a terminal in the **repository root** (`rvi20u32-vhdl`).

```bash
vivado -mode batch -source fpga/qmtech_wukong/vivado/create_project.tcl
```

Windows / Tcl Console: `cd` to the repo, then `source fpga/qmtech_wukong/vivado/create_project.tcl`.

## 2. Open in Vivado GUI

**File → Open Project** →

```text
fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.xpr
```

Confirm top = **`board_top`**, generics `IMEM_INIT_HEX=uart_hello`, `UART_CLKS_PER_BIT=5208`.
Timing may show WNS violations (combo IMEM/DMEM); UART baud is still 9600 from 50 MHz.

## 3. Generate Bitstream

Flow Navigator → **Generate Bitstream** (or batch `build_bitstream.tcl`).

```text
fpga/qmtech_wukong/vivado/proj/rvi20u32_wukong.runs/impl_1/board_top.bit
```

## 4. Program + serial

1. **JTAG** cable → Hardware Manager → Program `board_top.bit` → silk **D1** ON.
2. **Mini-USB** (onboard UART) → typically the only **`/dev/ttyUSB0`** (CP2102 or CH340). JTAG is not this tty.
3. Serial:

```bash
picocom -b 9600 -f n /dev/ttyUSB0
```

### Expected

| LED | Behaviour |
|-----|-----------|
| D1 | ON (DONE) |
| D4 | ON (3.3 V) |
| D5 (LED0) | ~1 s on / ~1 s off (CPU) |
| D6 (LED1) | ~1 Hz heartbeat (HW) |
| UART | `Hi` + CRLF once per LED0 half-period |

Press **Key0** or **Key1** to reset. Clock is 50 MHz; UART uses `CLKS_PER_BIT=5208` → 9600.

## Files

| File | Role |
|------|------|
| `create_project.tcl` | Create/recreate the `.xpr` |
| `build_bitstream.tcl` | Optional batch synth→bit |
| `files.tcl` | Explicit RTL / XDC list |
| `uart_hello.hex` | Reference copy of demo image |
| `proj/` | Generated project (gitignored) |

After pulling RTL changes, re-run `create_project.tcl` (`-force`).
