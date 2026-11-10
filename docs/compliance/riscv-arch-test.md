# RISC-V architecture tests (compliance)

Official suite: **[riscv-non-isa/riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test)**  
Legacy tag **3.9.1** (`riscv-test-suite/rv32i_m/{I,M,privilege}`).

## What this DUT can claim

| Area | Status |
|------|--------|
| RV32I ALU / branch / load-store | `rv32i_m/I` (e.g. `addi-01`) |
| **RV32M** | **8/8** DUT vs Unicorn: mul/mulh/mulhsu/mulhu/div/divu/rem/remu |
| **Zicsr + traps** | **ecall** / **ebreak** DUT vs Spike |
| Misaligned privilege tests | Implemented in RTL; not fully swept yet |
| Full RVI20U32 profile certification | Not claimed |

## Quick start

```bash
git clone --depth 1 -b 3.9.1 \
  https://github.com/riscv-non-isa/riscv-arch-test.git /tmp/riscv-arch-test-legacy
export ARCH_TEST_ROOT=/tmp/riscv-arch-test-legacy

# M-extension (Unicorn golden)
./compliance/scripts/run_m_subset.sh
python3 sim/run.py "lib.tb_arch_m.*"

# Privilege traps (Spike golden; needs Zicsr)
./compliance/scripts/run_privilege_subset.sh
python3 sim/run.py "lib.tb_arch_privilege.*"

# Classic I smoke
./compliance/scripts/compile_one.sh \
  $ARCH_TEST_ROOT/riscv-test-suite/rv32i_m/I/src/addi-01.S
python3 compliance/scripts/run_unicorn_sig.py \
  compliance/work/addi-01/test.elf compliance/work/addi-01/ref.signature
python3 sim/run.py "lib.tb_arch_addi.*"
```

`compile_one.sh` defaults to `-march=rv32im`. Override with `RISCV_MARCH` / `EXTRA_DEFS`
(e.g. `rv32i_zicsr` + `-Drvtest_mtrap_routine` for privilege).

## Layout

```
compliance/env/          model_test.h, link.ld
compliance/scripts/      compile + Unicorn/Spike + M/privilege subset runners
rtl/core/csr_file.vhd    M-mode CSRs + trap/mret
rtl/core/compliance_soc.vhd
tb/tb_arch_m.vhd         parameterized M suite
tb/tb_arch_privilege.vhd ecall/ebreak
tb/tb_trap_ecall.vhd     unit trap smoke
```
