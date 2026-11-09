# rvi20u32-vhdl

Classic **5-stage pipelined RV32I** CPU in modular VHDL.

- **ISA:** pure RV32I (no M/C/Zicsr). `FENCE` / `FENCE.I` = NOP; `ECALL`/`EBREAK` = halt.
- **Memory:** on-chip IMEM + DMEM (BRAM-style) for simulation and Artix-7 FPGA.
- **Target:** Xilinx Artix-7 **XC7A200T**, CPU clock **50 MHz**, LEDs + UART (board SKU / XDC deferred).
- **Sim:** GHDL + VUnit. **Synth:** Vivado (later).

## Status

**P0 — skeleton:** `rv32_pkg`, `alu`, `regfile`, `imem`, `dmem` + VUnit tests.

Next: decode + 5-stage pipeline (P2 smoke program).

## Layout

```
rtl/pkg/     rv32_pkg.vhd
rtl/core/    alu, regfile (+ stages later)
rtl/mem/     imem, dmem
tb/          VUnit testbenches
sim/run.py   VUnit entry
sw/          bare-metal programs (later)
fpga/a7_200t/  FPGA wrapper stub (constraints TBD)
```

## Simulate

```bash
# Dependencies: ghdl, python3, pip install vunit-hdl
python3 sim/run.py -v
```

## Memory map (v1)

| Region | Base | Size |
|--------|------|------|
| IMEM | `0x0000_0000` | 8 KiB |
| DMEM | `0x1000_0000` | 8 KiB |
| MMIO | `0x2000_0000` | LEDs / UART / status |

Reset PC = `0x0000_0000`.
