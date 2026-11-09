# rvi20u32-vhdl

Classic **5-stage pipelined RV32I** CPU in modular VHDL.

- **ISA:** pure RV32I (no M/C/Zicsr). `FENCE` / `FENCE.I` = NOP; `ECALL`/`EBREAK` = halt.
- **Memory:** on-chip IMEM + DMEM (async read / sync write) + MMIO (LEDs, UART TX stub).
- **Target:** Xilinx Artix-7 **XC7A200T**, CPU clock **50 MHz**; board XDC deferred.
- **Sim:** GHDL + VUnit. **Synth:** Vivado (wrapper in `fpga/a7_200t/`).

## Status

**P2 milestone:** full IF→ID→EX→MEM→WB pipeline with forwarding, load-use stall, control flush, WB→ID bypass. Smoke program (sum 1..5) runs to `ECALL` with LED/DMEM result `15`.

**Arch-tests:** harness for official [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test) (legacy 3.9.1 `rv32i_m/I`). DUT passes `addi-01` vs Unicorn RV32 reference signature. See `docs/compliance/riscv-arch-test.md` — full certification needs Zicsr/traps (not in v1).

## Simulate

```bash
# Dependencies: ghdl, python3, pip install vunit-hdl
python3 sim/run.py
```

## Layout

```
rtl/pkg/      rv32_pkg.vhd
rtl/core/     decode, alu, regfile, forward, hazard, cpu_top
rtl/mem/      imem, dmem
rtl/mmio/     leds, uart_tx
tb/           VUnit tests (alu, regfile, dmem, cpu_smoke)
sw/hex/       committed smoke.hex
fpga/a7_200t/ fpga_top (no board XDC yet)
```

## Memory map (v1)

| Region | Base | Size |
|--------|------|------|
| IMEM | `0x0000_0000` | 8 KiB |
| DMEM | `0x1000_0000` | 8 KiB |
| MMIO LEDs | `0x2000_0000` | word |
| MMIO UART TX | `0x2000_0004` | word |
| MMIO UART status | `0x2000_0008` | word |
| MMIO status | `0x2000_000C` | halt/illegal flags |

Reset PC = `0x0000_0000`.

GitHub Actions template: `docs/ci.yml.example` (needs `workflow` OAuth scope to install under `.github/workflows/`).
